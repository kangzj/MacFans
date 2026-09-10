import MacFansCore
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            MenuBarSettings()
                .tabItem { Label("Menu Bar", systemImage: "menubar.rectangle") }
            HelperSettings()
                .tabItem { Label("Helper", systemImage: "lock.shield") }
            AboutSettings()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 480)
    }
}

private struct GeneralSettings: View {
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

private struct MenuBarSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Picker("Show next to the icon", selection: $model.configuration.menuBarReadout) {
                Text("CPU temperature").tag(MenuBarReadout.cpu)
                ForEach(favorites) { sensor in
                    Text(sensor.name).tag(MenuBarReadout.sensor(sensor.id))
                }
                ForEach(model.monitor.fans) { fan in
                    Text("\(fan.name) speed").tag(MenuBarReadout.fanRPM(fan.id))
                }
                Text("Nothing").tag(MenuBarReadout.none)
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

private struct HelperSettings: View {
    @Environment(AppModel.self) private var model
    @State private var helperVersion: Int?

    var body: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    Label(statusText, systemImage: model.helper.isEnabled ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(model.helper.isEnabled ? .green : .secondary)
                }
                if let helperVersion {
                    LabeledContent("Protocol version", value: "\(helperVersion)")
                }
                if let error = model.helperInstallError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            Section {
                HStack {
                    Button(model.helper.isEnabled ? "Reinstall" : "Install Helper") { model.installHelper() }
                    if model.helper.status == .requiresApproval {
                        Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                    }
                    if model.helper.status != .notRegistered {
                        Button("Remove", role: .destructive) { Task { await model.removeHelper() } }
                    }
                    Spacer()
                    Button("Refresh") { model.helper.refreshStatus() }
                }
                Text("MacFans installs a small root daemon that is the only component allowed to change fan speed. It clamps every request to the fan's hardware range and returns fans to Auto if the app stops responding for 10 seconds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task(id: model.helper.status) {
            helperVersion = model.helper.isEnabled ? try? await model.helper.version() : nil
        }
    }

    private var statusText: String {
        switch model.helper.status {
        case .enabled: "Installed and approved"
        case .requiresApproval: "Waiting for approval in Login Items"
        case .notRegistered: "Not installed"
        case .notFound: "Helper missing from the app bundle"
        }
    }
}

private struct AboutSettings: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
            Text("MacFans")
                .font(.title2.weight(.semibold))
            Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                .foregroundStyle(.secondary)
            Text("Sensor readings come straight from the System Management Controller. Fan control uses Apple's own fan target keys, the same mechanism macOS uses.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding(24)
    }
}
