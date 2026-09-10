import Charts
import MacFansCore
import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card(title: "Temperature", symbol: "thermometer.medium") { temperatureChart }
                Card(title: "Fan Speed", symbol: "fanblades") { rpmChart }
                Text("MacFans keeps the last 30 minutes in memory while it runs.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
    }

    private var temperatureChart: some View {
        let unit = model.configuration.temperatureUnit
        let points = ChartPoint.points(from: model.monitor.history, series: [("CPU", ReadingHistory.summaryKey(.cpuPerformance)), ("GPU", ReadingHistory.summaryKey(.gpu))]) {
            Formatters.converted($0, to: unit)
        }
        return Chart(points) { point in
            LineMark(x: .value("Time", point.time), y: .value("Temperature", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(["CPU": Color.orange, "GPU": Color.purple])
        .chartYAxisLabel(unit == .celsius ? "°C" : "°F")
        .chartXScale(domain: historyDomain)
        .chartXAxis { timeAxis }
        .frame(height: 220)
    }

    private var rpmChart: some View {
        let series = model.monitor.fans.map { ($0.name, ReadingHistory.fanKey($0.id)) }
        let points = ChartPoint.points(from: model.monitor.history, series: series) { $0 }
        return Chart(points) { point in
            LineMark(x: .value("Time", point.time), y: .value("RPM", point.value))
                .foregroundStyle(by: .value("Fan", point.series))
                .interpolationMethod(.monotone)
        }
        .chartYAxisLabel("RPM")
        .chartXScale(domain: historyDomain)
        .chartXAxis { timeAxis }
        .frame(height: 180)
    }

    private var historyDomain: ClosedRange<Date> {
        let now = model.monitor.lastUpdate ?? Date()
        return now.addingTimeInterval(-ReadingHistory.window)...now
    }

    private var timeAxis: some AxisContent {
        let labelCutoff = historyDomain.upperBound.addingTimeInterval(-90)
        return AxisMarks(values: .stride(by: .minute, count: 5)) { value in
            AxisGridLine()
            if let date = value.as(Date.self), date < labelCutoff {
                AxisValueLabel(format: .dateTime.hour().minute())
            }
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
