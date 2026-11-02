# iPad Trackpad · Client

**iPad의 멀티터치 입력을 Mac으로 전달하는 SwiftUI 기반 무선 트랙패드 클라이언트입니다.**

iPad에서 감지한 손가락 이동량과 제스처를 12바이트 UDP 패킷으로 전송합니다. Mac에서 실행하는 서버 앱과 함께 커서 이동, 클릭, 스크롤, 드래그 등을 수행합니다.

| 저장소 | 역할 |
| --- | --- |
| **[Client](https://github.com/innon0842/ipadTrack_client)** | iPad 터치 인식, 감도 설정, 명령 전송 |
| [Server](https://github.com/innon0842/ipadTrack_server) | UDP 수신, 명령 처리, macOS 입력 이벤트 생성 |

> **포트폴리오용 실험 프로젝트입니다.** 현재 기기 인증·페어링·전송 암호화가 구현되어 있지 않습니다. 신뢰할 수 있는 로컬 네트워크에서 개발·시연 용도로 사용하세요. 서버를 공용 네트워크나 인터넷에 노출하지 마세요.

## 주요 기능

| 제스처 | 동작 |
| --- | --- |
| 한 손가락 이동 | 커서 이동 |
| 한 손가락 탭 | 왼쪽 클릭 |
| 두 손가락 이동 | 스크롤 |
| 두 손가락 좌우 스와이프 | 이전·다음 페이지 |
| 두 손가락 탭 | 오른쪽 클릭 |
| 세 손가락 이동 | 드래그 |
| 네 손가락 위로 스와이프 | Mission Control |

- 4단계 감도 설정: 느림, 보통, 빠름, 매우 빠름
- 라이트·다크 테마와 설정 저장
- 손가락 수와 조작 상태 표시
- 직접 터치만 인식하고 Apple Pencil 입력 제외
- 터치 접촉 반경에 기반한 간단한 손바닥 접촉 필터

페이지 이동과 Mission Control은 서버가 macOS 단축키를 전송하는 방식이므로 앱 및 시스템 단축키 설정에 따라 동작이 달라질 수 있습니다.

## 구현에서 다룬 문제

### 터치 좌표를 상대 이동량으로 변환

iPad의 절대 터치 위치 대신 직전 입력 대비 `dx`, `dy`를 전송합니다. 손가락을 화면에서 떼었다 다시 올려도 새 터치 위치로 Mac 커서가 바로 이동하지 않도록 상대 이동 방식으로 구성했습니다. 이동량에는 선택한 감도를 적용하며 작은 정지 노이즈를 필터링합니다.

### SwiftUI 화면과 UIKit 제스처 연결

화면과 설정은 SwiftUI로 구성하고, 손가락 수별 입력은 `UIGestureRecognizer`로 처리합니다. `UIViewRepresentable`이 UIKit 입력 뷰와 SwiftUI 상태를 연결합니다. 상태 표시 레이어는 터치를 통과시키고 감도·테마 버튼은 별도 레이어에서 입력을 받습니다.

### UI와 전송 로직 분리

터치 인식, 네트워크 송신, 설정 모델, 화면 컴포넌트를 별도 파일로 분리했습니다. `ContentView`는 화면 조합과 상태 연결을 담당합니다.

## 실행 환경

| 항목 | 현재 프로젝트 설정 |
| --- | --- |
| 실행 기기 | iPad — 멀티터치 동작 확인에는 실기기 필요 |
| Deployment Target | iPadOS 26.5 이상 |
| 빌드 확인 도구 | Xcode 27.2 |
| 주요 프레임워크 | SwiftUI, UIKit, Network, Observation |
| 외부 패키지 | 없음 |
| 통신 | UDP, 기본 포트 `12345` |

실제 기기·OS 조합별 동작과 입력 지연에 대한 정량 벤치마크는 아직 정리하지 않았습니다. 시뮬레이터 빌드 성공은 실제 iPad와 Mac 간 동작 검증을 대신하지 않습니다.

## 실행 방법

### 1. 두 프로젝트 준비

```sh
git clone https://github.com/innon0842/ipadTrack_client.git
git clone https://github.com/innon0842/ipadTrack_server.git
```

두 기기를 서로 통신할 수 있는 동일한 신뢰 네트워크에 연결합니다. 게스트 Wi-Fi의 기기 격리 설정은 통신을 막을 수 있습니다.

### 2. Mac 서버 실행

[서버 README](https://github.com/innon0842/ipadTrack_server#readme)에 따라 Mac 앱을 실행하고 접근성 권한을 허용합니다. 서버 화면에서 Mac의 IPv4 주소를 확인합니다.

### 3. 목적지 IP 설정

현재는 자동 검색과 앱 내 IP 입력 화면이 구현되어 있지 않습니다. 아래 파일의 `serverIP`를 사용할 Mac의 IPv4 주소로 변경하세요.

- 파일: [`iPadTrackpadClient/Networking/UDPSender.swift`](iPadTrackpadClient/Networking/UDPSender.swift)
- 설정: `private let serverIP = "<Mac의 IPv4 주소>"`
- 기본 포트: `12345` — 서버의 포트와 일치해야 합니다.

IP가 바뀌면 코드를 다시 수정하고 빌드해야 합니다.

### 4. Xcode 설정 및 iPad 실행

```sh
open iPadTrackpadClient.xcodeproj
```

1. 앱 타깃의 **Signing & Capabilities → Team**을 자신의 개발 팀으로 변경합니다. 필요하면 Bundle Identifier도 고유한 값으로 변경합니다.
2. **Info → Custom iOS Target Properties**에 `Privacy - Local Network Usage Description` (`NSLocalNetworkUsageDescription`)을 추가합니다. 현재 저장소의 프로젝트 설정에는 이 키가 명시되어 있지 않습니다.
3. 설명 예시: `같은 네트워크의 Mac에 터치 입력을 전송하기 위해 로컬 네트워크에 접근합니다.`
4. 연결한 iPad를 실행 대상으로 선택하고 앱을 실행합니다. 로컬 네트워크 접근 요청이 나타나면 허용합니다.
5. Mac에서 커서 이동, 클릭, 스크롤을 확인합니다.

로컬 네트워크 권한 설정은 [Apple 안내](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy)를 참고하세요.

## 구조

```text
iPadTrackpadClient/
├── App/
│   └── iPadTrackpadClientApp.swift
├── Networking/
│   ├── TrackpadCommand.swift
│   └── UDPSender.swift
├── Models/
│   ├── SensitivityLevel.swift
│   └── TrackpadInteractionState.swift
└── Features/
    └── Trackpad/
        ├── ContentView.swift
        ├── Appearance/
        ├── Input/
        └── Components/
```

```text
UIKit 제스처 인식 → 상대 이동량·명령 생성 → UDP 패킷 전송
                                               ↓
                                  Mac 서버 → macOS 입력 이벤트
```

## 패킷 형식

애플리케이션 페이로드는 12바이트입니다. UDP/IP 헤더 크기는 포함하지 않습니다.

| Offset | 크기 | 타입 | 용도 |
| --- | --- | --- | --- |
| 0 | 2바이트 | UInt16 | 명령 코드 |
| 2 | 2바이트 | UInt16 | 예약 필드, 현재 0 |
| 4 | 4바이트 | Float | 첫 번째 값, 이동량 X 등 |
| 8 | 4바이트 | Float | 두 번째 값, 이동량 Y 등 |

현재 송신기는 Apple 기기의 little-endian 메모리 레이아웃을 사용하며 서버는 동일한 형식으로 디코딩합니다. 명령 코드는 [`TrackpadCommand.swift`](iPadTrackpadClient/Networking/TrackpadCommand.swift)에 정의되어 있습니다. 프로토콜 버전·순번·인증 정보는 아직 없습니다.

## 빌드 확인

저장소 루트에서 실행합니다.

```sh
xcodebuild \
  -project iPadTrackpadClient.xcodeproj \
  -scheme iPadTrackpadClient \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

이 명령은 시뮬레이터용 컴파일을 확인합니다. 클라이언트 전용 자동화 테스트는 아직 없습니다.

## 현재 한계와 개선 계획

- **연결 상태:** UDP `.ready`를 연결됨으로 표시합니다. 서버 응답 확인이 아니므로 화면에 연결됨이 표시돼도 서버가 실제로 수신 중이라는 보장은 없습니다.
- **보안:** 기기 인증, 페어링, 암호화, 재전송 공격 방지가 구현되어 있지 않습니다.
- **신뢰성:** UDP는 패킷 유실·중복·순서 변경이 가능하며, 클릭·드래그 해제 패킷이 유실되면 서버에 눌림 상태가 남을 수 있습니다. 이상 동작 시 서버 앱을 종료하세요.
- **설정:** 서버 IP가 코드에 고정되어 있습니다. IP 입력·저장, 기기 자동 검색을 개선할 예정입니다.
- **입력:** 손바닥 필터는 접촉 반경에 기반한 휴리스틱이며 정확도를 보장하지 않습니다. 시스템 멀티태스킹 제스처가 앱 제스처와 충돌할 수 있습니다.
- **컴팩트 화면:** 관련 컴포넌트는 있지만 현재 UI에는 진입 경로가 없습니다.
- **검증:** 실기기별 제스처 충돌, 앱 백그라운드 전환, 연결 복구와 입력 지연 측정이 추가로 필요합니다.

우선 개선 항목은 페어링·인증, heartbeat와 눌림 상태 복구, 연결 설정 UI입니다.

## 라이선스

현재 별도 오픈소스 라이선스가 지정되어 있지 않습니다. 코드와 이미지의 재사용 조건은 저장소 소유자에게 확인해 주세요.
