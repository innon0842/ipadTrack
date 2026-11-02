import SwiftUI

struct ServerStatusRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(color.opacity(0.8))
                .frame(width: 26)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.55))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
                .lineLimit(1)
        }
    }
}
