import MacFansCore
import SwiftUI

struct TemperatureText: View {
    @Environment(AppModel.self) private var model
    let celsius: Double?
    let style: Font.TextStyle

    var body: some View {
        Group {
            if let celsius {
                Text(Formatters.temperature(celsius, unit: model.configuration.temperatureUnit))
                    .foregroundStyle(ThermalLevel(celsius: celsius).color)
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
