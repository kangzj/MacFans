import Foundation

final class HelperListener: NSObject, NSXPCListenerDelegate {
    private let service: HelperService

    init(service: HelperService) {
        self.service = service
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(#"identifier "com.jasperkang.macfans""#)
        connection.exportedInterface = NSXPCInterface(with: MacFansHelperProtocol.self)
        connection.exportedObject = service
        connection.resume()
        return true
    }
}

final class HelperService: NSObject, MacFansHelperProtocol {
    private let writer: FanWriter
    private let watchdog: Watchdog

    init(writer: FanWriter, watchdog: Watchdog) {
        self.writer = writer
        self.watchdog = watchdog
    }

    func version(reply: @escaping @Sendable (Int) -> Void) {
        reply(helperProtocolVersion)
    }

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
