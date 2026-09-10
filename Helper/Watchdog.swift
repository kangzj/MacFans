import Foundation
import Synchronization
import os

final class Watchdog: Sendable {
    private static let checkInterval: TimeInterval = 2

    private let writer: FanWriter
    private let lastHeartbeat = Mutex(Date())
    private let timer: DispatchSourceTimer
    private let log = Logger(subsystem: appBundleIdentifier, category: "Watchdog")

    init(writer: FanWriter) {
        self.writer = writer
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "\(helperMachServiceName).watchdog"))
        timer.schedule(deadline: .now() + Self.checkInterval, repeating: Self.checkInterval)
        timer.setEventHandler { [weak self] in self?.check() }
        timer.resume()
    }

    func recordHeartbeat() {
        lastHeartbeat.withLock { $0 = Date() }
    }

    private func check() {
        let silence = Date().timeIntervalSince(lastHeartbeat.withLock { $0 })
        guard silence > helperWatchdogTimeout, writer.hasForcedFans else { return }
        log.warning("No heartbeat for \(silence, format: .fixed(precision: 0))s; restoring auto fan control")
        do {
            try writer.setAllAuto()
        } catch {
            log.error("Failed to restore auto: \(error.localizedDescription)")
        }
    }
}
