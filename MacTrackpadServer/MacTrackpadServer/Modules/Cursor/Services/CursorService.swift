import Foundation
import CoreGraphics
import QuartzCore

nonisolated final class CursorService: @unchecked Sendable {
    // 커서 위치, 화면 범위와 이벤트 소스는 이 직렬 큐에서만 사용합니다.
    private let cursorQ = DispatchQueue(label: "trackpad.cursor", qos: .userInteractive)

    private var cPos:  CGPoint = .zero  // 정규 커서 위치
    private var fracX: CGFloat = 0      // 서브픽셀 누적 X
    private var fracY: CGFloat = 0      // 서브픽셀 누적 Y

    // 속도 (EMA, pts/sec) ── 예측·관성에 사용
    private var velX: Double = 0
    private var velY: Double = 0
    private var lastMoveTs: Double = 0

    // 관성 ── 손가락 뗌 후 서서히 감속
    private var inVelX:    Double = 0
    private var inVelY:    Double = 0
    private var inertiaOn: Bool   = false

    // iPad ↔ 물리 장치 커서 제어권 전환 플래그
    // true  = iPad 독점 제어 (CGAssociate = 0)
    // false = 물리 장치 제어 (CGAssociate = 1, 기본값)
    private var ipadActive: Bool = false

    private var cursorTimer: DispatchSourceTimer?

    // ★ 최적화 1: CGEventSource 캐시
    //   패킷마다 CGEventSource(stateID:) 를 새로 만들면 커널 진입 비용이 누적됨
    //   → 앱 수명 동안 1회 생성 후 재사용
    private let evSrc = CGEventSource(stateID: .hidSystemState)

    // ★ 최적화 2: 화면 범위 캐시
    //   clampPos() 가 120Hz 로 호출되므로 NSScreen.screens 를 매번 조회하면 AppKit 락 비용 누적
    //   → NSApplication.didChangeScreenParametersNotification 때만 갱신
    private var scrMinX: CGFloat = 0
    private var scrMaxX: CGFloat = 3840
    private var scrMinY: CGFloat = 0
    private var scrMaxY: CGFloat = 2160

    private let base: CGFloat

    init(sensitivity: CGFloat, screens: ScreenSnapshot, initialPosition: CGPoint) {
        base = sensitivity
        cPos = initialPosition
        scrMinX = screens.minX
        scrMaxX = screens.maxX
        scrMinY = screens.minY
        scrMaxY = screens.maxY
        startCursorTimer()
    }

    func updateScreenBounds(_ screens: ScreenSnapshot) {
        cursorQ.async { [self] in
            scrMinX = screens.minX
            scrMaxX = screens.maxX
            scrMinY = screens.minY
            scrMaxY = screens.maxY
        }
    }

    // ── 120Hz 커서 타이머 ──────────────────────────────────────────
    //
    // ★ 물리 장치 공존 핵심:
    //   CGWarpMouseCursorPosition() 은 macOS HID delta 를 억제함.
    //   iPad 유휴 시 CGAssociateMouseAndMouseCursorPosition(1) 로
    //   맥북 트랙패드·MX Master 에 커서 제어권을 완전히 반환.
    //
    // 4가지 모드:
    //  ⓪ iPad 유휴 (≥300ms, 관성 없음) → associate(1) + return
    //  ① 패킷 직후 (< 4ms)             → 정확한 위치
    //  ② 패킷 사이 (4–28ms)            → 속도 예측 (WiFi 지터 보간)
    //  ③ 손가락 뗌 (28–300ms)          → 관성 감속
    private func startCursorTimer() {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: cursorQ)
        timer.schedule(deadline: .now(), repeating: .microseconds(8_333)) // 120 Hz
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let now = CACurrentMediaTime()
            let dt  = now - lastMoveTs

            // ⓪ iPad 유휴: 물리 장치에 커서 제어권 반환
            if dt > 0.30 && !inertiaOn {
                velX = 0; velY = 0
                if ipadActive {
                    ipadActive = false
                    CGAssociateMouseAndMouseCursorPosition(1) // 물리 HID 재연결
                }
                return
            }

            // iPad 활성 전환: 커서 독점 제어 시작
            if !ipadActive {
                ipadActive = true
                CGAssociateMouseAndMouseCursorPosition(0) // 물리 HID 차단
            }

            let out: CGPoint

            if dt <= 0.004 {
                // ① 최신 패킷
                inertiaOn = false
                out = cPos

            } else if dt < 0.028 {
                // ② 패킷 사이 갭: 속도 예측으로 보간
                inertiaOn = false
                let decay = max(0.0, 1.0 - dt * 28)
                let px = cPos.x + CGFloat(velX * dt * decay)
                let py = cPos.y + CGFloat(velY * dt * decay)
                let cap: CGFloat = 24
                out = CGPoint(
                    x: max(cPos.x - cap, min(cPos.x + cap, px)),
                    y: max(cPos.y - cap, min(cPos.y + cap, py))
                )

            } else {
                // ③ 손가락 뗌: 관성 시작/감속
                if !inertiaOn {
                    // ★ 최적화 3: sqrt 제거 → 제곱합 비교 (25² = 625)
                    if velX*velX + velY*velY > 625 {
                        inVelX = velX * 0.75
                        inVelY = velY * 0.75
                        inertiaOn = true
                    }
                    velX = 0; velY = 0
                }

                if inertiaOn {
                    inVelX *= 0.90; inVelY *= 0.90
                    cPos.x += CGFloat(inVelX * 0.00833)
                    cPos.y += CGFloat(inVelY * 0.00833)
                    clampPos()
                    // ★ 최적화 3: sqrt 제거 (8² = 64)
                    if inVelX*inVelX + inVelY*inVelY < 64 { inertiaOn = false }
                    out = cPos
                } else {
                    out = cPos
                }
            }
            CGWarpMouseCursorPosition(out)
        }
        timer.resume()
        cursorTimer = timer
    }

    // ── 커서 이동 ─────────────────────────────────────────────────
    // 가속 곡선: 느림(<2pt)=1:1  중간(2–7)=~2.1x  빠름(7–18)=~5.4x  flick(18+)=7x+
    // 서브픽셀 누적으로 소수점 오차 제거
    // 300ms+ 갭 후 CoreGraphics 좌표로 재동기화합니다.
    func moveCursor(dx: CGFloat, dy: CGFloat) {
        cursorQ.async { [self] in
            let now = CACurrentMediaTime()
            inertiaOn = false

            // 물리 장치 사용 후 전환 시 실제 커서 위치로 재동기화
            if lastMoveTs > 0 && now - lastMoveTs > 0.3 {
                if let position = CGEvent(source: nil)?.location {
                    cPos = position
                }
                fracX = 0; fracY = 0; velX = 0; velY = 0
            }
            let dt = max(now - lastMoveTs, 0.001)
            lastMoveTs = now

            let speed = sqrt(dx*dx + dy*dy)
            let accel: CGFloat
            switch speed {
            case ..<2:    accel = 1.0
            case 2..<7:   accel = 1.0 + (speed - 2)  * 0.22  // ~2.1x @7
            case 7..<18:  accel = 2.1 + (speed - 7)  * 0.30  // ~5.4x @18
            default:      accel = 5.4 + (speed - 18) * 0.20  // 날아감
            }
            let sc = base * accel

            fracX += dx * sc; fracY += dy * sc
            let sX = fracX.rounded(); fracX -= sX
            let sY = fracY.rounded(); fracY -= sY

            cPos.x += sX; cPos.y += sY
            clampPos()

            // EMA 속도 갱신 (예측·관성에 사용)
            let a = 0.50
            velX = velX*(1-a) + Double(sX)/dt*a
            velY = velY*(1-a) + Double(sY)/dt*a
        }
    }

    // ── 3손가락 드래그 ────────────────────────────────────────────
    func dragCursor(dx: CGFloat, dy: CGFloat) {
        cursorQ.async { [self] in
            inertiaOn = false
            let accel = min(1.0 + sqrt(dx*dx + dy*dy) * 0.10, 2.8)
            fracX += dx * base * accel; fracY += dy * base * accel
            let sX = fracX.rounded(); fracX -= sX
            let sY = fracY.rounded(); fracY -= sY
            cPos.x += sX; cPos.y += sY; clampPos()
            // ★ 최적화 1: evSrc 재사용
            let ev = CGEvent(mouseEventSource: evSrc, mouseType: .leftMouseDragged,
                             mouseCursorPosition: cPos, mouseButton: .left)
            ev?.post(tap: .cghidEventTap)
        }
    }

    // ── 스크롤 · 클릭 · 키보드 ────────────────────────────────────
    // ★ 최적화 1: 모든 이벤트에 evSrc 재사용 (CGEventSource 생성 비용 완전 제거)

    func scrollCursor(dx: CGFloat, dy: CGFloat) {
        cursorQ.async { [self] in
            // 유한하지만 매우 큰 입력도 Int32 변환에서 크래시하지 않도록 제한합니다.
            let vertical = max(CGFloat(Int32.min), min(CGFloat(Int32.max), dy * 4))
            let horizontal = max(CGFloat(Int32.min), min(CGFloat(Int32.max), dx * 4))
            let ev = CGEvent(scrollWheelEvent2Source: evSrc, units: .pixel, wheelCount: 2,
                             wheel1: Int32(vertical), wheel2: Int32(horizontal), wheel3: 0)
            ev?.post(tap: .cghidEventTap)
        }
    }

    func fireClick(_ type: CGEventType) {
        cursorQ.async { [self] in
            let btn: CGMouseButton = (type == .rightMouseDown || type == .rightMouseUp) ? .right : .left
            let ev = CGEvent(mouseEventSource: evSrc, mouseType: type,
                             mouseCursorPosition: cPos, mouseButton: btn)
            ev?.post(tap: .cghidEventTap)
        }
    }

    func rightClick() {
        cursorQ.async { [self] in
            let pos = cPos
            let dn = CGEvent(mouseEventSource: evSrc, mouseType: .rightMouseDown,
                             mouseCursorPosition: pos, mouseButton: .right)
            dn?.post(tap: .cghidEventTap)
            cursorQ.asyncAfter(deadline: .now() + 0.08) { [self] in
                let up = CGEvent(mouseEventSource: evSrc, mouseType: .rightMouseUp,
                                 mouseCursorPosition: pos, mouseButton: .right)
                up?.post(tap: .cghidEventTap)
            }
        }
    }

    // ★ 최적화 2+5: 캐시된 범위 사용 + @inline(__always) → 인라인 치환
    @inline(__always)
    private func clampPos() {
        cPos.x = max(scrMinX, min(cPos.x, scrMaxX - 1))
        cPos.y = max(scrMinY, min(cPos.y, scrMaxY - 1))
    }
    deinit {
        cursorTimer?.cancel()
        // 서비스 종료 시 물리 마우스에 커서 제어권을 반환합니다.
        let shouldRestore = ipadActive
        cursorQ.async {
            if shouldRestore { CGAssociateMouseAndMouseCursorPosition(1) }
        }
    }
}
