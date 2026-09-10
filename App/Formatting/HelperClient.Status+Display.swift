import Foundation

extension HelperClient.Status {
    static let signingGuideURL = URL(string: "https://github.com/kangzj/fanwright#building-a-copy-that-can-control-fans")!

    var summary: String {
        switch self {
        case .enabled: "Installed and approved"
        case .requiresApproval: "Waiting for approval in Login Items"
        case .notRegistered: "Not installed"
        case .notFound: "Helper missing from the app bundle"
        case .unsignedBuild: "Unavailable in this unsigned build"
        }
    }

    var callToAction: String? {
        switch self {
        case .enabled: nil
        case .requiresApproval: "Approve Fanwright Helper in System Settings › Login Items to enable fan control."
        case .notRegistered, .notFound: "Fan control needs a small privileged helper. Reading sensors works without it."
        case .unsignedBuild: "This copy is not signed with an Apple identity, so macOS will not run the fan control helper. Sensors still work."
        }
    }

    var actionTitle: String {
        switch self {
        case .requiresApproval: "Open Login Items"
        case .unsignedBuild: "How to Fix"
        default: "Install Helper"
        }
    }
}
