import Foundation
import MacFansCore

enum ControlStatus: Equatable {
    case auto
    case boosting(endsAt: Date, returningTo: ControlMode, profileName: String)
    case constant
    case custom(profileName: String, activeRules: [String], isEasingBackToAuto: Bool)
}
