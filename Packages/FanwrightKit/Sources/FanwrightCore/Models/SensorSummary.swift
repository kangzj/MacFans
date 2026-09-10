public struct SensorSummary: Identifiable, Hashable, Sendable {
    public let family: SensorFamily
    public let max: Double
    public let average: Double
    public let sensorIDs: [SensorID]

    public var id: SensorFamily { family }
    public var title: String { family.title }
    public var group: SensorGroup { family.group }
}
