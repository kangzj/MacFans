enum SidebarItem: String, CaseIterable, Identifiable {
    case overview, fans, sensors, profiles, history

    var id: SidebarItem { self }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .fans: "Fans"
        case .sensors: "Sensors"
        case .profiles: "Profiles"
        case .history: "History"
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "gauge.with.dots.needle.33percent"
        case .fans: "fanblades"
        case .sensors: "thermometer.medium"
        case .profiles: "slider.horizontal.3"
        case .history: "clock.arrow.circlepath"
        }
    }
}
