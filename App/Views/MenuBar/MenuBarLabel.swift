import SwiftUI

struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "fanblades")
            if let readout {
                Text(readout)
                    .monospacedDigit()
            }
        }
    }

    private var readout: String? {
        switch model.monitor.readoutValue(for: model.configuration.menuBarReadout) {
        case .temperature(let celsius): Formatters.temperature(celsius, unit: model.configuration.temperatureUnit)
        case .rpm(let rpm): Formatters.rpm(rpm)
        case nil: nil
        }
    }
}
