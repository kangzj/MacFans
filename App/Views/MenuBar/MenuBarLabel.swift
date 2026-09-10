import MacFansCore
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
        let unit = model.configuration.temperatureUnit
        switch model.configuration.menuBarReadout {
        case .cpu:
            return (model.monitor.summary(.cpuPerformance)?.max ?? model.monitor.hottest?.celsius)
                .map { Formatters.temperature($0, unit: unit) }
        case .sensor(let id):
            return model.monitor.readings[id].map { Formatters.temperature($0, unit: unit) }
        case .fanRPM(let id):
            return model.monitor.fans.first { $0.id == id }.map { Formatters.rpm($0.actualRPM) }
        case .none:
            return nil
        }
    }
}
