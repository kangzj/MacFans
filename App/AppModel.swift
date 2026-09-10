import AppKit
import Foundation
import MacFansCore
import Observation

@MainActor
@Observable
final class AppModel {
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
        controller = FanController(helper: helper)
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

    // `configuration.mode` remembers the user's choice for "resume on launch"; the controller may fall back
    // to Auto on its own (errors, sleep) without changing that choice.
    func setMode(_ mode: ControlMode) {
        configuration.mode = mode
        controller.setMode(mode)
        Task { await tick() }
    }

    func activateProfile(_ id: UUID) {
        configuration.activeProfileID = id
        controller.resetEngine()
        Task { await tick() }
    }

    func setConstantSpeed(_ speed: FanSpeed, for fan: FanID) {
        configuration.constantSpeeds[fan] = speed
    }

    func toggleBoost() {
        if controller.isBoosting {
            controller.cancelBoost()
        } else {
            controller.boost(for: configuration.boostDuration)
        }
        Task { await tick() }
    }

    func installHelper() {
        do {
            if helper.isEnabled {
                Task { await reinstallHelper() }
            } else {
                try helper.register()
                helperInstallError = nil
            }
        } catch {
            helperInstallError = error.localizedDescription
        }
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

    private func reinstallHelper() async {
        await removeHelper()
        guard helperInstallError == nil else { return }
        do {
            try helper.register()
        } catch {
            helperInstallError = error.localizedDescription
        }
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
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            try? store.save(configuration)
        }
    }
}
