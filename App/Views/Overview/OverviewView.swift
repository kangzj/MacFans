import MacFansCore
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if case .unavailable(let message) = model.monitor.availability {
                ContentUnavailableView("Sensors Unavailable", systemImage: "thermometer.medium.slash", description: Text(message))
            } else {
                VStack(spacing: 32) {
                    ThermalHeadline()
                    fanRings
                    ModeSwitch()
                    boostButton
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var fanRings: some View {
        HStack(spacing: 48) {
            ForEach(model.monitor.fans) { fan in
                FanGauge(fan: fan, diameter: 96)
            }
        }
    }

    private var boostButton: some View {
        Button {
            model.toggleBoost()
        } label: {
            Label(model.controller.isBoosting ? "Stop full blast" : "Full blast for 5 minutes", systemImage: "wind")
                .font(.callout)
        }
        .buttonStyle(.borderless)
        .tint(model.controller.isBoosting ? .orange : .secondary)
        .disabled(!model.helper.isEnabled)
        .help("Run every fan at maximum speed for five minutes.")
    }
}

private struct ThermalHeadline: View {
    @Environment(AppModel.self) private var model

    private var headline: Double? {
        let cpu = model.monitor.summary(.cpuPerformance)?.max
        let gpu = model.monitor.summary(.gpu)?.max
        return [cpu, gpu].compactMap { $0 }.max() ?? model.monitor.hottest?.celsius
    }

    var body: some View {
        VStack(spacing: 6) {
            TemperatureText(celsius: headline, style: .largeTitle)
                .font(.system(size: 72, weight: .semibold, design: .rounded))
            Text(headline.map(Self.status) ?? "Reading sensors…")
                .font(.title3.weight(.medium))
            Text(keyReadings)
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var keyReadings: String {
        let unit = model.configuration.temperatureUnit
        let parts: [(String, SensorFamily)] = [("CPU", .cpuPerformance), ("GPU", .gpu), ("SSD", .ssd), ("Battery", .battery)]
        return parts.compactMap { name, family in
            model.monitor.summary(family).map { "\(name) \(Formatters.temperature($0.max, unit: unit))" }
        }.joined(separator: "  ·  ")
    }

    private static func status(for celsius: Double) -> String {
        switch celsius {
        case ..<60: "Running cool"
        case ..<80: "Getting warm"
        case ..<95: "Running hot"
        default: "Very hot"
        }
    }
}

private struct ModeSwitch: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 14) {
            ControlModePicker()
                .controlSize(.large)
                .frame(maxWidth: 360)
            Text(description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            modeDetail
        }
    }

    private var description: String {
        if model.controller.isBoosting, let until = model.controller.boostUntil {
            return "Full blast until \(until.formatted(date: .omitted, time: .shortened)), then back to \(model.controller.mode.title)."
        }
        switch model.controller.mode {
        case .auto: return "macOS manages the fans. MacFans just watches."
        case .constant: return "Fans hold this speed until MacFans quits or the Mac sleeps."
        case .custom: return "Fans follow the “\(model.activeProfile.name)” profile until MacFans quits or the Mac sleeps."
        }
    }

    @ViewBuilder
    private var modeDetail: some View {
        switch model.controller.mode {
        case .auto:
            EmptyView()
        case .constant:
            constantSlider
        case .custom:
            customStatus
        }
    }

    private var constantSlider: some View {
        let fans = model.monitor.fans
        let percent = Binding<Double>(
            get: {
                guard let first = fans.first else { return 50 }
                return (model.configuration.constantSpeeds[first.id] ?? AppConfiguration.defaultConstantSpeed).percent(for: first.limits)
            },
            set: { value in fans.forEach { model.setConstantSpeed(.percent(value), for: $0.id) } }
        )
        return VStack(spacing: 4) {
            Slider(value: percent, in: 0...100, step: 1)
                .frame(maxWidth: 360)
            Text(sliderCaption(percent.wrappedValue))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.top, 4)
    }

    private func sliderCaption(_ percent: Double) -> String {
        let rpms = model.monitor.fans.map { Formatters.rpm(FanSpeed.percent(percent).rpm(for: $0.limits)) }
        return "\(Formatters.percent(percent)) · " + rpms.joined(separator: " / ")
    }

    private var customStatus: some View {
        HStack(spacing: 12) {
            ProfilePicker()
                .labelsHidden()
                .fixedSize()
            Text(ruleStatus)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var ruleStatus: String {
        guard let evaluation = model.controller.lastEvaluation else { return "Evaluating rules…" }
        let active = model.activeProfile.rules.filter { evaluation.state.activeRuleIDs.contains($0.id) }
        if !active.isEmpty { return active.map(\.name).joined(separator: ", ") + (active.count == 1 ? " is active" : " are active") }
        let stillForced = evaluation.commands.values.contains { $0 != .auto }
        return stillForced ? "Rules released, easing back to Auto" : "No rule active, fans on Auto"
    }
}
