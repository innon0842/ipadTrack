struct SensitivityLevel: Identifiable, Equatable {
    let id: String
    let label: String
    let value: Float

    static let presets: [SensitivityLevel] = [
        .init(id: "slow", label: "느림", value: 0.6),
        .init(id: "normal", label: "보통", value: 1.0),
        .init(id: "fast", label: "빠름", value: 1.5),
        .init(id: "vfast", label: "매우빠름", value: 2.2),
    ]

    static func resolve(id: String) -> SensitivityLevel {
        presets.first(where: { $0.id == id }) ?? presets[1]
    }
}
