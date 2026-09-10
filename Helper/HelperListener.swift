import Foundation
import Security

final class HelperListener: NSObject, NSXPCListenerDelegate {
    static let clientIdentifier = "com.jasperkang.macfans"

    private let service: HelperService
    private let requirement: String

    init(service: HelperService) {
        self.service = service
        requirement = Self.clientRequirement()
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(requirement)
        connection.exportedInterface = NSXPCInterface(with: MacFansHelperProtocol.self)
        connection.exportedObject = service
        connection.resume()
        return true
    }

    // A Developer ID build pins clients to the same team; an ad-hoc development build can only match the identifier.
    private static func clientRequirement() -> String {
        let identifier = #"identifier "\#(clientIdentifier)""#
        guard let team = ownTeamIdentifier() else { return identifier }
        return #"anchor apple generic and \#(identifier) and certificate leaf[subject.OU] = "\#(team)""#
    }

    private static func ownTeamIdentifier() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess else { return nil }
        return (info as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String
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
