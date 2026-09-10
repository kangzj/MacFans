import Charts
import MacFansCore
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model

    private let heroes = [("cpu-performance", "CPU", "cpu"), ("gpu", "GPU", "rectangle.3.group"), ("memory", "Memory", "memorychip"), ("ssd", "SSD", "internaldrive"), ("battery", "Battery", "battery.100percent")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if case .unavailable(let message) = model.monitor.availability {
                    ContentUnavailableView("Sensors Unavailable", systemImage: "thermometer.medium.slash", description: Text(message))
                } else {
                    heroRow
                    fanRow
                    historyCard
                }
            }
            .padding(20)
        }
    }

    private var heroRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: heroes.count), spacing: 12) {
            ForEach(heroes, id: \.0) { id, title, symbol in
                let summary = model.monitor.summary(id)
                Card(title: title, symbol: symbol) {
                    TemperatureText(celsius: summary?.max, style: .largeTitle)
                    Text(caption(for: summary))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private func caption(for summary: SensorSummary?) -> String {
        guard let summary else { return "No reading" }
        let unit = model.configuration.temperatureUnit
        if summary.sensorIDs.count == 1 { return "1 sensor" }
        return "Avg \(Formatters.temperature(summary.average, unit: unit)) · \(summary.sensorIDs.count) sensors"
    }

    private var fanRow: some View {
        Card(title: "Fans", symbol: "fanblades") {
            HStack(alignment: .top, spacing: 24) {
                ForEach(model.monitor.fans) { fan in
                    FanGauge(fan: fan)
                        .frame(maxWidth: .infinity)
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Label(model.controller.mode.title, systemImage: model.controller.mode.symbolName)
                        .font(.headline)
                    Text(modeDescription)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if model.controller.mode == .custom, let evaluation = model.controller.lastEvaluation {
                        activeRules(evaluation)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var modeDescription: String {
        switch model.controller.mode {
        case .auto: "macOS is managing fan speed. MacFans only observes."
        case .constant: "Fans hold the speeds set in the Fans tab."
        case .custom: "Fans follow the “\(model.activeProfile.name)” profile."
        }
    }

    private func activeRules(_ evaluation: RuleEvaluation) -> some View {
        let active = model.activeProfile.rules.filter { evaluation.state.activeRuleIDs.contains($0.id) }
        return Group {
            if active.isEmpty {
                Text("No rule is active. Fans are on Auto.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(active) { rule in
                    Label(rule.name, systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var historyCard: some View {
        Card(title: "Last 30 Minutes", symbol: "clock") {
            VStack(spacing: 16) {
                temperatureChart
                rpmChart
            }
        }
    }

    private var temperatureChart: some View {
        let unit = model.configuration.temperatureUnit
        let points = ChartPoint.points(from: model.monitor.history, series: [("CPU", "cpu-performance"), ("GPU", "gpu")]) {
            Formatters.converted($0, to: unit)
        }
        return Chart(points) { point in
            LineMark(x: .value("Time", point.time), y: .value("Temperature", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(["CPU": Color.orange, "GPU": Color.purple])
        .chartYAxisLabel(unit == .celsius ? "°C" : "°F")
        .chartXAxis { timeAxis }
        .frame(height: 160)
    }

    private var rpmChart: some View {
        let series = model.monitor.fans.map { ($0.name, ReadingHistory.fanKey($0.id.rawValue)) }
        let points = ChartPoint.points(from: model.monitor.history, series: series) { $0 }
        return Chart(points) { point in
            LineMark(x: .value("Time", point.time), y: .value("RPM", point.value))
                .foregroundStyle(by: .value("Fan", point.series))
                .interpolationMethod(.monotone)
        }
        .chartYAxisLabel("RPM")
        .chartXAxis { timeAxis }
        .frame(height: 120)
    }

    private var timeAxis: some AxisContent {
        AxisMarks(values: .automatic(desiredCount: 6)) { _ in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.hour().minute())
        }
    }
}

private struct ChartPoint: Identifiable {
    let series: String
    let time: Date
    let value: Double

    var id: String { "\(series)-\(time.timeIntervalSinceReferenceDate)" }

    @MainActor
    static func points(from history: ReadingHistory, series: [(name: String, key: String)], transform: (Double) -> Double) -> [ChartPoint] {
        series.flatMap { name, key in
            history.samples(key).map { ChartPoint(series: name, time: $0.id, value: transform($0.value)) }
        }
    }
}
