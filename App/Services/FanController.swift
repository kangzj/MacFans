import Foundation
import FanwrightCore
import Observation

@MainActor
@Observable
final class FanController {
    static let heartbeatInterval: Duration = .seconds(2)

    private(set) var mode: ControlMode = .auto
    private(set) var engineState = RuleEngineState()
    private(set) var lastEvaluation: RuleEvaluation?
    private(set) var boostEndsAt: Date?
    private(set) var lastError: String?
    private var sentCommands: [FanID: FanCommand] = [:]
    private var generation = 0
    private var heartbeatTask: Task<Void, Never>?
    private let sink: any FanCommandSink

    init(sink: any FanCommandSink) {
        self.sink = sink
        startHeartbeat()
    }

    var isBoosting: Bool {
        boostEndsAt.map { $0 > Date() } ?? false
    }

    var isManual: Bool { mode != .auto || isBoosting }

    func setMode(_ mode: ControlMode) {
        guard mode != self.mode else { return }
        self.mode = mode
        lastError = nil
        invalidate()
    }

    func resetEngine() {
        engineState = RuleEngineState()
        lastEvaluation = nil
    }

    func boost(for duration: TimeInterval) {
        boostEndsAt = Date().addingTimeInterval(duration)
        lastError = nil
        invalidate()
    }

    func cancelBoost() {
        boostEndsAt = nil
        invalidate()
    }

    func clearError() {
        lastError = nil
    }

    func tick(monitor: ThermalMonitor, configuration: AppConfiguration) async {
        guard monitor.availability == .available, !monitor.fans.isEmpty else { return }
        if let boostEndsAt, boostEndsAt <= Date() { self.boostEndsAt = nil }

        let startGeneration = generation
        let evaluation = ControlPlanner.plan(
            mode: mode,
            isBoosting: isBoosting,
            constantSpeeds: configuration.constantSpeeds,
            profile: configuration.profile(id: configuration.activeProfileID) ?? .balanced,
            readings: monitor.sensorReadings,
            sensors: monitor.sensors,
            fans: monitor.fanLimits,
            previous: engineState,
            now: Date()
        )
        if mode == .custom {
            engineState = evaluation.state
            lastEvaluation = evaluation
        }
        let wantsControl = evaluation.commands.values.contains { $0 != .auto }
        guard sink.isEnabled else {
            if wantsControl { fail("Install the fan control helper in Settings to control fans.") }
            return
        }

        do {
            for (fan, command) in evaluation.commands.sorted(by: { $0.key.rawValue < $1.key.rawValue }) where sentCommands[fan] != command {
                switch command {
                case .auto: try await sink.setAuto(index: fan.rawValue)
                case .forced(let rpm): try await sink.setFan(index: fan.rawValue, rpm: rpm)
                }
                guard generation == startGeneration else { return }
                sentCommands[fan] = command
            }
        } catch {
            guard generation == startGeneration else { return }
            fail(error.localizedDescription)
        }
    }

    func restoreAuto() async {
        boostEndsAt = nil
        mode = .auto
        invalidate()
        guard sink.isEnabled else { return }
        do {
            try await sink.setAllAuto()
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func startHeartbeat() {
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.heartbeatInterval)
                await self?.heartbeat()
            }
        }
    }

    private func heartbeat() async {
        guard sink.isEnabled else { return }
        let startGeneration = generation
        guard let sinkHasForcedFans = try? await sink.heartbeat(), generation == startGeneration else { return }
        let sentForced = sentCommands.values.contains { $0 != .auto }
        if sinkHasForcedFans != sentForced {
            // The helper restarted or its watchdog fired; forget what was sent so the next tick resyncs.
            sentCommands = [:]
            if !sentForced { try? await sink.setAllAuto() }
        }
    }

    private func invalidate() {
        generation += 1
        resetEngine()
        sentCommands = [:]
    }

    private func fail(_ message: String) {
        lastError = message
        mode = .auto
        boostEndsAt = nil
        invalidate()
    }
}
