public enum FanSpeed: Codable, Hashable, Sendable {
    case rpm(Double)
    case percent(Double)
    case max

    public func rpm(for limits: FanLimits) -> Double {
        switch self {
        case .rpm(let rpm):
            limits.clamped(rpm)
        case .percent(let percent):
            limits.clamped(limits.minRPM + (limits.maxRPM - limits.minRPM) * percent / 100)
        case .max:
            limits.maxRPM
        }
    }
}
