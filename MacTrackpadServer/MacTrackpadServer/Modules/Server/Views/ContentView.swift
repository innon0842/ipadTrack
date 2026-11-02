import SwiftUI
import AppKit

struct ContentView: View {
    @State private var server = TrackpadServerModule()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hue: 0.62, saturation: 0.55, brightness: 0.15),
                         Color(hue: 0.72, saturation: 0.60, brightness: 0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("🖥️ Mac Trackpad Server")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("UDP Port \(server.configuration.port) · \(TrackpadPacketDTO.byteCount)-byte Protocol")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.top, 36)

                ServerStatusCard(
                    status: server.status,
                    localIP: server.localIP,
                    screenInfo: server.screenInfo
                )
                GestureGuideView()
                AccessibilityNoticeView()

                Spacer()
            }
        }
        .frame(minWidth: 440, minHeight: 620)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            server.refreshScreens()
        }
    }
}

#Preview { ContentView() }
