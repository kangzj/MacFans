import AppKit

@MainActor
enum PowerEvents {
    static func observe(willSleep: @escaping @MainActor () -> Void, didWake: @escaping @MainActor () -> Void) {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated(willSleep)
        }
        center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated(didWake)
        }
    }
}
