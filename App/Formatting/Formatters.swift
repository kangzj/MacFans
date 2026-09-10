import Foundation
import MacFansCore

enum Formatters {
    private static let rpmFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func temperature(_ celsius: Double, unit: TemperatureUnit) -> String {
        "\(Int(converted(celsius, to: unit).rounded()))°"
    }

    static func temperatureWithUnit(_ celsius: Double, unit: TemperatureUnit) -> String {
        temperature(celsius, unit: unit) + (unit == .celsius ? "C" : "F")
    }

    static func rpm(_ value: Double) -> String {
        (rpmFormatter.string(from: NSNumber(value: value)) ?? "\(Int(value))") + " RPM"
    }

    static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    static func converted(_ celsius: Double, to unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: celsius
        case .fahrenheit: celsius * 9 / 5 + 32
        }
    }

    static func celsius(_ value: Double, from unit: TemperatureUnit) -> Double {
        switch unit {
        case .celsius: value
        case .fahrenheit: (value - 32) * 5 / 9
        }
    }
}
