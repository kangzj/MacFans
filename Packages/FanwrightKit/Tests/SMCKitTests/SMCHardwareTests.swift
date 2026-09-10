import Foundation
import Testing
@testable import SMCKit

@Suite(.enabled(if: ProcessInfo.processInfo.environment["MACFANS_HW_TESTS"] == "1"))
struct SMCHardwareTests {
    @Test func readsFansAndTemperatures() throws {
        let smc = try SMCConnection()
        let count = try smc.fanCount()
        #expect(count > 0)
        let fan = try smc.fan(0)
        #expect(fan.maxRPM > fan.minRPM)
        let keys = try smc.temperatureKeys()
        #expect(keys.count > 10)
        let temps = smc.temperatures(keys)
        #expect(temps.values.contains { $0 > 10 && $0 < 120 })
    }

    @Test func writeWithoutRootIsNotPrivileged() throws {
        let smc = try SMCConnection()
        #expect(throws: SMCError.self) { try smc.setFanForced(0, false) }
    }
}
