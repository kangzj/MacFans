import MacFansCore
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            if case .unavailable(let message) = model.monitor.availability {
                ContentUnavailableView("Sensors Unavailable", systemImage: "thermometer.medium.slash", description: Text(message))
            } else {
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 16) {
                        ThermalCard()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        FansCard()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    ModeCard()
                }
                .padding(20)
            }
        }
    }
}

private struct ThermalCard: View {
    @Environment(AppModel.self) private var model

    private let readings: [(title: String, family: SensorFamily, symbol: String)] = [
        ("CPU", .cpuPerformance, "cpu"),
        ("GPU", .gpu, "rectangle.3.group"),
        ("SSD", .ssd, "internaldrive"),
        ("Battery", .battery, "battery.100percent"),
    ]

    private var headline: Double? {
        [model.monitor.summary(.cpuPerformance)?.max, model.monitor.summary(.gpu)?.max].compactMap { $0 }.max()
            ?? model.monitor.hottest?.celsius
    }

    var body: some View {
        Card(title: "Temperature", symbol: "thermometer.medium") {
            HStack(spacing: 28) {
                TemperatureRing(celsius: headline)
                VStack(spacing: 10) {
                    ForEach(readings, id: \.family) { title, family, symbol in
                        readingRow(title: title, symbol: symbol, celsius: model.monitor.summary(family)?.max)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            Spacer(minLength: 0)
            TrendStrip(
                title: "CPU · last 30 min",
                samples: model.monitor.history.samples(ReadingHistory.summaryKey(.cpuPerformance)),
                tint: TemperatureTint.color(for: headline ?? 0)
            )
        }
    }

    private func readingRow(title: String, symbol: String, celsius: Double?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(title)
                .font(.callout)
            Spacer()
            TemperatureText(celsius: celsius, style: .title3)
        }
    }
}

private struct FansCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Card(title: "Fans", symbol: "fanblades") {
            HStack(spacing: 24) {
                ForEach(model.monitor.fans) { fan in
                    FanGauge(fan: fan, diameter: 118)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            Spacer(minLength: 0)
            if let first = model.monitor.fans.first {
                TrendStrip(
                    title: "\(first.name) · last 30 min",
                    samples: model.monitor.history.samples(ReadingHistory.fanKey(first.id)),
                    tint: .blue
                )
            }
        }
    }
}

private struct ModeCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Fan Control", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    boostButton
                }
                HStack(spacing: 12) {
                    ForEach(ControlMode.allCases, id: \.self) { mode in
                        ModeTile(mode: mode, isSelected: model.controller.mode == mode) { model.setMode(mode) }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                detail
            }
        }
    }

    private var boostButton: some View {
        Button {
            model.toggleBoost()
        } label: {
            Label(model.controller.isBoosting ? "Stop Full Blast" : "Full Blast · 5 min", systemImage: "wind")
        }
        .controlSize(.small)
        .tint(model.controller.isBoosting ? .orange : nil)
        .disabled(!model.helper.isEnabled)
        .help("Run every fan at maximum speed for five minutes.")
    }

    @ViewBuilder
    private var detail: some View {
        HStack(spacing: 16) {
            switch model.controller.mode {
            case .auto:
                Text(statusLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            case .constant:
                constantSlider
            case .custom:
                ProfilePicker()
                    .labelsHidden()
                    .fixedSize()
                Text(statusLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 32)
    }

    private var statusLine: String {
        if model.controller.isBoosting, let until = model.controller.boostUntil {
            return "Full blast until \(until.formatted(date: .omitted, time: .shortened))."
        }
        switch model.controller.mode {
        case .auto:
            return "macOS is managing the fans. Auto is also where MacFans returns whenever it quits or the Mac sleeps."
        case .constant:
            return ""
        case .custom:
            guard let evaluation = model.controller.lastEvaluation else { return "Evaluating rules…" }
            let active = model.activeProfile.rules.filter { evaluation.state.activeRuleIDs.contains($0.id) }
            if !active.isEmpty { return active.map(\.name).joined(separator: ", ") + (active.count == 1 ? " is active." : " are active.") }
            let stillForced = evaluation.commands.values.contains { $0 != .auto }
            return stillForced ? "Rules released, easing back to Auto." : "No rule active. Fans are on Auto until one triggers."
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
        return HStack(spacing: 14) {
            Image(systemName: "fanblades")
                .foregroundStyle(.secondary)
            Slider(value: percent, in: 0...100, step: 1)
                .frame(maxWidth: 420)
            Text(sliderCaption(percent.wrappedValue))
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func sliderCaption(_ percent: Double) -> String {
        let rpms = model.monitor.fans.map { Formatters.rpm(FanSpeed.percent(percent).rpm(for: $0.limits)) }
        return "\(Formatters.percent(percent)) · " + rpms.joined(separator: " / ")
    }
}

private struct TrendStrip: View {
    let title: String
    let samples: [HistorySample]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Sparkline(samples: samples, tint: tint)
                .frame(height: 34)
        }
    }
}
