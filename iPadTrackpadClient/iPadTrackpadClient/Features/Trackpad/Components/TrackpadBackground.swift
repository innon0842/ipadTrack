import SwiftUI

struct TrackpadBackground: View {
    let theme: TrackpadTheme
    let showsGrid: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: theme.backgroundColors,
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(.all)
            if showsGrid {
                Canvas { ctx, size in
                    let sp: CGFloat = 40
                    var path = Path()
                    stride(from: 0, through: size.width,  by: sp).forEach { x in
                        path.move(to: .init(x: x, y: 0)); path.addLine(to: .init(x: x, y: size.height))
                    }
                    stride(from: 0, through: size.height, by: sp).forEach { y in
                        path.move(to: .init(x: 0, y: y)); path.addLine(to: .init(x: size.width, y: y))
                    }
                    ctx.stroke(path, with: .color(theme.foreground.opacity(theme.isDark ? 0.05 : 0.07)), lineWidth: 1)
                }
                .ignoresSafeArea()
            }
        }
    }
}
