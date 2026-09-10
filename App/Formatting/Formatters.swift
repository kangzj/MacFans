import Foundation
import FanwrightCore

enum Formatters {
    private static let rpmFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func temperature(_ celsius: Double, unit: TemperatureUnit) -> String {
        "\(Int(unit.convert(celsius: celsius).rounded()))°"
    }

    static func rpm(_ value: Double) -> String {
        rpmValue(value) + " RPM"
    }

    static func rpmValue(_ value: Double) -> String {
        rpmFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func minutes(_ seconds: TimeInterval) -> String {
        let minutes = Int((seconds / 60).rounded())
        return minutes == 1 ? "1 min" : "\(minutes) min"
    }
}
