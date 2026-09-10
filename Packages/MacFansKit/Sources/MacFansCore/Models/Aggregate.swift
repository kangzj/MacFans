public enum Aggregate: String, CaseIterable, Codable, Hashable, Sendable {
    case max, average

    func value(of values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        switch self {
        case .max: return values.max()
        case .average: return values.reduce(0, +) / Double(values.count)
        }
    }
}
