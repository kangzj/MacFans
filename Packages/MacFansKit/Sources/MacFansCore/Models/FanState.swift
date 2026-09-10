public struct FanState: Identifiable, Codable, Hashable, Sendable {
    public let id: FanID
    public var name: String
    public var limits: FanLimits
    public var actualRPM: Double
    public var targetRPM: Double
    public var isForced: Bool

    public init(id: FanID, name: String, limits: FanLimits, actualRPM: Double, targetRPM: Double, isForced: Bool) {
        self.id = id
        self.name = name
        self.limits = limits
        self.actualRPM = actualRPM
        self.targetRPM = targetRPM
        self.isForced = isForced
    }

    public static func defaultName(index: Int, count: Int) -> String {
        switch (count, index) {
        case (2, 0): "Left Fan"
        case (2, 1): "Right Fan"
        default: "Fan \(index + 1)"
        }
    }
}
