public enum SensorGroup: String, CaseIterable, Codable, Hashable, Sendable {
    case cpu, gpu, soc, memory, storage, battery, power, display, ambient, other

    public var title: String {
        switch self {
        case .cpu: "CPU"
        case .gpu: "GPU"
        case .soc: "SoC"
        case .memory: "Memory"
        case .storage: "Storage"
        case .battery: "Battery"
        case .power: "Power"
        case .display: "Display"
        case .ambient: "Ambient"
        case .other: "Other"
        }
    }

    public var symbolName: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "rectangle.3.group"
        case .soc: "memorychip"
        case .memory: "memorychip.fill"
        case .storage: "internaldrive"
        case .battery: "battery.100percent"
        case .power: "bolt"
        case .display: "display"
        case .ambient: "wind"
        case .other: "thermometer.medium"
        }
    }
}
