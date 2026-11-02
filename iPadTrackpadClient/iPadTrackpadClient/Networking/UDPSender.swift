import Foundation
import Network
import Observation

@Observable
class UDPSender {
    var connectionState = "연결 중..."
    private var connection: NWConnection?
    private let serverIP   = "192.168.0.185"
    private let serverPort: UInt16 = 12345

    // 명령(UInt16), 예약 필드(UInt16), 이동량(Float × 2)의 12바이트 패킷입니다.
    private var pktBuf: (UInt16, UInt16, Float, Float) = (0, 0, 0, 0)

    init() { connect() }

    private func connect() {
        connection?.cancel()
        let conn = NWConnection(
            host: NWEndpoint.Host(serverIP),
            port: NWEndpoint.Port(rawValue: serverPort)!,
            using: .udp
        )
        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:   self?.connectionState = "연결됨 ✅"
                case .failed:
                    self?.connectionState = "재연결 중..."
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1) { self?.connect() }
                case .waiting:
                    self?.connectionState = "대기 중..."
                    DispatchQueue.global().asyncAfter(deadline: .now() + 3) { self?.connect() }
                default: self?.connectionState = "연결 중..."
                }
            }
        }
        conn.start(queue: .global(qos: .userInteractive))
        connection = conn
    }

    @inline(__always)
    func send(_ cmd: TrackpadCommand, p1: Float = 0, p2: Float = 0) {
        // 스택 변수에 12바이트 쓰고 Data 래핑
        pktBuf = (cmd.rawValue, 0, p1, p2)
        withUnsafeBytes(of: &pktBuf) { rawPtr in
            let data = Data(rawPtr)
            connection?.send(content: data, completion: .idempotent)
        }
    }

    deinit { connection?.cancel() }
}
