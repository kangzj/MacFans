public struct SensorOverride: Codable, Hashable, Sendable {
    public var name: String?
    public var isFavorite: Bool

    public init(name: String? = nil, isFavorite: Bool = false) {
        self.name = name
        self.isFavorite = isFavorite
    }
}
