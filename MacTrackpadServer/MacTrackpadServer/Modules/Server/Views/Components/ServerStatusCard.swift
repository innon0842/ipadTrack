import SwiftUI

struct ServerStatusCard: View {
    let status: ServerStatus
    let localIP: String
    let screenInfo: String

    var body: some View {
        VStack(spacing: 16) {
            ServerStatusRow(icon: "wifi.circle.fill",
                            label: "서버 상태",
                            value: status.isRunning ? "수신 중 ✅" : "시작 중…",
                            color: status.isRunning ? .green : .orange)
            Divider().background(Color.white.opacity(0.12))
            ServerStatusRow(icon: "network",
                            label: "이 맥북 IP",
                            value: localIP,
                            color: .cyan)
            Divider().background(Color.white.opacity(0.12))
            ServerStatusRow(icon: "display.2",
                            label: "모니터",
                            value: screenInfo,
                            color: Color(hue: 0.55, saturation: 0.6, brightness: 0.9))
            Divider().background(Color.white.opacity(0.12))
            ServerStatusRow(icon: "arrow.down.circle.fill",
                            label: "마지막 명령",
                            value: status.lastCommand,
                            color: .white)
            Divider().background(Color.white.opacity(0.12))
            ServerStatusRow(icon: "tray.2.fill",
                            label: "수신 패킷",
                            value: "\(status.packetCount) 개",
                            color: Color(hue: 0.75, saturation: 0.6, brightness: 0.9))
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 28)
    }
}
