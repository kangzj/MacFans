import MacFansCore
import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppModel.self) private var model
    @State private var launchAtLoginError: String?

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Picker("Temperature unit", selection: $model.configuration.temperatureUnit) {
                    Text("Celsius").tag(TemperatureUnit.celsius)
                    Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                }
                .pickerStyle(.segmented)
                LabeledContent("Refresh every") {
                    HStack {
                        Slider(value: $model.configuration.pollInterval, in: AppConfiguration.pollIntervalRange, step: 1)
                        Text("\(Int(model.configuration.pollInterval)) s")
                            .monospacedDigit()
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
            Section {
                Picker("Full blast runs for", selection: $model.configuration.boostDuration) {
                    ForEach(AppConfiguration.boostDurationChoices, id: \.self) { duration in
                        Text(Formatters.minutes(duration)).tag(duration)
                    }
                }
                Text("Full Blast runs every fan at maximum speed, then returns to whatever mode was active.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { SMAppService.mainApp.status == .enabled },
                    set: { setLaunchAtLogin($0) }
                ))
                if let launchAtLoginError {
                    Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
                }
                Toggle("Resume last control mode on launch", isOn: $model.configuration.startInModeOnLaunch)
                Text("When off, MacFans always starts in Auto so fans are never forced without you noticing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLoginError = nil
        } catch {
            launchAtLoginError = error.localizedDescription
        }
    }
}
