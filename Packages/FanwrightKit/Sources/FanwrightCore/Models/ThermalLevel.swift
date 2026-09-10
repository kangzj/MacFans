public enum ThermalLevel: CaseIterable, Sendable {
    case cool, warm, hot, critical

    public init(celsius: Double) {
        switch celsius {
        case ..<60: self = .cool
        case ..<80: self = .warm
        case ..<95: self = .hot
        default: self = .critical
        }
    }

    public var label: String {
        switch self {
        case .cool: "Running cool"
        case .warm: "Getting warm"
        case .hot: "Running hot"
        case .critical: "Very hot"
        }
    }
}
