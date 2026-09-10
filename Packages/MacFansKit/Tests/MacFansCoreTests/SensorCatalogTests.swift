import MacFansCore
import Testing

@Suite struct SensorCatalogTests {
    @Test func plausibility() {
        #expect(SensorCatalog.isPlausible(celsius: 45))
        #expect(!SensorCatalog.isPlausible(celsius: 0))
        #expect(!SensorCatalog.isPlausible(celsius: -306_783_232))
        #expect(!SensorCatalog.isPlausible(celsius: 151))
    }

    @Test func numbersCoresInSortedOrder() {
        let sensors = SensorCatalog.sensors(for: ["Tp04", "Tp00", "Tp1E"])
        #expect(sensors.map(\.name) == ["CPU Performance Core 1", "CPU Performance Core 2", "CPU Efficiency Core 1"])
        #expect(sensors.map(\.group) == [.cpu, .cpu, .cpu])
    }

    @Test func mapsKnownKeysAndGroups() {
        let sensors = SensorCatalog.sensors(for: ["TB0T", "Tg3a", "TH0x", "TCMb", "TD00", "TVD0", "Tm0y", "ZZZZ"])
        let byKey = Dictionary(uniqueKeysWithValues: sensors.map { ($0.id.rawValue, $0) })
        #expect(byKey["TB0T"]?.group == .battery)
        #expect(byKey["Tg3a"]?.name == "GPU Cluster 3 Sensor 1")
        #expect(byKey["TH0x"]?.group == .storage)
        #expect(byKey["TCMb"]?.name == "SoC Package")
        #expect(byKey["TD00"]?.group == .display)
        #expect(byKey["TVD0"]?.group == .power)
        #expect(byKey["Tm0y"]?.group == .memory)
        #expect(byKey["ZZZZ"]?.group == .other)
        #expect(byKey["ZZZZ"]?.name == "ZZZZ")
    }

    @Test func appliesOverrides() {
        let overrides = [SensorID(rawValue: "TB0T"): SensorOverride(name: "Batt", isFavorite: true)]
        let sensors = SensorCatalog.sensors(for: ["TB0T"], overrides: overrides)
        #expect(sensors[0].name == "Batt")
        #expect(sensors[0].isFavorite)
    }

    @Test func summarisesFamiliesInFixedOrder() {
        let sensors = SensorCatalog.sensors(for: ["TW0P", "TB0T", "Tg0a", "Tg0b", "TCMb", "TCDX", "Tp00", "Tp04", "Tp1E", "TAOL", "Tm0y", "TH0x"])
        let readings = Dictionary(uniqueKeysWithValues: [
            ("Tp00", 50.0), ("Tp04", 70.0), ("Tp1E", 40.0), ("Tg0a", 60.0), ("Tg0b", 62.0),
            ("TCMb", 55.0), ("TCDX", 90.0), ("TB0T", 30.0), ("TW0P", 45.0), ("TAOL", 25.0),
        ].map { (SensorID(rawValue: $0), $1) })
        let summaries = SensorCatalog.summaries(sensors: sensors, readings: readings)
        #expect(summaries.map(\.id) == [.cpuPerformance, .cpuEfficiency, .gpu, .soc, .battery, .wifi, .ambient])
        #expect(summaries.map(\.title) == ["CPU Performance Cores", "CPU Efficiency Cores", "GPU", "SoC Package", "Battery", "Wi-Fi", "Ambient"])
        let byID = Dictionary(uniqueKeysWithValues: summaries.map { ($0.id, $0) })
        #expect(byID[.cpuPerformance]?.max == 70)
        #expect(byID[.cpuPerformance]?.average == 60)
        #expect(byID[.cpuPerformance]?.group == .cpu)
        #expect(byID[.cpuPerformance]?.sensorIDs == [SensorID(rawValue: "Tp00"), SensorID(rawValue: "Tp04")])
        #expect(byID[.gpu]?.max == 62)
        #expect(byID[.soc]?.max == 55)
        #expect(byID[.soc]?.sensorIDs == [SensorID(rawValue: "TCMb")])
        #expect(byID[.ambient]?.sensorIDs == [SensorID(rawValue: "TAOL")])
    }

    @Test func socFallsBackToAllSoCSensorsWithoutPackageKey() {
        let sensors = SensorCatalog.sensors(for: ["TCDX", "Ts0a"])
        let readings = [SensorID(rawValue: "TCDX"): 80.0, SensorID(rawValue: "Ts0a"): 60.0]
        let summaries = SensorCatalog.summaries(sensors: sensors, readings: readings)
        #expect(summaries.map(\.id) == [.soc])
        #expect(summaries[0].max == 80)
        #expect(summaries[0].average == 70)
        #expect(summaries[0].sensorIDs.count == 2)
    }

    @Test func legacyCoreKeysOnlyApplyWithoutTpKeys() {
        let m4 = SensorCatalog.sensors(for: ["Tf04", "Te05", "Tf14"])
        #expect(m4.map(\.group) == [.cpu, .cpu, .gpu])
        let m5 = SensorCatalog.sensors(for: ["Tp00", "Tf04", "Tf14"])
        #expect(m5.map(\.group) == [.other, .other, .cpu])
        #expect(m5[0].name == "Tf04")
        let summaries = SensorCatalog.summaries(sensors: m5, readings: [SensorID(rawValue: "Tp00"): 50, SensorID(rawValue: "Tf04"): 90])
        #expect(summaries.map(\.id) == [.cpuPerformance])
        #expect(summaries[0].max == 50)
    }
}
