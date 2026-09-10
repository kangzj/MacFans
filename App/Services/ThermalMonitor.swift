import Foundation
import MacFansCore
import Observation
import SMCKit

enum MenuBarReadoutValue: Equatable {
    case temperature(Double)
    case rpm(Double)
}

@MainActor
@Observable
final class ThermalMonitor {
    enum Availability: Equatable {
        case starting
        case available
        case unavailable(String)
    }

    private(set) var availability: Availability = .starting
    private(set) var sensors: [Sensor] = []
    private(set) var readings: [SensorID: Double] = [:]
    private(set) var summaries: [SensorSummary] = []
    private(set) var fans: [FanState] = []
    private(set) var lastUpdate: Date?
    let history = ReadingHistory()

    private var reader: SMCReader?
    private var keys: [String] = []
    private var overrides: [SensorID: SensorOverride] = [:]

    var sensorsWithReadings: [Sensor] {
        sensors.filter { readings[$0.id] != nil }
    }

    var hottest: (sensor: Sensor, celsius: Double)? {
        sensorsWithReadings
            .compactMap { sensor in readings[sensor.id].map { (sensor, $0) } }
            .max { $0.1 < $1.1 }
    }

    var sensorReadings: [SensorReading] {
        readings.map { SensorReading(id: $0.key, celsius: $0.value) }
    }

    var fanLimits: [FanLimits] { fans.map(\.limits) }

    func summary(_ family: SensorFamily) -> SensorSummary? {
        summaries.first { $0.family == family }
    }

    func value(for group: SensorGroup, _ aggregate: Aggregate) -> Double? {
        RuleEngine.triggerValue(.group(group, aggregate), readings: sensorReadings, sensors: sensors)
    }

    func readoutValue(for readout: MenuBarReadout) -> MenuBarReadoutValue? {
        switch readout {
        case .family(let family): summary(family).map { .temperature($0.max) }
        case .hottest: hottest.map { .temperature($0.celsius) }
        case .sensor(let id): readings[id].map { .temperature($0) }
        case .fanRPM(let id): fans.first { $0.id == id }.map { .rpm($0.actualRPM) }
        case .none: nil
        }
    }

    func applyOverrides(_ overrides: [SensorID: SensorOverride]) {
        self.overrides = overrides
        sensors = SensorCatalog.sensors(for: keys, overrides: overrides)
    }

    func refresh() async {
        if reader == nil {
            do {
                let reader = try SMCReader()
                self.reader = reader
                keys = await reader.temperatureKeys.map(\.string)
                sensors = SensorCatalog.sensors(for: keys, overrides: overrides)
            } catch {
                availability = .unavailable("This Mac does not expose an SMC that MacFans can read (\(error.localizedDescription)).")
                return
            }
        }
        guard let reader else { return }
        do {
            let snapshot = try await reader.snapshot()
            publish(snapshot, at: Date())
            availability = .available
        } catch {
            availability = .unavailable("Reading sensors failed: \(error.localizedDescription)")
        }
    }

    private func publish(_ snapshot: SMCSnapshot, at date: Date) {
        var plausible: [SensorID: Double] = [:]
        for (key, celsius) in snapshot.temperatures where SensorCatalog.isPlausible(celsius: celsius) {
            plausible[SensorID(rawValue: key.string)] = celsius
        }
        readings = plausible
        summaries = SensorCatalog.summaries(sensors: sensors, readings: plausible)
        fans = snapshot.fans.map { reading in
            FanState(
                id: FanID(rawValue: reading.index),
                name: FanState.defaultName(index: reading.index, count: snapshot.fans.count),
                limits: FanLimits(id: FanID(rawValue: reading.index), minRPM: reading.minRPM, maxRPM: reading.maxRPM),
                actualRPM: reading.actualRPM,
                targetRPM: reading.targetRPM,
                isForced: reading.isForced
            )
        }
        lastUpdate = date

        var samples: [HistoryKey: Double] = [:]
        for (id, celsius) in plausible { samples[.sensor(id)] = celsius }
        for summary in summaries { samples[.summary(summary.family)] = summary.max }
        for fan in fans { samples[.fan(fan.id)] = fan.actualRPM }
        history.append(samples, at: date)
    }
}
