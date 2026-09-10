import Foundation
import MacFansCore
import Testing

@Suite struct ConfigurationStoreTests {
    func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    @Test func loadsDefaultWhenMissing() {
        #expect(ConfigurationStore(directory: tempDirectory()).load() == .default)
    }

    @Test func roundTrips() throws {
        let store = ConfigurationStore(directory: tempDirectory())
        var config = AppConfiguration.default
        config.mode = .custom
        config.pollInterval = 5
        config.menuBarReadout = .fanRPM(FanID(rawValue: 0))
        config.profiles = [
            Profile(
                id: UUID(),
                name: "Mine",
                rules: [Rule(name: "r", trigger: .sensor(SensorID(rawValue: "Tp00")), onAbove: 70, speed: .rpm(4000))],
                isBuiltIn: false
            ),
        ]
        config.sensorOverrides[SensorID(rawValue: "Tp00")] = SensorOverride(name: "Core", isFavorite: true)
        config.constantSpeeds[FanID(rawValue: 1)] = .percent(80)
        try store.save(config)
        #expect(store.load() == config)
    }

    @Test func encodesIdentifierKeyedDictionariesAsObjects() throws {
        let directory = tempDirectory()
        var config = AppConfiguration.default
        config.sensorOverrides[SensorID(rawValue: "Tp00")] = SensorOverride(isFavorite: true)
        config.constantSpeeds[FanID(rawValue: 1)] = .percent(80)
        try ConfigurationStore(directory: directory).save(config)
        let json = try String(contentsOf: directory.appendingPathComponent("configuration.json"), encoding: .utf8)
        #expect(json.contains("\"Tp00\" : {"))
        #expect(json.contains("\"1\" : {"))
    }

    @Test func toleratesMissingFields() throws {
        let directory = tempDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try #"{"mode":"constant"}"#.write(to: directory.appendingPathComponent("configuration.json"), atomically: true, encoding: .utf8)
        let config = ConfigurationStore(directory: directory).load()
        #expect(config.mode == .constant)
        #expect(config.pollInterval == 2)
        #expect(config.activeProfileID == Profile.balanced.id)
    }

    @Test func loadsDefaultWhenCorrupt() throws {
        let directory = tempDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try "not json".write(to: directory.appendingPathComponent("configuration.json"), atomically: true, encoding: .utf8)
        #expect(ConfigurationStore(directory: directory).load() == .default)
    }

    @Test func allProfilesIncludesBuiltIns() {
        #expect(AppConfiguration.default.allProfiles.count == Profile.builtIns.count)
        #expect(AppConfiguration.default.profile(id: Profile.cool.id) == Profile.cool)
        #expect(AppConfiguration.default.profile(id: UUID()) == nil)
    }

    @Test func builtInProfilesAreEditableAndResettable() {
        var config = AppConfiguration.default
        let id = Profile.quiet.id
        #expect(!config.isModifiedBuiltIn(id: id))
        config.updateProfile(id: id) { $0.name = "Library" }
        #expect(config.profile(id: id)?.name == "Library")
        #expect(config.profile(id: id)?.isBuiltIn == true)
        #expect(config.isModifiedBuiltIn(id: id))
        #expect(config.allProfiles.count == Profile.builtIns.count)
        #expect(config.allProfiles.first?.id == id)
        config.resetBuiltInProfile(id: id)
        #expect(config.profile(id: id)?.name == Profile.quiet.name)
        #expect(!config.isModifiedBuiltIn(id: id))
    }
}
