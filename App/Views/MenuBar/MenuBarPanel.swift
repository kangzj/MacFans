import FanwrightCore
import SwiftUI

struct MenuBarPanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            temperatureGrid
            fans
            controls
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Fanwright")
                .font(.title3.weight(.semibold))
            Spacer()
            Label(model.controlStatus.summary, systemImage: model.controller.mode.symbolName)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
    }

    private var temperatureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(SensorFamily.headlineFamilies, id: \.self) { family in
                HStack {
                    Text(family.shortTitle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    TemperatureText(celsius: model.monitor.summary(family)?.max, style: .title3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var fans: some View {
        VStack(spacing: 6) {
            ForEach(model.monitor.fans) { fan in
                HStack {
                    Image(systemName: "fanblades")
                        .foregroundStyle(.secondary)
                    Text(fan.name)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(Formatters.rpm(fan.actualRPM))
                            .font(.body.weight(.medium))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(fan.menuBarDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            ControlModePicker()
            if model.controller.mode == .custom {
                ProfilePicker()
                    .labelsHidden()
            }
            Button {
                model.toggleBoost()
            } label: {
                Label(model.controller.isBoosting ? "Stop Full Blast" : "Full Blast for \(Formatters.minutes(model.configuration.boostDuration))", systemImage: "wind")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!model.helper.isEnabled)
            .help(model.helper.isEnabled ? "Run every fan at maximum speed, then return to the current mode." : "Install the helper in Settings to control fans.")
        }
    }

    private var footer: some View {
        HStack {
            Button("Open Fanwright") {
                openWindow(id: MainWindow.id)
                NSApp.activate()
            }
            Spacer()
            Button("Settings…") {
                openSettings()
                NSApp.activate()
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .buttonStyle(.link)
        .font(.callout)
    }
}
