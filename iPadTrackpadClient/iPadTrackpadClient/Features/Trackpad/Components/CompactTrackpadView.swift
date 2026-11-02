import SwiftUI

struct CompactTrackpadView: View {
    @Binding var isPresented: Bool
    @Binding var position: CGPoint
    let interaction: TrackpadInteractionState
    let connectionState: String
    let containerSize: CGSize
    let safeAreaInsets: EdgeInsets

    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        let size = max(80, min(containerSize.width * 0.2, 150))
        let drag = DragGesture(coordinateSpace: .named("canvas"))
            .updating($dragOffset) { v, state, _ in state = v.translation }
            .onEnded { v in
                let margin = size / 2 + 16
                let sx = v.location.x < containerSize.width  / 2 ? margin : containerSize.width  - margin
                let sy = v.location.y < containerSize.height / 2
                    ? safeAreaInsets.top + margin
                    : containerSize.height - safeAreaInsets.bottom - margin
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    position = CGPoint(x: sx, y: sy)
                }
            }

        ZStack {
            Circle().fill(.ultraThinMaterial)
                .overlay(Circle().stroke(interaction.fingerCount > 0 ? Color.cyan.opacity(0.7)
                                                         : Color.white.opacity(0.25), lineWidth: 1.5))
            VStack(spacing: 4) {
                Image(systemName: interaction.icon)
                    .font(.system(size: size * 0.26))
                    .foregroundColor(interaction.fingerCount > 0 ? .cyan : .white.opacity(0.8))
                Circle().fill(connectionState.contains("✅") ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)
            }
            VStack {
                HStack {
                    Spacer()
                    Button { withAnimation(.spring(response: 0.35)) { isPresented = false } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: max(size * 0.22, 16)))
                            .foregroundColor(.white.opacity(0.65))
                    }.buttonStyle(.plain)
                }
                Spacer()
            }.padding(6)
        }
        .frame(width: size, height: size)
        .position(x: position.x + dragOffset.width, y: position.y + dragOffset.height)
        .gesture(drag)
    }
}
