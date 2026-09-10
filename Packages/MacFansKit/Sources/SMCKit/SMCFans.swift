public struct FanReading: Sendable, Equatable {
    public let index: Int
    public let actualRPM: Double
    public let targetRPM: Double
    public let minRPM: Double
    public let maxRPM: Double
    public let isForced: Bool

    public init(index: Int, actualRPM: Double, targetRPM: Double, minRPM: Double, maxRPM: Double, isForced: Bool) {
        self.index = index
        self.actualRPM = actualRPM
        self.targetRPM = targetRPM
        self.minRPM = minRPM
        self.maxRPM = maxRPM
        self.isForced = isForced
    }
}

extension SMCConnection {
    private static let fanCountKey = SMCKey("FNum")

    public func fanCount() throws -> Int {
        Int(try readDouble(Self.fanCountKey))
    }

    public func fan(_ index: Int) throws -> FanReading {
        FanReading(
            index: index,
            actualRPM: try readDouble(fanKey(index, "Ac")),
            targetRPM: try readDouble(fanKey(index, "Tg")),
            minRPM: try readDouble(fanKey(index, "Mn")),
            maxRPM: try readDouble(fanKey(index, "Mx")),
            isForced: try readDouble(fanKey(index, "md")) != 0
        )
    }

    public func setFanForced(_ index: Int, _ forced: Bool) throws {
        try write(fanKey(index, "md"), value: forced ? 1 : 0)
    }

    public func setFanTarget(_ index: Int, rpm: Double) throws {
        try write(fanKey(index, "Tg"), value: rpm)
    }

    private func fanKey(_ index: Int, _ suffix: String) -> SMCKey {
        SMCKey("F\(index)\(suffix)")
    }
}
