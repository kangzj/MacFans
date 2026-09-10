import Foundation

let helperMachServiceName = "com.jasperkang.macfans.helper"
let helperProtocolVersion = 1

@objc protocol MacFansHelperProtocol {
    func version(reply: @escaping (Int) -> Void)
    func setFan(index: Int, rpm: Double, reply: @escaping (String?) -> Void)
    func setAuto(index: Int, reply: @escaping (String?) -> Void)
    func setAllAuto(reply: @escaping (String?) -> Void)
    func heartbeat(reply: @escaping (Bool) -> Void)
}
