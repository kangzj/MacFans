import Foundation
import Security

final class HelperListener: NSObject, NSXPCListenerDelegate {
    private let service: HelperService
    private let requirement: String

    init(service: HelperService) {
        self.service = service
        requirement = Self.clientRequirement()
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(requirement)
        connection.exportedInterface = NSXPCInterface(with: FanwrightHelperProtocol.self)
        connection.exportedObject = service
        connection.resume()
        return true
    }

    // A Developer ID build pins clients to the same team; an ad-hoc development build can only match the identifier.
    private static func clientRequirement() -> String {
        let identifier = #"identifier "\#(appBundleIdentifier)""#
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
