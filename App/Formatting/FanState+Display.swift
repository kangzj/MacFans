import MacFansCore

extension FanState {
    var targetDescription: String {
        isForced ? forcedTarget : "Auto"
    }

    var menuBarDescription: String {
        isForced ? forcedTarget : "System controlled"
    }

    private var forcedTarget: String {
        "Target \(Formatters.rpm(targetRPM))"
    }
}
