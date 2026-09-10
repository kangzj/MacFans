import FanwrightCore

extension ControlMode {
    var title: String {
        switch self {
        case .auto: "Auto"
        case .constant: "Constant"
        case .custom: "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .auto: "wand.and.sparkles"
        case .constant: "dial.medium"
        case .custom: "slider.horizontal.3"
        }
    }
}
