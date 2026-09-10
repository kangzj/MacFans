public struct FanID: RawRepresentable, Codable, CodingKeyRepresentable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
