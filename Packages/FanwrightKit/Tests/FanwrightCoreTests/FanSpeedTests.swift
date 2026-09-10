import Foundation
import FanwrightCore
import Testing

@Suite struct FanSpeedTests {
    let limits = FanLimits(id: FanID(rawValue: 0), minRPM: 1000, maxRPM: 5000)

    @Test func rpmIsClamped() {
        #expect(FanSpeed.rpm(500).rpm(for: limits) == 1000)
        #expect(FanSpeed.rpm(9000).rpm(for: limits) == 5000)
        #expect(FanSpeed.rpm(3000).rpm(for: limits) == 3000)
    }

    @Test func percentMapsOntoRange() {
        #expect(FanSpeed.percent(0).rpm(for: limits) == 1000)
        #expect(FanSpeed.percent(50).rpm(for: limits) == 3000)
        #expect(FanSpeed.percent(150).rpm(for: limits) == 5000)
    }

    @Test func maxIsMax() {
        #expect(FanSpeed.max.rpm(for: limits) == 5000)
    }

    @Test func ruleDefaultsHysteresis() {
        let rule = Rule(name: "x", trigger: .group(.cpu, .max), onAbove: 80, speed: .max)
        #expect(rule.offBelow == 75)
        #expect(rule.isValid)
    }

    @Test func builtInsAreValidAndStable() {
        #expect(Profile.builtIns.allSatisfy { $0.isBuiltIn && $0.rules.allSatisfy(\.isValid) })
        #expect(Profile.quiet.id == Profile.quiet.id)
        #expect(Set(Profile.builtIns.map(\.id)).count == Profile.builtIns.count)
    }

    @Test func modelsRoundTripJSON() throws {
        let data = try JSONEncoder().encode(Profile.balanced)
        #expect(try JSONDecoder().decode(Profile.self, from: data) == Profile.balanced)
    }

    @Test func identifiersEncodeAsRawValues() throws {
        let sensorJSON = try JSONEncoder().encode(SensorID(rawValue: "Tp00"))
        #expect(String(decoding: sensorJSON, as: UTF8.self) == "\"Tp00\"")
        let fanJSON = try JSONEncoder().encode(FanID(rawValue: 1))
        #expect(String(decoding: fanJSON, as: UTF8.self) == "1")
    }
}
