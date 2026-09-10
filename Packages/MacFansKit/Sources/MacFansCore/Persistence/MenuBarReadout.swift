public enum MenuBarReadout: Codable, Hashable, Sendable {
    case cpu
    case sensor(SensorID)
    case fanRPM(FanID)
    case none
}
