import SwiftUI

struct GestureGuideRow: View {
    let gesture: String
    let action: String

    var body: some View {
        HStack {
            Text(gesture)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 130, alignment: .leading)
            Text("→")
                .foregroundColor(.white.opacity(0.3))
                .font(.system(size: 11))
            Text(action)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.45))
            Spacer()
        }
    }
}
