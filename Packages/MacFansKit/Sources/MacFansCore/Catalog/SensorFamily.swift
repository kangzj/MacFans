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
