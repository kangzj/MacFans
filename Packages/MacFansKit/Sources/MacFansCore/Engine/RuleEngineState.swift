import Foundation

public struct RuleEngineState: Equatable, Sendable {
    public var activeRuleIDs: Set<UUID>
    public var lastCommands: [FanID: FanCommand]
    public var lastRaised: [FanID: Date]

    public init() {
        activeRuleIDs = []
        lastCommands = [:]
        lastRaised = [:]
    }
}
