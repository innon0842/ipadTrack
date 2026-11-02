# Mac Trackpad Server 구조

서버는 아래 5개 기능 모듈로 구성합니다. 각 모듈은 자신의 책임에 필요한 Controller, Service, DTO, Model, View를 내부에 둡니다. 폴더는 단일 Xcode 앱 타깃 안의 기능 경계이며 별도 Swift Package나 프레임워크 타깃은 아닙니다.

```text
MacTrackpadServer/
├── App/
│   └── MacTrackpadServerApp.swift
└── Modules/
    ├── Server/
    │   ├── TrackpadServerModule.swift
    │   ├── Configuration/
    │   │   └── ServerConfiguration.swift
    │   ├── Controllers/
    │   │   └── TrackpadCommandController.swift
    │   ├── Models/
    │   │   └── ServerStatus.swift
    │   └── Views/
    │       ├── ContentView.swift
    │       └── Components/
    │           ├── ServerStatusCard.swift
    │           ├── ServerStatusRow.swift
    │           ├── GestureGuideView.swift
    │           ├── GestureGuideRow.swift
    │           └── AccessibilityNoticeView.swift
    ├── Networking/
    │   ├── DTOs/
    │   │   └── TrackpadPacketDTO.swift
    │   ├── Models/
    │   │   └── TrackpadCommand.swift
    │   └── Services/
    │       └── UDPServerService.swift
    ├── Cursor/
    │   └── Services/
    │       └── CursorService.swift
    ├── Keyboard/
    │   └── Services/
    │       └── KeyboardService.swift
    └── SystemInfo/
        ├── Models/
        │   └── ScreenSnapshot.swift
        └── Services/
            ├── ScreenInfoService.swift
            └── NetworkInfoService.swift
```

## 모듈별 책임과 의존 방향

| 모듈 | 책임 | 의존하는 기능 모듈 |
| --- | --- | --- |
| Server | 서버 시작·종료, 상태 집계, 명령 라우팅, 서버 화면과 전체 설정 | Networking, Cursor, Keyboard, SystemInfo |
| Networking | UDP 접속·수신, 패킷 디코딩·검증, 전송 명령 코드 | 없음 |
| Cursor | 커서 위치·가속·보간·관성, 클릭·드래그·스크롤 | SystemInfo의 ScreenSnapshot |
| Keyboard | 페이지 이동과 Mission Control 키 이벤트 | 없음 |
| SystemInfo | 디스플레이·실제 커서 위치·로컬 IP 조회 | 없음 |

`Server`가 다른 모듈을 조립합니다. `Networking`은 커서·키보드를 직접 조작하지 않으며, `Cursor`와 `Keyboard`는 네트워크 패킷이나 서버 화면을 알지 못합니다. `Server/Controllers/TrackpadCommandController`가 이 경계를 연결합니다.

각 모듈에는 실제 책임이 있는 계층만 둡니다. 예를 들어 `Cursor`와 `Keyboard`는 현재 서비스만 필요하므로 빈 Controller·DTO 폴더를 만들지 않습니다. 저장 기능이 생기면 그 기능을 소유한 모듈 안에 `Repositories`를 둡니다.

프로토콜과 UDP 수신 검증은 `Tests/Modules/Networking/ServerProtocolChecks.swift`에 있으며, `Tests/run-checks.sh`로 실행합니다. 신규 기능의 테스트 역시 `Tests/Modules/<기능명>/`에 배치합니다.

## 명령 처리 흐름

1. `UDPServerService`가 UDP datagram을 수신합니다.
2. `TrackpadPacketDTO`가 길이, 숫자 유효성 및 필드 값을 검사·디코딩합니다.
3. `TrackpadServerModule`이 main actor에서 명령을 전달하고 화면 상태를 갱신합니다.
4. `TrackpadCommandController`가 명령에 따라 `CursorService` 또는 `KeyboardService`를 호출합니다.
5. `Views`가 모듈의 관찰 가능한 상태를 표시합니다.

DTO는 기존 클라이언트의 12바이트 형식과 명령 코드 1~10을 유지합니다. 각 필드는 little-endian 기준으로 offset 0의 UInt16 명령, offset 2의 UInt16 예약 필드, offset 4와 8의 Float 값입니다. 미지원 명령은 실행하지 않으며 진단용 명령명에는 원본 코드를 표시합니다.

## 책임과 실행 컨텍스트

- `TrackpadServerModule`: 서비스 생성과 연결, 패킷 집계, 화면에 노출할 상태를 담당합니다. SwiftUI와 같은 main actor에서 동작합니다.
- `UDPServerService`: 전용 직렬 큐에서 리스너와 접속 목록을 관리합니다. 메시지 단위로 수신하고 오류가 발생한 접속은 취소·제거합니다. `start()`와 `stop()`은 동일 큐에서 실행합니다.
- `TrackpadCommandController`: DTO를 입력 서비스 호출로 변환합니다. 소켓과 화면을 직접 다루지 않습니다.
- `CursorService`: 전용 직렬 큐에서 위치, 서브픽셀 누적, 가속, 예측·관성, 클릭·드래그·스크롤과 화면 범위를 관리합니다. 기존 가속 곡선과 타이머 간격을 유지합니다. 종료 시 물리 마우스의 커서 연결을 복구합니다.
- `KeyboardService`: 페이지 이동과 Mission Control 키 이벤트를 생성합니다.
- `ScreenInfoService`: main actor에서 AppKit 디스플레이 정보를 조회해 값 타입인 `ScreenSnapshot`으로 전달합니다. 화면 변경 알림은 `ContentView`에서 모듈에 전달합니다.
- `NetworkInfoService`: 기존 방식대로 en0 인터페이스의 IPv4 주소를 조회합니다.

`UDPServerService`와 `CursorService`의 `@unchecked Sendable`은 가변 상태를 전용 직렬 큐로 보호한다는 전제입니다. 새로운 메서드도 초기화·종료 외에는 해당 큐 안에서 상태에 접근해야 합니다.

## Repository를 추가하지 않은 이유

현재 서버는 DB나 파일에 데이터를 영속 저장하지 않습니다. 전송 서비스와 메모리 상태만 있어 Repository 계층을 추가하지 않았습니다. 추후 페어링 기기나 사용자 설정을 저장한다면 별도 Repository를 도입할 수 있습니다.

## 검증

저장소 루트(`MacTrackpadServer`)에서:

```sh
./Tests/run-checks.sh
xcodebuild -project MacTrackpadServer.xcodeproj \
  -scheme MacTrackpadServer -configuration Debug \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

`run-checks.sh`는 실제 마우스·키보드 이벤트 없이 다음을 검증합니다.

- 클라이언트 튜플 패킷 및 알려진 little-endian 바이트 호환성
- 모든 명령 ID, 음수·소수 값, 미지원 명령
- 잘못된 길이와 NaN·무한대 거부
- localhost UDP 수신, 잘못된 datagram 이후 정상 수신
- UDP 서버 중지와 재시작

실제 iPad 연결, 접근성 권한, 다중 모니터와 커서 감각은 실기기 검증이 필요합니다. 인증·페어링, heartbeat, 패킷 유실 시 버튼 상태 복구는 이번 구조 분리의 구현 범위에 포함하지 않았습니다.
