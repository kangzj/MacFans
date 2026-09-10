import Foundation
import SMCKit

struct SMCSnapshot: Sendable {
    let temperatures: [SMCKey: Double]
    let fans: [FanReading]
}

actor SMCReader {
    private let smc: SMCConnection
    private let keys: [SMCKey]

    init() throws {
        smc = try SMCConnection()
        keys = try smc.temperatureKeys()
    }

    var temperatureKeys: [SMCKey] { keys }

    func snapshot() throws -> SMCSnapshot {
        let count = try smc.fanCount()
        let fans = try (0..<count).map { try smc.fan($0) }
        return SMCSnapshot(temperatures: smc.temperatures(keys), fans: fans)
    }
}
