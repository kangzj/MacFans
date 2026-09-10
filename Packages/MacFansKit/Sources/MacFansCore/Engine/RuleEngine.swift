import Foundation

public enum RuleEngine {
    public static let lowerDwell: TimeInterval = 5

    public static func triggerValue(_ trigger: RuleTrigger, readings: [SensorReading], sensors: [Sensor]) -> Double? {
        switch trigger {
        case .sensor(let id):
            return readings.first { $0.id == id }?.celsius
        case .group(let group, let aggregate):
            let ids = Set(sensors.filter { $0.group == group }.map(\.id))
            return aggregate.value(of: readings.filter { ids.contains($0.id) }.map(\.celsius))
        }
    }

    public static func evaluate(
        profile: Profile,
        readings: [SensorReading],
        sensors: [Sensor],
        fans: [FanLimits],
        previous: RuleEngineState,
        now: Date
    ) -> RuleEvaluation {
        let evaluatedRules = profile.rules.map { ($0, triggerValue($0.trigger, readings: readings, sensors: sensors)) }
        let activeRules = evaluatedRules.compactMap { rule, value -> Rule? in
            guard rule.isEnabled, rule.isValid, let value else { return nil }
            let stillActive = previous.activeRuleIDs.contains(rule.id) && value > rule.offBelow
            return value >= rule.onAbove || stillActive ? rule : nil
        }

        var state = RuleEngineState()
        state.activeRuleIDs = Set(activeRules.map(\.id))
        for fan in fans {
            let previousCommand = previous.lastCommands[fan.id] ?? .auto
            let previousRaise = previous.lastRaised[fan.id]
            var command = desiredCommand(for: fan, activeRules: activeRules)
            if command.rpm < previousCommand.rpm, let previousRaise, now.timeIntervalSince(previousRaise) < lowerDwell {
                command = previousCommand
            }
            state.lastCommands[fan.id] = command
            state.lastRaised[fan.id] = command.rpm > previousCommand.rpm ? now : previousRaise
        }

        return RuleEvaluation(
            commands: state.lastCommands,
            state: state,
            triggerValues: Dictionary(evaluatedRules.map { ($0.id, $1) }, uniquingKeysWith: { $1 })
        )
    }

    private static func desiredCommand(for fan: FanLimits, activeRules: [Rule]) -> FanCommand {
        let rpm = activeRules.lazy.filter { $0.fans.contains(fan.id) }.map { $0.speed.rpm(for: fan) }.max()
        return rpm.map { .forced(rpm: $0) } ?? .auto
    }
}
