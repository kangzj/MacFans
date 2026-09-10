public struct SensorID: RawRepresentable, Codable, CodingKeyRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
