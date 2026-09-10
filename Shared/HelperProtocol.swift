import Foundation

let helperMachServiceName = "com.jasperkang.macfans.helper"
let helperProtocolVersion = 1

@objc protocol MacFansHelperProtocol {
    func version(reply: @escaping @Sendable (Int) -> Void)
    func setFan(index: Int, rpm: Double, reply: @escaping @Sendable (String?) -> Void)
    func setAuto(index: Int, reply: @escaping @Sendable (String?) -> Void)
    func setAllAuto(reply: @escaping @Sendable (String?) -> Void)
    func heartbeat(reply: @escaping @Sendable (Bool) -> Void)
}
