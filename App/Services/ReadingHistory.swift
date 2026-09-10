import Foundation
import MacFansCore
import Observation

struct HistorySample: Identifiable, Sendable {
    let id: Date
    let value: Double
}

@MainActor
@Observable
final class ReadingHistory {
    static let window: TimeInterval = 30 * 60

    private(set) var series: [String: [HistorySample]] = [:]

    func append(_ values: [String: Double], at date: Date) {
        let cutoff = date.addingTimeInterval(-Self.window)
        for (key, value) in values {
            var samples = series[key, default: []]
            samples.append(HistorySample(id: date, value: value))
            if let first = samples.first, first.id < cutoff {
                samples.removeAll { $0.id < cutoff }
            }
            series[key] = samples
        }
    }

    func samples(_ key: String) -> [HistorySample] {
        series[key] ?? []
    }

    static func fanKey(_ id: FanID) -> String { "fan:\(id.rawValue)" }
    static func summaryKey(_ family: SensorFamily) -> String { "summary:\(family.rawValue)" }
}
