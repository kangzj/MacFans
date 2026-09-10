import AppKit
import Foundation
import FanwrightCore
import Observation

@MainActor
@Observable
final class AppModel {
    private static let saveDebounce: Duration = .milliseconds(500)

    var configuration: AppConfiguration {
        didSet {
            guard configuration != oldValue else { return }
            if configuration.sensorOverrides != oldValue.sensorOverrides {
                monitor.applyOverrides(configuration.sensorOverrides)
            }
            scheduleSave()
        }
    }

    let monitor = ThermalMonitor()
    let helper = HelperClient()
    let controller: FanController
    private(set) var helperInstallError: String?

    private let store: ConfigurationStore
    private var pollTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    private var tickInProgress = false
    private var tickRequested = false

    init(store: ConfigurationStore = ConfigurationStore(directory: ConfigurationStore.defaultDirectory)) {
        self.store = store
        configuration = store.load()
        controller = FanController(sink: helper)
        monitor.applyOverrides(configuration.sensorOverrides)
        if configuration.startInModeOnLaunch {
            controller.setMode(configuration.mode)
        }
        PowerEvents.observe(
            willSleep: { [weak self] in self?.handleSleep() },
            didWake: { [weak self] in self?.helper.refreshStatus() }
        )
        startPolling()
    }

    var activeProfile: Profile {
        configuration.profile(id: configuration.activeProfileID) ?? .balanced
    }

    var controlStatus: ControlStatus {
        if controller.isBoosting, let endsAt = controller.boostEndsAt {
            return .boosting(endsAt: endsAt, returningTo: controller.mode, profileName: activeProfile.name)
        }
        switch controller.mode {
        case .auto:
            return .auto
        case .constant:
            return .constant
        case .custom:
            let evaluation = controller.lastEvaluation
            let activeIDs = evaluation?.state.activeRuleIDs ?? []
            let activeRules = activeProfile.rules.filter { activeIDs.contains($0.id) }.map(\.name)
            let easing = activeRules.isEmpty && (evaluation?.commands.values.contains { $0 != .auto } ?? false)
            return .custom(profileName: activeProfile.name, activeRules: activeRules, isEasingBackToAuto: easing)
        }
    }

    // `configuration.mode` remembers the user's choice for "resume on launch"; the controller may fall back
    // to Auto on its own (errors, sleep) without changing that choice.
    func setMode(_ mode: ControlMode) {
        configuration.mode = mode
        controller.setMode(mode)
        requestTick()
    }

    func activateProfile(_ id: UUID) {
        configuration.activeProfileID = id
        controller.resetEngine()
        requestTick()
    }

    func constantPercent(for fan: FanState) -> Double {
        (configuration.constantSpeeds[fan.id] ?? AppConfiguration.defaultConstantSpeed).percent(for: fan.limits)
    }

    func setConstantPercent(_ percent: Double, for fans: [FanID]) {
        for fan in fans { configuration.constantSpeeds[fan] = .percent(percent) }
    }

    func toggleBoost() {
        if controller.isBoosting {
            controller.cancelBoost()
        } else {
            controller.boost(for: configuration.boostDuration)
        }
        requestTick()
    }

    func installHelper() {
        Task {
            if helper.isEnabled { await removeHelper() }
            guard helperInstallError == nil else { return }
            let error = await registerHelperWithRetry()
            helperInstallError = helper.status == .notRegistered ? error : nil
        }
    }

    // Service Management rejects a registration that lands while the previous one is still being torn down.
    private func registerHelperWithRetry(attempts: Int = 4) async -> String? {
        for attempt in 1...attempts {
            do {
                try helper.register()
                return nil
            } catch {
                if attempt == attempts { return error.localizedDescription }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        return nil
    }

    func removeHelper() async {
        await controller.restoreAuto()
        do {
            try await helper.unregister()
            helperInstallError = nil
        } catch {
            helperInstallError = error.localizedDescription
        }
    }

    func prepareForTermination() async {
        pollTask?.cancel()
        saveTask?.cancel()
        try? store.save(configuration)
        await controller.restoreAuto()
    }

    private func requestTick() {
        Task { await tick() }
    }

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await tick()
                try? await Task.sleep(for: .seconds(configuration.pollInterval))
            }
        }
    }

    private func tick() async {
        if tickInProgress {
            tickRequested = true
            return
        }
        tickInProgress = true
        defer { tickInProgress = false }
        repeat {
            tickRequested = false
            await monitor.refresh()
            await controller.tick(monitor: monitor, configuration: configuration)
        } while tickRequested
    }

    private func handleSleep() {
        Task { await controller.restoreAuto() }
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: Self.saveDebounce)
            guard let self, !Task.isCancelled else { return }
            try? store.save(configuration)
        }
    }
}
