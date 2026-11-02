import SwiftUI

struct ContentView: View {
    @State private var sender = UDPSender()
    @State private var interaction = TrackpadInteractionState()
    @State private var isPiP = false
    @State private var compactPosition = CGPoint.zero

    @AppStorage("isDark") private var isDark = true
    @AppStorage("sensLevel") private var sensitivityID = "normal"

    private var theme: TrackpadTheme { TrackpadTheme(isDark: isDark) }
    private var sensitivity: SensitivityLevel { .resolve(id: sensitivityID) }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                TrackpadBackground(theme: theme, showsGrid: !isPiP)

                TrackpadView(
                    sender: sender,
                    sensitivity: sensitivity.value,
                    onDraggingChanged: { interaction.isDragging = $0 },
                    onFingerCountChanged: { interaction.fingerCount = $0 }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

                if !isPiP {
                    TrackpadStatusView(
                        interaction: interaction,
                        connectionState: sender.connectionState,
                        foreground: theme.foreground,
                        safeAreaBottom: geometry.safeAreaInsets.bottom
                    )

                    SensitivityControl(
                        selectedID: $sensitivityID,
                        foreground: theme.foreground,
                        safeAreaBottom: geometry.safeAreaInsets.bottom
                    )

                    ThemeToggleButton(
                        isDark: $isDark,
                        foreground: theme.foreground,
                        safeAreaTop: geometry.safeAreaInsets.top
                    )
                }

                if isPiP {
                    CompactTrackpadView(
                        isPresented: $isPiP,
                        position: $compactPosition,
                        interaction: interaction,
                        connectionState: sender.connectionState,
                        containerSize: geometry.size,
                        safeAreaInsets: geometry.safeAreaInsets
                    )
                }
            }
            .coordinateSpace(name: "canvas")
        }
        .preferredColorScheme(isDark ? .dark : .light)
    }
}

#Preview { ContentView() }
