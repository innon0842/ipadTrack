import AppKit
import Observation

/// 서버 기능의 조립 지점입니다. 화면에 노출하는 상태는 main actor에서 갱신합니다.
@MainActor
@Observable
final class TrackpadServerModule {
    private(set) var status = ServerStatus()
    private(set) var screenInfo: String
    let localIP: String
    let configuration: ServerConfiguration

    @ObservationIgnored private let cursor: CursorService
    @ObservationIgnored private let controller: TrackpadCommandController
    @ObservationIgnored private let screenService: ScreenInfoService
    @ObservationIgnored private var transport: UDPServerService?
    @ObservationIgnored private var receivedPacketCount = 0

    init(configuration: ServerConfiguration = ServerConfiguration()) {
        self.configuration = configuration
        let screens = ScreenInfoService()
        let snapshot = screens.snapshot()
        screenService = screens
        screenInfo = snapshot.description
        localIP = NetworkInfoService().localIPv4Address()
        let cursor = CursorService(
            sensitivity: configuration.cursorSensitivity,
            screens: snapshot,
            initialPosition: screens.cursorPosition()
        )
        self.cursor = cursor
        controller = TrackpadCommandController(cursor: cursor, keyboard: KeyboardService())
        transport = UDPServerService(
            port: configuration.port,
            onPacket: { [weak self] packet in
                DispatchQueue.main.async { self?.receive(packet) }
            },
            onRunningChanged: { [weak self] isRunning in
                DispatchQueue.main.async { self?.status.isRunning = isRunning }
            }
        )
        transport?.start()
    }

    func refreshScreens() {
        let snapshot = screenService.snapshot()
        screenInfo = snapshot.description
        cursor.updateScreenBounds(snapshot)
    }

    private func receive(_ packet: TrackpadPacketDTO) {
        controller.handle(packet)
        receivedPacketCount += 1
        if receivedPacketCount % max(configuration.statusUpdateInterval, 1) == 0 {
            status.packetCount = receivedPacketCount
            status.lastCommand = packet.commandDescription
        }
    }

    deinit { transport?.stop() }
}
