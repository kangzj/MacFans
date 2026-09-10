import Foundation

public struct AppConfiguration: Codable, Equatable, Sendable {
    public static let pollIntervalRange: ClosedRange<TimeInterval> = 1...10
    public static let defaultConstantSpeed: FanSpeed = .percent(50)
    public static let `default` = AppConfiguration()

    public var profiles: [Profile] = []
    public var activeProfileID: UUID = Profile.balanced.id
    public var mode: ControlMode = .auto
    public var constantSpeeds: [FanID: FanSpeed] = [:]
    public var sensorOverrides: [SensorID: SensorOverride] = [:]
    public var pollInterval: TimeInterval = 2
    public var temperatureUnit: TemperatureUnit = .celsius
    public var menuBarReadout: MenuBarReadout = .cpu
    public var showAllSensors = false
    public var startInModeOnLaunch = false

    public var allProfiles: [Profile] {
        let builtInIDs = Set(Profile.builtIns.map(\.id))
        let builtIns = Profile.builtIns.map { builtIn in profiles.first { $0.id == builtIn.id } ?? builtIn }
        return builtIns + profiles.filter { !builtInIDs.contains($0.id) }
    }

    public func profile(id: UUID) -> Profile? {
        allProfiles.first { $0.id == id }
    }

    public func isModifiedBuiltIn(id: UUID) -> Bool {
        Profile.builtIns.contains { $0.id == id } && profiles.contains { $0.id == id }
    }

    public mutating func updateProfile(id: UUID, _ change: (inout Profile) -> Void) {
        if let index = profiles.firstIndex(where: { $0.id == id }) {
            change(&profiles[index])
        } else if var builtIn = Profile.builtIns.first(where: { $0.id == id }) {
            change(&builtIn)
            profiles.append(builtIn)
        }
    }

    public mutating func resetBuiltInProfile(id: UUID) {
        guard Profile.builtIns.contains(where: { $0.id == id }) else { return }
        profiles.removeAll { $0.id == id }
    }
}

extension AppConfiguration {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.default
        profiles = try container.decodeIfPresent([Profile].self, forKey: .profiles) ?? defaults.profiles
        activeProfileID = try container.decodeIfPresent(UUID.self, forKey: .activeProfileID) ?? defaults.activeProfileID
        mode = try container.decodeIfPresent(ControlMode.self, forKey: .mode) ?? defaults.mode
        constantSpeeds = try container.decodeIfPresent([FanID: FanSpeed].self, forKey: .constantSpeeds) ?? defaults.constantSpeeds
        sensorOverrides = try container.decodeIfPresent([SensorID: SensorOverride].self, forKey: .sensorOverrides) ?? defaults.sensorOverrides
        pollInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .pollInterval) ?? defaults.pollInterval
        temperatureUnit = try container.decodeIfPresent(TemperatureUnit.self, forKey: .temperatureUnit) ?? defaults.temperatureUnit
        menuBarReadout = try container.decodeIfPresent(MenuBarReadout.self, forKey: .menuBarReadout) ?? defaults.menuBarReadout
        showAllSensors = try container.decodeIfPresent(Bool.self, forKey: .showAllSensors) ?? defaults.showAllSensors
        startInModeOnLaunch = try container.decodeIfPresent(Bool.self, forKey: .startInModeOnLaunch) ?? defaults.startInModeOnLaunch
    }
}
