public enum RuleTrigger: Codable, Hashable, Sendable {
    case sensor(SensorID)
    case group(SensorGroup, Aggregate)
}
