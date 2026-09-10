import Foundation
import MacFansCore
import Observation

@MainActor
@Observable
final class FanController {
    static let heartbeatInterval: Duration = .seconds(2)

    private(set) var mode: ControlMode = .auto
    private(set) var engineState = RuleEngineState()
    private(set) var lastEvaluation: RuleEvaluation?
    private(set) var boostUntil: Date?
    private(set) var lastError: String?
    private var sentCommands: [FanID: FanCommand] = [:]
    private var generation = 0
    private var heartbeatTask: Task<Void, Never>?
    private let helper: HelperClient

    init(helper: HelperClient) {
        self.helper = helper
        startHeartbeat()
    }

    var isBoosting: Bool {
        boostUntil.map { $0 > Date() } ?? false
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
        boostUntil = Date().addingTimeInterval(duration)
        lastError = nil
        invalidate()
    }

    func cancelBoost() {
        boostUntil = nil
        invalidate()
    }

    func clearError() {
        lastError = nil
    }

    func tick(monitor: ThermalMonitor, configuration: AppConfiguration) async {
        guard monitor.availability == .available, !monitor.fans.isEmpty else { return }
        if let boostUntil, boostUntil <= Date() { self.boostUntil = nil }

        let startGeneration = generation
        let desired = desiredCommands(monitor: monitor, configuration: configuration)
        let wantsControl = desired.values.contains { $0 != .auto }
        guard helper.isEnabled else {
            if wantsControl { fail("Install the fan control helper in Settings to control fans.") }
            return
        }

        do {
            for (fan, command) in desired.sorted(by: { $0.key.rawValue < $1.key.rawValue }) where sentCommands[fan] != command {
                switch command {
                case .auto: try await helper.setAuto(index: fan.rawValue)
                case .forced(let rpm): try await helper.setFan(index: fan.rawValue, rpm: rpm)
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
        boostUntil = nil
        mode = .auto
        invalidate()
        guard helper.isEnabled else { return }
        do {
            try await helper.setAllAuto()
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
        guard helper.isEnabled else { return }
        let startGeneration = generation
        guard let helperHasForcedFans = try? await helper.heartbeat(), generation == startGeneration else { return }
        let sentForced = sentCommands.values.contains { $0 != .auto }
        if helperHasForcedFans != sentForced {
            // The helper restarted or its watchdog fired; forget what was sent so the next tick resyncs.
            sentCommands = [:]
            if !sentForced { try? await helper.setAllAuto() }
        }
    }

    private func invalidate() {
        generation += 1
        resetEngine()
        sentCommands = [:]
    }

    private func desiredCommands(monitor: ThermalMonitor, configuration: AppConfiguration) -> [FanID: FanCommand] {
        let limits = monitor.fanLimits
        if isBoosting {
            return Dictionary(uniqueKeysWithValues: limits.map { ($0.id, FanCommand.forced(rpm: $0.maxRPM)) })
        }
        switch mode {
        case .auto:
            return Dictionary(uniqueKeysWithValues: limits.map { ($0.id, FanCommand.auto) })
        case .constant:
            return Dictionary(uniqueKeysWithValues: limits.map { fan in
                let speed = configuration.constantSpeeds[fan.id] ?? AppConfiguration.defaultConstantSpeed
                return (fan.id, FanCommand.forced(rpm: speed.rpm(for: fan)))
            })
        case .custom:
            let profile = configuration.profile(id: configuration.activeProfileID) ?? .balanced
            let evaluation = RuleEngine.evaluate(
                profile: profile,
                readings: monitor.sensorReadings,
                sensors: monitor.sensors,
                fans: limits,
                previous: engineState,
                now: Date()
            )
            engineState = evaluation.state
            lastEvaluation = evaluation
            return evaluation.commands
        }
    }

    private func fail(_ message: String) {
        lastError = message
        mode = .auto
        boostUntil = nil
        invalidate()
    }
}
