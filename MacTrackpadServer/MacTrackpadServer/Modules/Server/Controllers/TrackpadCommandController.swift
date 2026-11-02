import CoreGraphics

/// 전송 형식을 해석한 DTO를 실제 입력 서비스 호출로 연결합니다.
final class TrackpadCommandController {
    private let cursor: CursorService
    private let keyboard: KeyboardService

    init(cursor: CursorService, keyboard: KeyboardService) {
        self.cursor = cursor
        self.keyboard = keyboard
    }

    func handle(_ packet: TrackpadPacketDTO) {
        switch packet.command {
        case .mouseMove: cursor.moveCursor(dx: CGFloat(packet.p1), dy: CGFloat(packet.p2))
        case .scroll: cursor.scrollCursor(dx: CGFloat(packet.p1), dy: CGFloat(packet.p2))
        case .leftDown: cursor.fireClick(.leftMouseDown)
        case .leftUp, .dragEnd: cursor.fireClick(.leftMouseUp)
        case .rightClick: cursor.rightClick()
        case .pageBack: keyboard.sendKey(0x21, flags: .maskCommand)
        case .pageForward: keyboard.sendKey(0x1E, flags: .maskCommand)
        case .drag: cursor.dragCursor(dx: CGFloat(packet.p1), dy: CGFloat(packet.p2))
        case .missionCtrl: keyboard.missionControl()
        case nil: break
        }
    }
}
