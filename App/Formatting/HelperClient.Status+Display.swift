extension HelperClient.Status {
    var summary: String {
        switch self {
        case .enabled: "Installed and approved"
        case .requiresApproval: "Waiting for approval in Login Items"
        case .notRegistered: "Not installed"
        case .notFound: "Helper missing from the app bundle"
        }
    }

    var callToAction: String? {
        switch self {
        case .enabled: nil
        case .requiresApproval: "Approve MacFans Helper in System Settings › Login Items to enable fan control."
        case .notRegistered, .notFound: "Fan control needs a small privileged helper. Reading sensors works without it."
        }
    }
}
