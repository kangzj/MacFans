public enum FanCommand: Equatable, Sendable {
    case auto
    case forced(rpm: Double)

    var rpm: Double {
        switch self {
        case .auto: 0
        case .forced(let rpm): rpm
        }
    }
}
