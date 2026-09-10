import Foundation
import Testing
@testable import FanwrightCore

@Suite struct ThermalLevelTests {
    @Test func thresholds() {
        #expect(ThermalLevel(celsius: 59.9) == .cool)
        #expect(ThermalLevel(celsius: 60) == .warm)
        #expect(ThermalLevel(celsius: 80) == .hot)
        #expect(ThermalLevel(celsius: 95) == .critical)
        #expect(ThermalLevel(celsius: 95).label == "Very hot")
    }
}

@Suite struct TemperatureUnitTests {
    @Test func convertsBothWays() {
        #expect(TemperatureUnit.fahrenheit.convert(celsius: 100) == 212)
        #expect(TemperatureUnit.fahrenheit.celsius(from: 212) == 100)
        #expect(TemperatureUnit.celsius.convert(celsius: 37) == 37)
        #expect(TemperatureUnit.celsius.symbol == "°C")
        #expect(TemperatureUnit.fahrenheit.symbol == "°F")
    }
}

@Suite struct FanStateNamingTests {
    @Test func namesTwoFansLeftAndRight() {
        #expect(FanState.defaultName(index: 0, count: 2) == "Left Fan")
        #expect(FanState.defaultName(index: 1, count: 2) == "Right Fan")
        #expect(FanState.defaultName(index: 0, count: 1) == "Fan 1")
        #expect(FanState.defaultName(index: 2, count: 3) == "Fan 3")
    }
}

@Suite struct FanSpeedPercentTests {
    let limits = FanLimits(id: FanID(rawValue: 0), minRPM: 1000, maxRPM: 5000)

    @Test func percentRoundTripsThroughRPM() {
        #expect(FanSpeed.percent(25).percent(for: limits) == 25)
        #expect(FanSpeed.percent(140).percent(for: limits) == 100)
        #expect(FanSpeed.max.percent(for: limits) == 100)
        #expect(FanSpeed.rpm(3000).percent(for: limits) == 50)
        #expect(FanSpeed.rpm(100).percent(for: limits) == 0)
    }
}

@Suite struct ProfileManagementTests {
    @Test func addsAndDuplicatesWithUniqueNames() {
        var config = AppConfiguration.default
        let first = config.addProfile()
        let second = config.addProfile()
        #expect(first.name == "New Profile")
        #expect(second.name == "New Profile 2")
        let copy = config.duplicateProfile(id: Profile.balanced.id)
        #expect(copy?.name == "Balanced Copy")
        #expect(copy?.rules.count == Profile.balanced.rules.count)
        #expect(copy?.rules.map(\.id).contains(Profile.balanced.rules[0].id) == false)
        #expect(config.allProfiles.count == Profile.builtIns.count + 3)
    }

    @Test func deleteRespectsBuiltInsAndActiveProfile() {
        var config = AppConfiguration.default
        let mine = config.addProfile()
        #expect(!config.canDeleteProfile(id: Profile.quiet.id))
        config.activeProfileID = mine.id
        #expect(!config.canDeleteProfile(id: mine.id))
        config.activeProfileID = Profile.balanced.id
        #expect(config.canDeleteProfile(id: mine.id))
        config.deleteProfile(id: mine.id)
        #expect(config.profile(id: mine.id) == nil)
    }

    @Test func sensorOverridesTrimAndToggle() {
        var config = AppConfiguration.default
        let id = SensorID(rawValue: "Tp00")
        config.setSensorName("  Core 1 ", for: id)
        #expect(config.sensorOverrides[id]?.name == "Core 1")
        config.setSensorName("   ", for: id)
        #expect(config.sensorOverrides[id]?.name == nil)
        config.toggleFavorite(id)
        #expect(config.sensorOverrides[id]?.isFavorite == true)
    }
}

@Suite struct ControlPlannerTests {
    let fan0 = FanLimits(id: FanID(rawValue: 0), minRPM: 1000, maxRPM: 5000)
    let fan1 = FanLimits(id: FanID(rawValue: 1), minRPM: 1000, maxRPM: 6000)

    func plan(mode: ControlMode, boosting: Bool = false, speeds: [FanID: FanSpeed] = [:]) -> [FanID: FanCommand] {
        ControlPlanner.plan(
            mode: mode, isBoosting: boosting, constantSpeeds: speeds, profile: .balanced,
            readings: [], sensors: [], fans: [fan0, fan1], previous: RuleEngineState(), now: Date()
        ).commands
    }

    @Test func autoYieldsAutoForEveryFan() {
        #expect(plan(mode: .auto) == [fan0.id: .auto, fan1.id: .auto])
    }

    @Test func boostOverridesAnyMode() {
        #expect(plan(mode: .auto, boosting: true) == [fan0.id: .forced(rpm: 5000), fan1.id: .forced(rpm: 6000)])
    }

    @Test func constantUsesConfiguredOrDefaultSpeed() {
        let commands = plan(mode: .constant, speeds: [fan1.id: .percent(100)])
        #expect(commands[fan0.id] == .forced(rpm: 3000))
        #expect(commands[fan1.id] == .forced(rpm: 6000))
    }

    @Test func customWithNoReadingsFallsBackToAuto() {
        #expect(plan(mode: .custom) == [fan0.id: .auto, fan1.id: .auto])
    }
}
