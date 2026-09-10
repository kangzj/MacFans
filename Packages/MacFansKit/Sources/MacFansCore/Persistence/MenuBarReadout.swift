public enum MenuBarReadout: Codable, Hashable, Sendable {
    case hottest
    case sensor(SensorID)
    case fanRPM(FanID)
    case none
}
