import Foundation

let appBundleIdentifier = "com.jasperkang.fanwright"
let helperMachServiceName = "com.jasperkang.fanwright.helper"
let helperProtocolVersion = 1
let helperWatchdogTimeout: TimeInterval = 10

@objc protocol FanwrightHelperProtocol {
    func version(reply: @escaping @Sendable (Int) -> Void)
    func setFan(index: Int, rpm: Double, reply: @escaping @Sendable (String?) -> Void)
    func setAuto(index: Int, reply: @escaping @Sendable (String?) -> Void)
    func setAllAuto(reply: @escaping @Sendable (String?) -> Void)
    func heartbeat(reply: @escaping @Sendable (Bool) -> Void)
}
