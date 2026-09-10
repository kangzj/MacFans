public enum FanSelection: Codable, Hashable, Sendable {
    case all
    case some(Set<FanID>)

    public func contains(_ id: FanID) -> Bool {
        switch self {
        case .all: true
        case .some(let ids): ids.contains(id)
        }
    }
}
