import Foundation

final class HelperService: NSObject, FanwrightHelperProtocol {
    private let writer: FanWriter
    private let watchdog: Watchdog

    init(writer: FanWriter, watchdog: Watchdog) {
        self.writer = writer
        self.watchdog = watchdog
    }

    func version(reply: @escaping @Sendable (Int) -> Void) {
        reply(helperProtocolVersion)
    }

    // Only forcing a fan arms the watchdog; returning fans to auto is always safe without a heartbeat.
    func setFan(index: Int, rpm: Double, reply: @escaping @Sendable (String?) -> Void) {
        watchdog.recordHeartbeat()
        reply(errorMessage { try writer.setFan(index: index, rpm: rpm) })
    }

    func setAuto(index: Int, reply: @escaping @Sendable (String?) -> Void) {
        reply(errorMessage { try writer.setAuto(index: index) })
    }

    func setAllAuto(reply: @escaping @Sendable (String?) -> Void) {
        reply(errorMessage { try writer.setAllAuto() })
    }

    func heartbeat(reply: @escaping @Sendable (Bool) -> Void) {
        watchdog.recordHeartbeat()
        reply(writer.hasForcedFans)
    }

    private func errorMessage(_ operation: () throws -> Void) -> String? {
        do {
            try operation()
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
