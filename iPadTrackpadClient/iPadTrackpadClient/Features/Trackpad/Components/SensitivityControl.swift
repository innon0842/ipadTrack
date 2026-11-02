import SwiftUI

struct SensitivityControl: View {
    @Binding var selectedID: String
    let foreground: Color
    let safeAreaBottom: CGFloat

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 11))
                        .foregroundColor(foreground.opacity(0.35))
                    Text("감도")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(foreground.opacity(0.45))
                    Image(systemName: "hare.fill")
                        .font(.system(size: 11))
                        .foregroundColor(foreground.opacity(0.35))
                }
                HStack(spacing: 8) {
                    ForEach(SensitivityLevel.presets) { lv in
                        Button {
                            withAnimation(.spring(response: 0.25)) { selectedID = lv.id }
                        } label: {
                            Text(lv.label)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedID == lv.id ? .black : foreground.opacity(0.55))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    selectedID == lv.id
                                        ? Color.cyan
                                        : Color.white.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, max(safeAreaBottom, 16))
        }
    }
}
