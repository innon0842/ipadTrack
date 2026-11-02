import Foundation
import Network

/// 실제 마우스/키보드 이벤트를 발생시키지 않고 프로토콜과 UDP 수신을 검증합니다.
@main
struct ServerProtocolChecks {
    static func main() {
        // Client와 동일한 튜플 레이아웃 및 음수/소수 값 호환성.
        var clientPacket: (UInt16, UInt16, Float, Float) = (1, 0, 1.5, -2.25)
        let data = withUnsafeBytes(of: &clientPacket) { Data($0) }
        let packet = TrackpadPacketDTO(data: data)!
        precondition(packet.command == .mouseMove)
        precondition(packet.reserved == 0 && packet.p1 == 1.5 && packet.p2 == -2.25)

        // 명시적인 little-endian 바이트가 동일하게 해석되는지 검증.
        let knownBytes = Data([1, 0, 0, 0, 0, 0, 192, 63, 0, 0, 16, 192])
        precondition(TrackpadPacketDTO(data: knownBytes)?.p2 == -2.25)
        for size in [0, 1, 11, 13, 24] {
            precondition(TrackpadPacketDTO(data: Data(repeating: 0, count: size)) == nil)
        }
        for invalid: Float in [.nan, .infinity, -.infinity] {
            for index in [0, 1] {
                var values: (UInt16, UInt16, Float, Float) = (2, 0, 0, 0)
                if index == 0 { values.2 = invalid } else { values.3 = invalid }
                let bytes = withUnsafeBytes(of: &values) { Data($0) }
                precondition(TrackpadPacketDTO(data: bytes) == nil)
            }
        }
        let unknown = TrackpadPacketDTO(data: Data([255, 255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))!
        precondition(unknown.command == nil && unknown.commandDescription == "unknown(65535)")
        for rawValue: UInt16 in 1...10 {
            var values: (UInt16, UInt16, Float, Float) = (rawValue, 0, 0, 0)
            let bytes = withUnsafeBytes(of: &values) { Data($0) }
            precondition(TrackpadPacketDTO(data: bytes)?.command?.rawValue == rawValue)
        }
        print("PASS: packet compatibility, command IDs, length and numeric validation")

        let ready = DispatchSemaphore(value: 0)
        let received = DispatchSemaphore(value: 0)
        let stopped = DispatchSemaphore(value: 0)
        let port = UInt16.random(in: 49152...65535)
        let server = UDPServerService(
            port: port,
            onPacket: { packet in
                precondition(packet.command == .mouseMove && packet.p1 == 1.5 && packet.p2 == -2.25)
                received.signal()
            },
            onRunningChanged: { running in
                if running { ready.signal() } else { stopped.signal() }
            }
        )
        server.start()
        precondition(ready.wait(timeout: .now() + 5) == .success, "UDP listener did not become ready")
        let client = NWConnection(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: port)!, using: .udp)
        client.start(queue: DispatchQueue(label: "trackpad.test.client"))
        // 잘못된 크기의 datagram을 무시한 후에도 다음 정상 패킷을 받아야 합니다.
        client.send(content: Data([1]), completion: .idempotent)
        client.send(content: data, completion: .idempotent)
        precondition(received.wait(timeout: .now() + 5) == .success, "Valid packet was not received")
        client.cancel()
        server.stop()
        precondition(stopped.wait(timeout: .now() + 5) == .success, "UDP listener did not stop")
        server.start()
        precondition(ready.wait(timeout: .now() + 5) == .success, "UDP listener did not restart")
        server.stop()
        precondition(stopped.wait(timeout: .now() + 5) == .success)
        print("PASS: localhost UDP receive, malformed datagram recovery, stop and restart")
    }
}
