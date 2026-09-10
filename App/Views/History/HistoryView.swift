import Charts
import FanwrightCore
import SwiftUI

struct HistoryView: View {
    private static let axisLabelCutoff: TimeInterval = 90

    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card(title: "Temperature", symbol: "thermometer.medium") { temperatureChart }
                Card(title: "Fan Speed", symbol: "fanblades") { rpmChart }
                Text("Fanwright keeps the last 30 minutes in memory while it runs.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(20)
        }
    }

    private var temperatureChart: some View {
        let unit = model.configuration.temperatureUnit
        let points = ChartPoint.points(from: model.monitor.history, series: [("CPU", .summary(.cpuPerformance)), ("GPU", .summary(.gpu))]) {
            unit.convert(celsius: $0)
        }
        return Chart(points) { point in
            LineMark(x: .value("Time", point.time), y: .value("Temperature", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(.monotone)
        }
        .chartForegroundStyleScale(["CPU": Color.orange, "GPU": Color.purple])
        .chartYAxisLabel(unit.symbol)
        .chartXScale(domain: historyDomain)
        .chartXAxis { timeAxis }
        .frame(height: 220)
    }

    private var rpmChart: some View {
        let series = model.monitor.fans.map { ($0.name, HistoryKey.fan($0.id)) }
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
        let labelCutoff = historyDomain.upperBound.addingTimeInterval(-Self.axisLabelCutoff)
        return AxisMarks(values: .stride(by: .minute, count: 5)) { value in
            AxisGridLine()
            if let date = value.as(Date.self), date < labelCutoff {
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
    }
}
