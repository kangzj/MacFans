public enum SensorFamily: String, CaseIterable, Codable, Sendable {
    case cpuPerformance = "cpu-performance"
    case cpuEfficiency = "cpu-efficiency"
    case gpu
    case soc
    case memory
    case ssd
    case battery
    case wifi
    case ambient

    public var title: String {
        switch self {
        case .cpuPerformance: "CPU Performance Cores"
        case .cpuEfficiency: "CPU Efficiency Cores"
        case .gpu: "GPU"
        case .soc: "SoC Package"
        case .memory: "Memory"
        case .ssd: "SSD"
        case .battery: "Battery"
        case .wifi: "Wi-Fi"
        case .ambient: "Ambient"
        }
    }

    public static let headlineFamilies: [SensorFamily] = [.cpuPerformance, .gpu, .ssd, .battery]

    public var shortTitle: String {
        switch self {
        case .cpuPerformance: "CPU"
        case .cpuEfficiency: "E-cores"
        default: title
        }
    }

    public var symbolName: String {
        switch self {
        case .cpuPerformance, .cpuEfficiency: "cpu"
        case .gpu: "rectangle.3.group"
        case .soc: "memorychip"
        case .memory: "memorychip.fill"
        case .ssd: "internaldrive"
        case .battery: "battery.100percent"
        case .wifi: "wifi"
        case .ambient: "wind"
        }
    }

    public var group: SensorGroup {
        switch self {
        case .cpuPerformance, .cpuEfficiency: .cpu
        case .gpu: .gpu
        case .soc: .soc
        case .memory: .memory
        case .ssd: .storage
        case .battery: .battery
        case .wifi, .ambient: .ambient
        }
    }
}
