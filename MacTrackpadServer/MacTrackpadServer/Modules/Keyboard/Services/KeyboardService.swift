import CoreGraphics

final class KeyboardService {
    private let evSrc = CGEventSource(stateID: .hidSystemState)

    func sendKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
        let dn = CGEvent(keyboardEventSource: evSrc, virtualKey: keyCode, keyDown: true)
        dn?.flags = flags; dn?.post(tap: .cghidEventTap)
        let up = CGEvent(keyboardEventSource: evSrc, virtualKey: keyCode, keyDown: false)
        up?.flags = flags; up?.post(tap: .cghidEventTap)
    }

    func missionControl() { sendKey(0x7E, flags: .maskControl) }
}
