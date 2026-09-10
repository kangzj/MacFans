import MacFansCore
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if case .unavailable(let message) = model.monitor.availability {
            ContentUnavailableView("Sensors Unavailable", systemImage: "thermometer.medium.slash", description: Text(message))
        } else {
            HStack(alignment: .top, spacing: 16) {
                ThermalCard()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                FansCard()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
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
            HStack(spacing: 24) {
                TemperatureRing(celsius: headline, diameter: 150)
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
                    FanGauge(fan: fan, diameter: 112)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            modeDetail
                .frame(maxWidth: .infinity)
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

    @ViewBuilder
    private var modeDetail: some View {
        switch model.controller.mode {
        case .auto:
            statusText(model.controller.isBoosting ? boostText : "Auto · managed by macOS.")
        case .constant:
            constantSlider
        case .custom:
            statusText(model.controller.isBoosting ? boostText : ruleStatus)
        }
    }

    private func statusText(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .multilineTextAlignment(.center)
            .frame(minHeight: 22)
    }

    private var boostText: String {
        "Full blast until \(model.controller.boostUntil?.formatted(date: .omitted, time: .shortened) ?? "")."
    }

    private var ruleStatus: String {
        guard let evaluation = model.controller.lastEvaluation else { return "Evaluating “\(model.activeProfile.name)”…" }
        let active = model.activeProfile.rules.filter { evaluation.state.activeRuleIDs.contains($0.id) }
        if !active.isEmpty { return active.map(\.name).joined(separator: ", ") + (active.count == 1 ? " is active." : " are active.") }
        let stillForced = evaluation.commands.values.contains { $0 != .auto }
        return stillForced ? "Rules released, easing back to Auto." : "Custom · “\(model.activeProfile.name)”, no rule active."
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
        return HStack(spacing: 10) {
            Slider(value: percent, in: 0...100, step: 1)
            Text(Formatters.percent(percent.wrappedValue))
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .frame(minHeight: 22)
    }
}

private struct TrendStrip: View {
    let title: String
    let samples: [HistorySample]
    let tint: Color
    @AppStorage("showOverviewTrends") private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    Text(title)
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help(isExpanded ? "Hide the last 30 minutes" : "Show the last 30 minutes")
            if isExpanded {
                Sparkline(samples: samples, tint: tint)
                    .frame(height: 34)
            }
        }
    }
}
