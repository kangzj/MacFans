public struct SensorReading: Codable, Hashable, Sendable {
    public let id: SensorID
    public let celsius: Double

    public init(id: SensorID, celsius: Double) {
        self.id = id
        self.celsius = celsius
    }
}
