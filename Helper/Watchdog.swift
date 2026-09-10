import Foundation
import Synchronization
import os

final class Watchdog: Sendable {
    static let timeout: TimeInterval = 10

    private let writer: FanWriter
    private let lastHeartbeat = Mutex(Date())
    private let timer: DispatchSourceTimer
    private let log = Logger(subsystem: "com.jasperkang.macfans", category: "Watchdog")

    init(writer: FanWriter) {
        self.writer = writer
        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.jasperkang.macfans.watchdog"))
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in self?.check() }
        timer.resume()
    }

    func recordHeartbeat() {
        lastHeartbeat.withLock { $0 = Date() }
    }

    private func check() {
        let silence = Date().timeIntervalSince(lastHeartbeat.withLock { $0 })
        guard silence > Self.timeout, writer.hasForcedFans else { return }
        log.warning("No heartbeat for \(silence, format: .fixed(precision: 0))s; restoring auto fan control")
        do {
            try writer.setAllAuto()
        } catch {
            log.error("Failed to restore auto: \(error.localizedDescription)")
        }
    }
}
