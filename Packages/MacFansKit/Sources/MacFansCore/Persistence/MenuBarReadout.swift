public enum MenuBarReadout: Codable, Hashable, Sendable {
    case family(SensorFamily)
    case hottest
    case sensor(SensorID)
    case fanRPM(FanID)
    case none
}
