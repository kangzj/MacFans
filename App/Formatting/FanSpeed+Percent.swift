import MacFansCore

extension FanSpeed {
    func percent(for limits: FanLimits) -> Double {
        switch self {
        case .percent(let value): Swift.min(Swift.max(value, 0), 100)
        case .max: 100
        case .rpm: (rpm(for: limits) - limits.minRPM) / Swift.max(limits.maxRPM - limits.minRPM, 1) * 100
        }
    }
}
