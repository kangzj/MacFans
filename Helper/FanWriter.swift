import Foundation
import SMCKit
import os

final class FanWriter: Sendable {
    private let smc: SMCConnection
    private let limits: [Int: (min: Double, max: Double)]
    private let log = Logger(subsystem: appBundleIdentifier, category: "FanWriter")

    init() throws {
        smc = try SMCConnection()
        var limits: [Int: (min: Double, max: Double)] = [:]
        for index in 0..<(try smc.fanCount()) {
            let fan = try smc.fan(index)
            limits[index] = (fan.minRPM, fan.maxRPM)
        }
        self.limits = limits
        log.info("Ready with \(limits.count) fans")
    }

    var hasForcedFans: Bool {
        limits.keys.contains { (try? smc.fan($0).isForced) ?? false }
    }

    func setFan(index: Int, rpm: Double) throws {
        guard let limits = limits[index] else { throw HelperError.unknownFan(index) }
        let clamped = min(max(rpm, limits.min), limits.max)
        try smc.setFanForced(index, true)
        try smc.setFanTarget(index, rpm: clamped)
        log.info("Fan \(index) forced to \(clamped, format: .fixed(precision: 0)) RPM")
    }

    func setAuto(index: Int) throws {
        guard limits[index] != nil else { throw HelperError.unknownFan(index) }
        try smc.setFanForced(index, false)
        log.info("Fan \(index) returned to auto")
    }

    func setAllAuto() throws {
        var firstError: Error?
        for index in limits.keys.sorted() {
            do { try setAuto(index: index) } catch { firstError = firstError ?? error }
        }
        if let firstError { throw firstError }
    }
}

enum HelperError: LocalizedError {
    case unknownFan(Int)

    var errorDescription: String? {
        switch self {
        case .unknownFan(let index): "No fan with index \(index)"
        }
    }
}
