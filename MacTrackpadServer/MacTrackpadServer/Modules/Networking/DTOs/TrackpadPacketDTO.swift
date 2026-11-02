import Foundation

/// Client의 [UInt16 command, UInt16 reserved, Float p1, Float p2] 형식입니다.
/// 기존 Apple 기기 간 12바이트 little-endian 프로토콜을 유지합니다.
nonisolated struct TrackpadPacketDTO: Sendable {
    static let byteCount = 12

    let commandRawValue: UInt16
    let reserved: UInt16
    let p1: Float
    let p2: Float

    var command: TrackpadCommand? { TrackpadCommand(rawValue: commandRawValue) }
    var commandDescription: String {
        command.map { "\($0)" } ?? "unknown(\(commandRawValue))"
    }

    init?(data: Data) {
        guard data.count == Self.byteCount else { return nil }
        let fields = data.withUnsafeBytes { bytes in
            (
                UInt16(littleEndian: bytes.loadUnaligned(fromByteOffset: 0, as: UInt16.self)),
                UInt16(littleEndian: bytes.loadUnaligned(fromByteOffset: 2, as: UInt16.self)),
                Float(bitPattern: UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: 4, as: UInt32.self))),
                Float(bitPattern: UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: 8, as: UInt32.self)))
            )
        }
        guard fields.2.isFinite, fields.3.isFinite else { return nil }
        commandRawValue = fields.0
        reserved = fields.1
        p1 = fields.2
        p2 = fields.3
    }
}
