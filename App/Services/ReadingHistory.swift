import Foundation
import FanwrightCore
import Observation

enum HistoryKey: Hashable {
    case sensor(SensorID)
    case summary(SensorFamily)
    case fan(FanID)
}

struct HistorySample: Identifiable, Sendable {
    let time: Date
    let value: Double

    var id: Date { time }
}

@MainActor
@Observable
final class ReadingHistory {
    static let window: TimeInterval = 30 * 60

    private(set) var series: [HistoryKey: [HistorySample]] = [:]

    func append(_ values: [HistoryKey: Double], at date: Date) {
        let cutoff = date.addingTimeInterval(-Self.window)
        for (key, value) in values {
            var samples = series[key, default: []]
            samples.append(HistorySample(time: date, value: value))
            if let first = samples.first, first.time < cutoff {
                samples.removeAll { $0.time < cutoff }
            }
            series[key] = samples
        }
    }

    func samples(_ key: HistoryKey) -> [HistorySample] {
        series[key] ?? []
    }
}
