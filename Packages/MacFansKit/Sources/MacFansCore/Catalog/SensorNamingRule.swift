struct SensorNamingRule: Sendable {
    enum Pattern: Sendable {
        case exact(String)
        case prefix(String)

        func matches(_ key: String) -> Bool {
            switch self {
            case .exact(let exact): key == exact
            case .prefix(let prefix): key.hasPrefix(prefix)
            }
        }
    }

    enum Label: Sendable {
        case fixed(String)
        case series(String)
        case gpuCluster

        func name(for key: String, numbering: inout SeriesNumbering) -> String {
            switch self {
            case .fixed(let name):
                return name
            case .series(let series):
                return "\(series) \(numbering.next(in: series))"
            case .gpuCluster:
                let series = "GPU Cluster \(key.dropFirst(2).prefix(1)) Sensor"
                return "\(series) \(numbering.next(in: series))"
            }
        }
    }

    struct SeriesNumbering {
        private var counts: [String: Int] = [:]

        mutating func next(in series: String) -> Int {
            let next = counts[series, default: 0] + 1
            counts[series] = next
            return next
        }
    }

    let pattern: Pattern
    let group: SensorGroup
    let label: Label
    let family: SensorFamily?
    let representsFamily: Bool

    static func rules(for keys: some Sequence<String>) -> [SensorNamingRule] {
        keys.contains { $0.hasPrefix("Tp0") } ? common : common + appleSiliconM3M4Cores
    }

    func matches(_ key: String) -> Bool {
        pattern.matches(key)
    }

    private static func exact(_ key: String, _ group: SensorGroup, _ name: String, family: SensorFamily? = nil, representsFamily: Bool = false) -> SensorNamingRule {
        SensorNamingRule(pattern: .exact(key), group: group, label: .fixed(name), family: family, representsFamily: representsFamily)
    }

    private static func prefix(_ prefix: String, _ group: SensorGroup, _ label: Label, family: SensorFamily? = nil) -> SensorNamingRule {
        SensorNamingRule(pattern: .prefix(prefix), group: group, label: label, family: family, representsFamily: false)
    }

    private static let common: [SensorNamingRule] = [
        .exact("TW0P", .ambient, "Wi-Fi Module", family: .wifi),
        .exact("TCMb", .soc, "SoC Package", family: .soc, representsFamily: true),
        .exact("TCDX", .soc, "SoC Die", family: .soc),
        .exact("TCHP", .power, "Charger"),
        .exact("TAOL", .ambient, "Ambient", family: .ambient),
        .exact("TS0P", .ambient, "Palm Rest Left", family: .ambient),
        .exact("Ts1P", .ambient, "Palm Rest Right", family: .ambient),
        .prefix("TB", .battery, .series("Battery"), family: .battery),
        .prefix("TH0", .storage, .series("SSD"), family: .ssd),
        .prefix("TH1", .storage, .series("SSD"), family: .ssd),
        .prefix("Tp0", .cpu, .series("CPU Performance Core"), family: .cpuPerformance),
        .prefix("Tp1", .cpu, .series("CPU Efficiency Core"), family: .cpuEfficiency),
        .prefix("TfC", .soc, .series("SoC Sensor"), family: .soc),
        .prefix("Tg", .gpu, .gpuCluster, family: .gpu),
        .prefix("Tm", .memory, .series("Memory"), family: .memory),
        .prefix("Ts0", .soc, .series("SoC Sensor"), family: .soc),
        .prefix("Ta0", .soc, .series("Neural Engine"), family: .soc),
        .prefix("TaL", .ambient, .series("Airflow Left"), family: .ambient),
        .prefix("TaR", .ambient, .series("Airflow Right"), family: .ambient),
        .prefix("TV", .power, .series("Power Rail")),
        .prefix("TD", .display, .series("Display")),
    ]

    // M3 and M4 report cores under Tf/Te; M5 reuses Tp and leaves Tf keys holding fixed non-temperature values.
    private static let appleSiliconM3M4Cores: [SensorNamingRule] = [
        .prefix("Te0", .cpu, .series("CPU Efficiency Core"), family: .cpuEfficiency),
        .prefix("Tf0", .cpu, .series("CPU Performance Core"), family: .cpuPerformance),
        .prefix("Tf4", .cpu, .series("CPU Performance Core"), family: .cpuPerformance),
        .prefix("Tf1", .gpu, .series("GPU Sensor"), family: .gpu),
        .prefix("Tf2", .gpu, .series("GPU Sensor"), family: .gpu),
    ]
}
