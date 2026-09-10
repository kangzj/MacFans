public struct FanLimits: Codable, Hashable, Sendable {
    public let id: FanID
    public let minRPM: Double
    public let maxRPM: Double

    public init(id: FanID, minRPM: Double, maxRPM: Double) {
        self.id = id
        self.minRPM = minRPM
        self.maxRPM = maxRPM
    }

    func clamped(_ rpm: Double) -> Double {
        min(max(rpm, minRPM), maxRPM)
    }
}
