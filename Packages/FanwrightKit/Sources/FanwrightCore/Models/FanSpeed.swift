public enum FanSpeed: Codable, Hashable, Sendable {
    case rpm(Double)
    case percent(Double)
    case max

    public func rpm(for limits: FanLimits) -> Double {
        switch self {
        case .rpm(let rpm):
            limits.clamped(rpm)
        case .percent(let percent):
            limits.clamped(limits.minRPM + limits.span * percent / 100)
        case .max:
            limits.maxRPM
        }
    }

    public func percent(for limits: FanLimits) -> Double {
        switch self {
        case .percent(let percent): Swift.min(Swift.max(percent, 0), 100)
        case .max: 100
        case .rpm: (rpm(for: limits) - limits.minRPM) / limits.span * 100
        }
    }
}
