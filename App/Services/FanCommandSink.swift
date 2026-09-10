@MainActor
protocol FanCommandSink: AnyObject {
    var isEnabled: Bool { get }
    func setFan(index: Int, rpm: Double) async throws
    func setAuto(index: Int) async throws
    func setAllAuto() async throws
    func heartbeat() async throws -> Bool
}
