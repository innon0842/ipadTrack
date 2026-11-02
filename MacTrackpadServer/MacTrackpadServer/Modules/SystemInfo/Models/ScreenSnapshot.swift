import Foundation

nonisolated struct ScreenSnapshot: Sendable {
    let minX: CGFloat
    let maxX: CGFloat
    let minY: CGFloat
    let maxY: CGFloat
    let description: String
}
