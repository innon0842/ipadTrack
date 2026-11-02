# iPad Trackpad · Server

**iPad에서 전달한 멀티터치 명령을 macOS의 마우스·키보드 입력으로 변환하는 Swift 기반 서버입니다.**

UDP로 수신한 패킷을 DTO로 디코딩하고, 명령 컨트롤러를 통해 커서·키보드 서비스로 전달합니다. iPad 클라이언트와 함께 무선 트랙패드로 동작합니다.

| 저장소 | 역할 |
| --- | --- |
| [Client](https://github.com/innon0842/ipadTrack_client) | iPad 터치 인식, 감도 설정, 명령 전송 |
| **[Server](https://github.com/innon0842/ipadTrack_server)** | UDP 수신, 명령 처리, macOS 입력 이벤트 생성 |

> **포트폴리오용 실험 프로젝트입니다.** 현재 서버는 접속 기기를 인증하지 않습니다. 서버가 실행 중이고 macOS 접근성 권한이 허용된 상태에서 수신 포트에 도달 가능한 기기가 입력 명령을 보낼 수 있습니다. 신뢰할 수 있는 로컬 네트워크에서만 사용하고, 사용 후 서버 앱을 종료하세요. 공용 네트워크와 인터넷에 노출하거나 포트 포워딩하지 마세요.

## 주요 기능

- UDP 패킷 수신과 12바이트 형식 검증
- 커서 이동, 좌·우 클릭, 스크롤, 드래그
- 페이지 이동 및 Mission Control 단축키 전송
- 커서 가속, 서브픽셀 이동량 누적, 속도 예측과 관성 감속
- 유휴 상태에서 물리 마우스에 커서 제어권 반환
- 서버 상태, 로컬 IP, 모니터 정보, 수신 명령 표시
- 잘못된 길이와 NaN·무한대 입력 거부

## 구현에서 다룬 문제

### 기기 간 입력 전달과 역할 분리

UDP 수신, 전송 형식 해석, 명령 라우팅, 실제 입력 제어를 분리했습니다. 네트워크 서비스는 커서를 직접 조작하지 않고, 입력 서비스는 네트워크 패킷을 해석하지 않습니다.

```text
iPad Client
    ↓ UDP
Networking / UDPServerService
    ↓ TrackpadPacketDTO
Server / TrackpadServerModule
    ↓ TrackpadCommandController
Cursor / CursorService 또는 Keyboard / KeyboardService
    ↓
macOS 입력 이벤트
```

### 입력 간격 변화와 커서 움직임

커서 서비스는 수신한 상대 이동량을 누적하고 이동 크기에 따른 가속을 적용합니다. 패킷 사이에는 속도 예측을, 입력이 멈춘 뒤에는 관성 감속을 적용하도록 구현했습니다. 위치와 화면 범위 등 커서 상태는 전용 직렬 큐에서 관리합니다.

커서 타이머 간격은 약 8.33ms로 설정되어 있습니다. **이는 타이머의 목표 주기이며 실제 120Hz 입력, 화면 갱신률 또는 특정 지연 시간을 보장하는 측정 결과는 아닙니다.**

### iPad와 물리 마우스 간 제어권 전환

입력 후 일정 시간이 지나고 관성이 끝나면 물리 마우스와 커서를 다시 연결합니다. 긴 입력 공백 뒤에는 실제 커서 위치로 내부 좌표를 맞춥니다. 다양한 마우스·모니터 구성에서의 사용감은 추가 검증 대상입니다.

## 실행 환경

| 항목 | 현재 프로젝트 설정 |
| --- | --- |
| 실행 기기 | Mac |
| Deployment Target | macOS 26.5 이상 |
| 빌드 확인 도구 | Xcode 27.2 |
| 주요 프레임워크 | SwiftUI, AppKit, Network, CoreGraphics, QuartzCore, Observation |
| 외부 패키지 | 없음 |
| 통신 | UDP, 기본 포트 `12345` |
| 입력 제어 권한 | macOS 접근성 권한 필요 |

실제 기기·OS 조합별 동작과 종단 간 입력 지연에 대한 정량 벤치마크는 아직 정리하지 않았습니다.

## 실행 방법

### 1. 프로젝트 열기

```sh
git clone https://github.com/innon0842/ipadTrack_server.git
cd ipadTrack_server
open MacTrackpadServer.xcodeproj
```

앱 타깃의 **Signing & Capabilities → Team**을 자신의 개발 팀으로 변경합니다. 필요하면 Bundle Identifier도 고유한 값으로 변경합니다.

### 2. 권한 설정 및 서버 실행

1. 로컬 네트워크 접근을 사용하는 환경에 맞게 앱 타깃의 **Info**에 `Privacy - Local Network Usage Description` (`NSLocalNetworkUsageDescription`)을 설정합니다. 현재 저장소의 프로젝트 설정에는 이 키가 명시되어 있지 않습니다.
2. 설명 예시: `같은 네트워크의 iPad에서 터치 명령을 수신하기 위해 로컬 네트워크에 접근합니다.`
3. Xcode에서 Mac 앱을 실행합니다. 앱이 생성되면 UDP 리스너가 자동으로 시작됩니다.
4. **시스템 설정 → 개인정보 보호 및 보안 → 접근성**에서 실행한 `MacTrackpadServer` 앱을 추가·활성화합니다. 필요하면 앱을 종료하고 다시 실행합니다.
5. 서버 상태가 수신 중인지 확인합니다. 방화벽이 묻는 경우 신뢰 네트워크에서의 수신을 허용합니다.

현재 앱은 접근성 권한 안내를 표시하지만 권한 상태를 자동으로 확인하거나 요청하는 흐름은 구현되어 있지 않습니다. 서버가 수신 중이어도 접근성 권한이 없으면 입력 제어가 정상 작동하지 않을 수 있습니다.

로컬 네트워크 설정은 [Apple 안내](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)를 참고하세요.

### 3. iPad 클라이언트 연결

1. Mac과 iPad를 서로 통신할 수 있는 동일한 신뢰 네트워크에 연결합니다.
2. 서버 화면에 표시된 Mac의 IPv4 주소를 클라이언트의 `UDPSender.serverIP`에 설정합니다.
3. [클라이언트 README](https://github.com/innon0842/ipadTrack_client#readme)에 따라 iPad 앱을 빌드·실행합니다.
4. 커서 이동, 클릭, 스크롤과 드래그를 확인합니다.

서버의 IP 표시 기능은 현재 `en0` 인터페이스만 조회합니다. Ethernet·VPN 등 다른 인터페이스를 사용하는 경우 macOS 네트워크 설정에서 실제 사용할 IP를 확인하세요. 클라이언트의 연결됨 표시는 서버 응답 확인을 의미하지 않습니다.

### 4. 사용 종료

현재 서버 화면에는 시작·중지 버튼이 없습니다. 서버 앱을 **완전히 종료**하거나 Xcode에서 실행을 중지해 수신을 끝내세요. 창을 닫는 것만으로 프로세스가 종료된다고 가정하지 마세요.

## 기능 모듈 구조

```text
MacTrackpadServer/
├── App/
└── Modules/
    ├── Server/
    │   ├── TrackpadServerModule.swift
    │   ├── Configuration/
    │   ├── Controllers/
    │   ├── Models/
    │   └── Views/Components/
    ├── Networking/
    │   ├── DTOs/
    │   ├── Models/
    │   └── Services/
    ├── Cursor/
    │   └── Services/
    ├── Keyboard/
    │   └── Services/
    └── SystemInfo/
        ├── Models/
        └── Services/
```

| 모듈 | 책임 |
| --- | --- |
| Server | 서비스 조립, 명령 라우팅, 상태 집계, 화면과 전체 설정 |
| Networking | UDP 접속·수신, 패킷 DTO, 전송 명령 코드 |
| Cursor | 커서 위치, 가속·예측·관성, 클릭·스크롤·드래그 |
| Keyboard | 페이지 이동 및 Mission Control 키 이벤트 |
| SystemInfo | 디스플레이 정보, 실제 커서 위치, 로컬 IP 조회 |

각 폴더는 하나의 Xcode 앱 타깃 안에 있는 기능 모듈입니다. 별도 패키지·프레임워크로 컴파일되는 구조는 아닙니다. 각 모듈에는 실제로 필요한 계층만 두며, 영속 저장 기능이 없어 Repository는 추가하지 않았습니다.

상세 책임과 실행 큐는 [Architecture 문서](Docs/Architecture.md)에 정리했습니다.

## 프로토콜과 설정

애플리케이션 페이로드는 12바이트이며 UDP/IP 헤더 크기는 제외합니다.

| Offset | 크기 | 타입 | 용도 |
| --- | --- | --- | --- |
| 0 | 2바이트 | UInt16 | 명령 코드 |
| 2 | 2바이트 | UInt16 | 예약 필드 |
| 4 | 4바이트 | Float | 첫 번째 값 |
| 8 | 4바이트 | Float | 두 번째 값 |

서버는 little-endian으로 디코딩합니다. 명령 코드는 [`TrackpadCommand.swift`](MacTrackpadServer/Modules/Networking/Models/TrackpadCommand.swift)에 정의되어 있으며, 미지원 명령은 실행하지 않습니다.

[`ServerConfiguration.swift`](MacTrackpadServer/Modules/Server/Configuration/ServerConfiguration.swift)에서 기본값을 변경할 수 있습니다.

| 설정 | 기본값 | 설명 |
| --- | --- | --- |
| `port` | `12345` | UDP 수신 포트, 클라이언트와 일치 필요 |
| `cursorSensitivity` | `1.25` | 서버 측 기본 커서 감도 |
| `statusUpdateInterval` | `10` | 수신 패킷 10개마다 화면의 집계 상태 갱신 |

패킷 길이·숫자 검증은 접속자 인증을 대신하지 않습니다. 프로토콜 버전·순번·인증 정보는 아직 없습니다.

## 빌드 및 검증

저장소 루트에서 실행합니다.

```sh
xcodebuild \
  -project MacTrackpadServer.xcodeproj \
  -scheme MacTrackpadServer \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO build
```

프로토콜과 UDP 검증:

```sh
./Tests/run-checks.sh
```

검증 스크립트는 실제 마우스·키보드 입력을 발생시키지 않고 다음을 확인합니다.

- 클라이언트 튜플 패킷과 알려진 little-endian 바이트 호환성
- 명령 ID, 음수·소수 값, 미지원 명령
- 잘못된 길이와 NaN·무한대 입력 거부
- localhost UDP 수신과 잘못된 datagram 이후 정상 수신
- 서버 중지·재시작

macOS Debug 빌드와 위 검증 스크립트의 통과를 확인했습니다. 이 검증은 실제 iPad 연결, 접근성 권한, 다중 모니터와 입력 사용감 검증을 대신하지 않습니다.

## 현재 한계와 개선 계획

- **보안:** 기기 인증, 페어링, 암호화, 재전송 공격 방지가 없습니다. 다음 우선순위는 승인된 기기만 입력을 전달할 수 있는 인증된 세션 구성입니다.
- **입력 상태 복구:** heartbeat와 버튼 눌림 상태의 시간 초과 복구가 없습니다. UDP 해제 패킷 유실 시 눌림 상태가 남을 수 있습니다. 이상 동작 시 앱을 종료하고 실제 마우스로 눌림 상태를 확인하세요.
- **접속 관리:** 접속 수·수신량 제한과 유휴 접속 정리가 추가로 필요합니다.
- **권한·화면:** 접근성 권한 상태 확인, 연결 기기 표시, 서버 시작·중지 UI가 필요합니다.
- **권한 설정 정리:** 현재 App Sandbox가 꺼져 있고 Apple Events entitlement가 포함되어 있습니다. Apple Events 권한은 접근성 권한을 대신하지 않으며, 배포 전 실제 요구사항에 맞춘 권한 최소화와 동작 검증이 필요합니다.
- **다중 디스플레이:** 화면 전체의 경계 사각형으로 커서를 제한하므로 불규칙한 모니터 배치와 빈 영역 처리가 추가 검증 대상입니다.
- **성능:** 입력 지연, CPU 사용률, 패킷 유실 환경에서의 동작을 정량 측정할 예정입니다.

README의 사용 범위 안내는 위 보안 기능을 대신하지 않습니다. 일반 사용자에게 배포하기 전에 인증과 입력 상태 복구를 우선 보완해야 합니다.

## 라이선스

현재 별도 오픈소스 라이선스가 지정되어 있지 않습니다. 코드의 재사용 조건은 저장소 소유자에게 확인해 주세요.
