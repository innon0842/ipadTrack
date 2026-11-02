import SwiftUI

struct TrackpadTheme {
    let isDark: Bool

    var foreground: Color { isDark ? .white : Color(white: 0.12) }

    var backgroundColors: [Color] {
        isDark
        ? [Color(hue: 0.62, saturation: 0.55, brightness: 0.18),
           Color(hue: 0.72, saturation: 0.60, brightness: 0.10)]
        : [Color(white: 0.96), Color(white: 0.88)]
    }
}
