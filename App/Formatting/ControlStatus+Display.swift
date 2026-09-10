import Foundation
import MacFansCore

extension ControlStatus {
    var summary: String {
        switch self {
        case .custom(let profileName, _, _), .boosting(_, .custom, let profileName):
            "Custom · \(profileName)"
        default:
            mode.title
        }
    }

    // Constant mode shows its speed slider where the other modes show this line.
    var detail: String? {
        switch self {
        case .auto:
            "Auto · managed by macOS."
        case .constant, .boosting(_, returningTo: .constant, _):
            nil
        case .boosting(let endsAt, _, _):
            "Full blast until \(Self.clockTime(endsAt))."
        case .custom(_, let activeRules, _) where !activeRules.isEmpty:
            activeRules.joined(separator: ", ") + (activeRules.count == 1 ? " is active." : " are active.")
        case .custom(_, _, true):
            "Rules released, easing back to Auto."
        case .custom(let profileName, _, false):
            "Custom · “\(profileName)”, no rule active."
        }
    }

    func boostButtonHelp(duration: TimeInterval) -> String {
        if case .boosting(let endsAt, _, _) = self {
            return "Stop full blast (ends at \(Self.clockTime(endsAt)))"
        }
        return "Full blast for \(Formatters.minutes(duration)), then back to \(mode.title)"
    }

    private var mode: ControlMode {
        switch self {
        case .auto: .auto
        case .constant: .constant
        case .boosting(_, let returningTo, _): returningTo
        case .custom: .custom
        }
    }

    private static func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}
