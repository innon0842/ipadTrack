import SwiftUI

struct TrackpadStatusView: View {
    let interaction: TrackpadInteractionState
    let connectionState: String
    let foreground: Color
    let safeAreaBottom: CGFloat

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle().fill(.ultraThinMaterial).frame(width: 84, height: 84)
                Image(systemName: interaction.icon)
                    .font(.system(size: 38))
                    .foregroundColor(interaction.fingerCount > 0 ? .cyan : foreground.opacity(0.6))
                    .scaleEffect(interaction.isDragging ? 1.2 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6),
                               value: interaction.isDragging)
            }
            Text("iPad Trackpad")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(foreground)
            Text(interaction.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(foreground.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            // 연결 상태
            HStack(spacing: 6) {
                Image(systemName: "wifi")
                Text(connectionState)
            }
            .font(.system(size: 12))
            .foregroundColor(foreground.opacity(0.35))
            .padding(.bottom, max(safeAreaBottom, 20) + 72)
            // ↑ 감도 버튼 높이(72)만큼 여백 확보
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)  // 레이블 영역은 터치 통과
    }
}
