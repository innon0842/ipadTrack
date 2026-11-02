import SwiftUI

struct ThemeToggleButton: View {
    @Binding var isDark: Bool
    let foreground: Color
    let safeAreaTop: CGFloat

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) { isDark.toggle() }
        } label: {
            Image(systemName: isDark ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 17))
                .foregroundColor(foreground.opacity(0.75))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.top, safeAreaTop + 10)
        .padding(.leading, 16)
    }
}
