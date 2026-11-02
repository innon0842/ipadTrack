import AppKit

struct ScreenInfoService {
    func snapshot() -> ScreenSnapshot {
        let screens = NSScreen.screens
        let primaryHeight = NSScreen.main?.frame.height ?? 900
        let names = screens.enumerated().map { index, screen in
            "\(index + 1)번 \(Int(screen.frame.width))×\(Int(screen.frame.height)) @\(Int(screen.backingScaleFactor))x"
        }
        return ScreenSnapshot(
            minX: screens.map(\.frame.minX).min() ?? 0,
            maxX: screens.map(\.frame.maxX).max() ?? 3840,
            minY: screens.map { primaryHeight - $0.frame.maxY }.min() ?? 0,
            maxY: screens.map { primaryHeight - $0.frame.minY }.max() ?? 2160,
            description: names.joined(separator: " / ")
        )
    }

    func cursorPosition() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }
}
