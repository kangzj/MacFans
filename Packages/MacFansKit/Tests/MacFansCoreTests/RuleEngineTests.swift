import Foundation
import MacFansCore
import Testing

@Suite struct RuleEngineTests {
    let cpu1 = Sensor(id: SensorID(rawValue: "Tp00"), name: "CPU 1", group: .cpu, isFavorite: false)
    let cpu2 = Sensor(id: SensorID(rawValue: "Tp04"), name: "CPU 2", group: .cpu, isFavorite: false)
    let fan0 = FanLimits(id: FanID(rawValue: 0), minRPM: 1000, maxRPM: 5000)
    let fan1 = FanLimits(id: FanID(rawValue: 1), minRPM: 1000, maxRPM: 6000)
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    var sensors: [Sensor] { [cpu1, cpu2] }

    func readings(_ a: Double, _ b: Double) -> [SensorReading] {
        [SensorReading(id: cpu1.id, celsius: a), SensorReading(id: cpu2.id, celsius: b)]
    }

    func profile(_ rules: Rule...) -> Profile {
        Profile(id: UUID(), name: "p", rules: rules, isBuiltIn: false)
    }

    @Test func groupAggregates() {
        #expect(RuleEngine.triggerValue(.group(.cpu, .max), readings: readings(50, 70), sensors: sensors) == 70)
        #expect(RuleEngine.triggerValue(.group(.cpu, .average), readings: readings(50, 70), sensors: sensors) == 60)
        #expect(RuleEngine.triggerValue(.group(.gpu, .max), readings: readings(50, 70), sensors: sensors) == nil)
        #expect(RuleEngine.triggerValue(.sensor(cpu2.id), readings: readings(50, 70), sensors: sensors) == 70)
    }

    @Test func inactiveRulesYieldAuto() {
        let p = profile(Rule(name: "r", trigger: .group(.cpu, .max), onAbove: 80, speed: .max))
        let e = RuleEngine.evaluate(profile: p, readings: readings(50, 60), sensors: sensors, fans: [fan0, fan1], previous: .init(), now: t0)
        #expect(e.commands == [fan0.id: .auto, fan1.id: .auto])
        #expect(e.triggerValues.values.first == 60)
    }

    @Test func activatesAboveThresholdAndHoldsUntilOffBelow() {
        let p = profile(Rule(name: "r", trigger: .group(.cpu, .max), onAbove: 80, offBelow: 70, speed: .percent(50)))
        let on = RuleEngine.evaluate(profile: p, readings: readings(0, 81), sensors: sensors, fans: [fan0], previous: .init(), now: t0)
        #expect(on.commands[fan0.id] == .forced(rpm: 3000))
        let held = RuleEngine.evaluate(profile: p, readings: readings(0, 75), sensors: sensors, fans: [fan0], previous: on.state, now: t0 + 10)
        #expect(held.commands[fan0.id] == .forced(rpm: 3000))
        let off = RuleEngine.evaluate(profile: p, readings: readings(0, 70), sensors: sensors, fans: [fan0], previous: held.state, now: t0 + 20)
        #expect(off.commands[fan0.id] == .auto)
    }

    @Test func highestActiveRuleWinsPerFan() {
        let low = Rule(name: "low", trigger: .group(.cpu, .max), onAbove: 60, speed: .percent(25))
        let high = Rule(name: "high", trigger: .group(.cpu, .max), onAbove: 80, fans: .some([fan1.id]), speed: .max)
        let e = RuleEngine.evaluate(profile: profile(low, high), readings: readings(85, 85), sensors: sensors, fans: [fan0, fan1], previous: .init(), now: t0)
        #expect(e.commands[fan0.id] == .forced(rpm: 2000))
        #expect(e.commands[fan1.id] == .forced(rpm: 6000))
    }

    @Test func loweringWaitsForDwell() {
        let p = profile(Rule(name: "r", trigger: .group(.cpu, .max), onAbove: 80, offBelow: 70, speed: .max))
        let on = RuleEngine.evaluate(profile: p, readings: readings(0, 90), sensors: sensors, fans: [fan0], previous: .init(), now: t0)
        let tooSoon = RuleEngine.evaluate(profile: p, readings: readings(0, 50), sensors: sensors, fans: [fan0], previous: on.state, now: t0 + 2)
        #expect(tooSoon.commands[fan0.id] == .forced(rpm: 5000))
        let later = RuleEngine.evaluate(profile: p, readings: readings(0, 50), sensors: sensors, fans: [fan0], previous: tooSoon.state, now: t0 + 6)
        #expect(later.commands[fan0.id] == .auto)
    }

    @Test func disabledAndMissingDataAreIgnored() {
        var rule = Rule(name: "r", trigger: .sensor(SensorID(rawValue: "Tg00")), onAbove: 10, speed: .max)
        let missing = RuleEngine.evaluate(profile: profile(rule), readings: readings(99, 99), sensors: sensors, fans: [fan0], previous: .init(), now: t0)
        #expect(missing.commands[fan0.id] == .auto)
        #expect(missing.triggerValues[rule.id] == .some(nil))
        rule = Rule(name: "r", trigger: .group(.cpu, .max), onAbove: 10, speed: .max)
        rule.isEnabled = false
        let disabled = RuleEngine.evaluate(profile: profile(rule), readings: readings(99, 99), sensors: sensors, fans: [fan0], previous: .init(), now: t0)
        #expect(disabled.commands[fan0.id] == .auto)
    }
}
