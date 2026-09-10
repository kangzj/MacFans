public struct Sensor: Identifiable, Codable, Hashable, Sendable {
    public let id: SensorID
    public var name: String
    public var group: SensorGroup
    public var isFavorite: Bool

    public init(id: SensorID, name: String, group: SensorGroup, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.group = group
        self.isFavorite = isFavorite
    }
}
