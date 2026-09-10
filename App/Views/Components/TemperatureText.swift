import MacFansCore
import SwiftUI

enum TemperatureTint {
    static func color(for celsius: Double) -> Color {
        switch celsius {
        case ..<60: .green
        case ..<80: .yellow
        case ..<95: .orange
        default: .red
        }
    }
}

struct TemperatureText: View {
    @Environment(AppModel.self) private var model
    let celsius: Double?
    var style: Font.TextStyle = .body
    var tinted = true

    var body: some View {
        Group {
            if let celsius {
                Text(Formatters.temperature(celsius, unit: model.configuration.temperatureUnit))
                    .foregroundStyle(tinted ? TemperatureTint.color(for: celsius) : .primary)
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.system(style, design: .rounded, weight: .semibold))
        .monospacedDigit()
        .contentTransition(.numericText())
    }
}
