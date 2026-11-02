import Foundation
import Network

/// 리스너와 접속 목록은 networkQueue에서만 변경합니다.
nonisolated final class UDPServerService: @unchecked Sendable {
    private let networkQueue = DispatchQueue(label: "trackpad.network", qos: .userInteractive)
    private let port: UInt16
    private let onPacket: @Sendable (TrackpadPacketDTO) -> Void
    private let onRunningChanged: @Sendable (Bool) -> Void
    private var listener: NWListener?
    private var connections: [UUID: NWConnection] = [:]

    init(port: UInt16,
         onPacket: @escaping @Sendable (TrackpadPacketDTO) -> Void,
         onRunningChanged: @escaping @Sendable (Bool) -> Void) {
        self.port = port
        self.onPacket = onPacket
        self.onRunningChanged = onRunningChanged
    }

    func start() {
        networkQueue.async { [self] in
            guard listener == nil, let endpointPort = NWEndpoint.Port(rawValue: port) else { return }
            do {
                let listener = try NWListener(using: .udp, on: endpointPort)
                listener.newConnectionHandler = { [weak self] connection in
                    self?.accept(connection)
                }
                listener.stateUpdateHandler = { [weak self, weak listener] state in
                    guard let self, self.listener === listener else { return }
                    onRunningChanged(state == .ready)
                }
                self.listener = listener
                listener.start(queue: networkQueue)
            } catch {
                onRunningChanged(false)
                print("리스너 생성 실패: \(error)")
            }
        }
    }

    func stop() {
        networkQueue.async { [self] in
            listener?.cancel()
            listener = nil
            connections.values.forEach { $0.cancel() }
            connections.removeAll()
            onRunningChanged(false)
        }
    }

    private func accept(_ connection: NWConnection) {
        let id = UUID()
        connections[id] = connection
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .failed, .cancelled:
                self?.connections.removeValue(forKey: id)?.cancel()
            default: break
            }
        }
        connection.start(queue: networkQueue)
        receive(on: connection, id: id)
    }

    private func receive(on connection: NWConnection, id: UUID) {
        connection.receiveMessage { [weak self] data, _, _, error in
            guard let self, connections[id] != nil else { return }
            guard error == nil else {
                connections.removeValue(forKey: id)?.cancel()
                return
            }
            if let data, let packet = TrackpadPacketDTO(data: data) {
                onPacket(packet)
            }
            receive(on: connection, id: id)
        }
    }

    deinit {
        listener?.cancel()
        connections.values.forEach { $0.cancel() }
    }
}
