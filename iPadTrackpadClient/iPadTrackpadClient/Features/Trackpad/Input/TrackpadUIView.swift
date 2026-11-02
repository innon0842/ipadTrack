import UIKit

class TrackpadUIView: UIView {
    var sender: UDPSender?
    var sensitivity: Float = 1.0
    var onFingerCountChanged: ((Int) -> Void)?
    var onDraggingChanged: ((Bool) -> Void)?

    private let palmRadius: CGFloat = 45

    private var twoFAccumX: CGFloat = 0
    private var twoFAccumY: CGFloat = 0
    private var twoFLocked: Bool? = nil   // nil=미결정, true=수평, false=수직

    private var is3FDragging = false

    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = .clear
        isMultipleTouchEnabled = true

        let p1 = UIPanGestureRecognizer(target: self, action: #selector(pan1(_:)))
        p1.minimumNumberOfTouches = 1; p1.maximumNumberOfTouches = 1
        // ★ 최적화 2: 직접 터치만 허용 (Apple Pencil 제외)
        p1.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        p1.cancelsTouchesInView = false
        p1.delegate = self; addGestureRecognizer(p1)

        let t1 = UITapGestureRecognizer(target: self, action: #selector(tap1(_:)))
        t1.numberOfTouchesRequired = 1
        t1.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        t1.delegate = self; addGestureRecognizer(t1)

        let p2 = UIPanGestureRecognizer(target: self, action: #selector(pan2(_:)))
        p2.minimumNumberOfTouches = 2; p2.maximumNumberOfTouches = 2
        p2.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        p2.cancelsTouchesInView = false
        p2.delegate = self; addGestureRecognizer(p2)

        let t2 = UITapGestureRecognizer(target: self, action: #selector(tap2(_:)))
        t2.numberOfTouchesRequired = 2
        t2.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        t2.delegate = self; addGestureRecognizer(t2)

        let p3 = UIPanGestureRecognizer(target: self, action: #selector(pan3(_:)))
        p3.minimumNumberOfTouches = 3; p3.maximumNumberOfTouches = 3
        p3.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        p3.cancelsTouchesInView = false
        p3.delegate = self; addGestureRecognizer(p3)

        let s4 = UISwipeGestureRecognizer(target: self, action: #selector(swipe4Up(_:)))
        s4.numberOfTouchesRequired = 4; s4.direction = .up
        s4.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        s4.delegate = self; addGestureRecognizer(s4)
    }

    // MARK: 1손가락 이동 (delta 기반 트랙패드)
    // · 아이패드 절대 좌표가 아닌 직전 프레임 대비 delta(dx,dy)만 전송
    // · 맥 서버는 cPos(마지막 커서 위치) + delta → 순간이동 없음
    // · 0.15pt 미만 정지 노이즈만 필터 (EMA 제거 → 정확도·응답성 복원)
    @objc private func pan1(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began:
            gr.setTranslation(.zero, in: self)
            onFingerCountChanged?(1); onDraggingChanged?(true)
        case .changed:
            let t = gr.translation(in: self)
            gr.setTranslation(.zero, in: self)

            let rx = Float(t.x)
            let ry = Float(t.y)
            guard abs(rx) > 0.15 || abs(ry) > 0.15 else { return }

            sender?.send(.mouseMove, p1: rx * sensitivity, p2: ry * sensitivity)
        case .ended, .cancelled, .failed:
            onDraggingChanged?(false); onFingerCountChanged?(0)
        default: break
        }
    }

    // MARK: 1손가락 탭 → 왼쪽 클릭 (100ms 딜레이로 앱 포커스 후 클릭 보장)
    @objc private func tap1(_ gr: UITapGestureRecognizer) {
        guard gr.state == .recognized else { return }
        sender?.send(.leftDown)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.sender?.send(.leftUp)
        }
    }

    // MARK: 2손가락 패닝 → 스크롤 & 페이지 이동
    @objc private func pan2(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began:
            gr.setTranslation(.zero, in: self)
            twoFAccumX = 0; twoFAccumY = 0; twoFLocked = nil
            onFingerCountChanged?(2)

        case .changed:
            let t = gr.translation(in: self)
            twoFAccumX += t.x; twoFAccumY += t.y

            // 15pt 이후 방향 확정
            if twoFLocked == nil && abs(twoFAccumX) + abs(twoFAccumY) > 15 {
                twoFLocked = abs(twoFAccumX) > abs(twoFAccumY) * 2.0
            }

            // 수직(또는 미결정)이면 스크롤 전송
            if twoFLocked != true {
                sender?.send(.scroll,
                             p1: Float(t.x) * sensitivity,
                             p2: Float(t.y) * sensitivity)
            }
            gr.setTranslation(.zero, in: self)

        case .ended:
            let vel = gr.velocity(in: self)
            let horizDom  = abs(twoFAccumX) > abs(twoFAccumY) * 1.2
            let fastEnough = abs(vel.x) > 150
            let farEnough  = abs(twoFAccumX) > 35

            if horizDom && (fastEnough || farEnough) {
                // ★ 방향 수정: 오른쪽 스와이프=이전, 왼쪽 스와이프=다음
                let goBack = (twoFAccumX > 0)
                sender?.send(goBack ? .pageBack : .pageForward)
            }
            twoFLocked = nil; onFingerCountChanged?(0)

        case .cancelled, .failed:
            twoFLocked = nil; onFingerCountChanged?(0)
        default: break
        }
    }

    // MARK: 2손가락 탭 → 오른쪽 클릭
    @objc private func tap2(_ gr: UITapGestureRecognizer) {
        guard gr.state == .recognized else { return }
        sender?.send(.rightClick)
    }

    // MARK: 3손가락 드래그
    @objc private func pan3(_ gr: UIPanGestureRecognizer) {
        switch gr.state {
        case .began:
            is3FDragging = true; sender?.send(.leftDown)
            gr.setTranslation(.zero, in: self)
            onFingerCountChanged?(3); onDraggingChanged?(true)
        case .changed:
            let t = gr.translation(in: self)
            sender?.send(.drag, p1: Float(t.x) * sensitivity,
                                p2: Float(t.y) * sensitivity)
            gr.setTranslation(.zero, in: self)
        case .ended, .cancelled, .failed:
            if is3FDragging { sender?.send(.dragEnd); is3FDragging = false }
            onDraggingChanged?(false); onFingerCountChanged?(0)
        default: break
        }
    }

    // MARK: 4손가락 위 → 미션 컨트롤
    @objc private func swipe4Up(_ gr: UISwipeGestureRecognizer) {
        guard gr.state == .recognized else { return }
        sender?.send(.missionCtrl)
        onFingerCountChanged?(4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.onFingerCountChanged?(0)
        }
    }
}

extension TrackpadUIView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gr: UIGestureRecognizer,
                           shouldReceive touch: UITouch) -> Bool {
        let r = touch.majorRadius
        return r == 0 || r < palmRadius
    }

    func gestureRecognizer(_ gr: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        let f1 = fCount(gr), f2 = fCount(other)
        if f1 == f2, gr is UITapGestureRecognizer || other is UITapGestureRecognizer { return false }
        return true
    }

    private func fCount(_ gr: UIGestureRecognizer) -> Int {
        if let p = gr as? UIPanGestureRecognizer   { return p.minimumNumberOfTouches }
        if let t = gr as? UITapGestureRecognizer   { return t.numberOfTouchesRequired }
        if let s = gr as? UISwipeGestureRecognizer { return s.numberOfTouchesRequired }
        return 0
    }
}
