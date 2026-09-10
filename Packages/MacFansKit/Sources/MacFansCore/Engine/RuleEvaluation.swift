import Foundation

public struct RuleEvaluation: Equatable, Sendable {
    public let commands: [FanID: FanCommand]
    public let state: RuleEngineState
    public let triggerValues: [UUID: Double?]
}
