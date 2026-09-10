import Foundation

struct ChartPoint: Identifiable {
    let series: String
    let time: Date
    let value: Double

    var id: String { "\(series)-\(time.timeIntervalSinceReferenceDate)" }

    @MainActor
    static func points(from history: ReadingHistory, series: [(name: String, key: HistoryKey)], transform: (Double) -> Double) -> [ChartPoint] {
        series.flatMap { name, key in
            history.samples(key).map { ChartPoint(series: name, time: $0.time, value: transform($0.value)) }
        }
    }
}
