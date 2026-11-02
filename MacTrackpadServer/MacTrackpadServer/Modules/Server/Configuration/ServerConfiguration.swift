import Foundation

nonisolated struct ServerConfiguration: Sendable {
    var port: UInt16 = 12345
    var cursorSensitivity: CGFloat = 1.25
    var statusUpdateInterval = 10
}
