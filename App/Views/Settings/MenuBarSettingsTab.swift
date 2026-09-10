import FanwrightCore
import SwiftUI

struct MenuBarSettingsTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Show next to the icon", selection: $model.configuration.menuBarReadout) {
                Section("Temperatures") {
                    ForEach(model.monitor.summaries) { summary in
                        Text(summary.title).tag(MenuBarReadout.family(summary.family))
                    }
                    Text("Hottest sensor").tag(MenuBarReadout.hottest)
                }
                if !favorites.isEmpty {
                    Section("Favourite sensors") {
                        ForEach(favorites) { sensor in
                            Text(sensor.name).tag(MenuBarReadout.sensor(sensor.id))
                        }
                    }
                }
                Section("Fans") {
                    ForEach(model.monitor.fans) { fan in
                        Text("\(fan.name) speed").tag(MenuBarReadout.fanRPM(fan.id))
                    }
                }
                Section {
                    Text("Nothing").tag(MenuBarReadout.none)
                }
            }
            Text("Star sensors in the Sensors tab to offer them here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var favorites: [Sensor] {
        model.monitor.sensorsWithReadings.filter(\.isFavorite)
    }
}
