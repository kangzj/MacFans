import Foundation

public enum ControlPlanner {
    public static func plan(
        mode: ControlMode,
        isBoosting: Bool,
        constantSpeeds: [FanID: FanSpeed],
        profile: Profile,
        readings: [SensorReading],
        sensors: [Sensor],
        fans: [FanLimits],
        previous: RuleEngineState,
        now: Date
    ) -> RuleEvaluation {
        if isBoosting {
            return uniform(fans) { .forced(rpm: $0.maxRPM) }
        }
        switch mode {
        case .auto:
            return uniform(fans) { _ in .auto }
        case .constant:
            return uniform(fans) { fan in
                .forced(rpm: (constantSpeeds[fan.id] ?? AppConfiguration.defaultConstantSpeed).rpm(for: fan))
            }
        case .custom:
            return RuleEngine.evaluate(profile: profile, readings: readings, sensors: sensors, fans: fans, previous: previous, now: now)
        }
    }

    private static func uniform(_ fans: [FanLimits], _ command: (FanLimits) -> FanCommand) -> RuleEvaluation {
        RuleEvaluation(
            commands: Dictionary(uniqueKeysWithValues: fans.map { ($0.id, command($0)) }),
            state: RuleEngineState(),
            triggerValues: [:]
        )
    }
}
