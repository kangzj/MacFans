public struct SensorSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let group: SensorGroup
    public let max: Double
    public let average: Double
    public let sensorIDs: [SensorID]
}
