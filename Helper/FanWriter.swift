import Foundation
import SMCKit
import Synchronization
import os

final class FanWriter: Sendable {
    private struct State {
        var limits: [Int: (min: Double, max: Double)] = [:]
        var forced: Set<Int> = []
    }

    private let smc: SMCConnection
    private let state = Mutex(State())
    private let log = Logger(subsystem: "com.jasperkang.macfans", category: "FanWriter")

    init() throws {
        smc = try SMCConnection()
        let count = try smc.fanCount()
        var limits: [Int: (min: Double, max: Double)] = [:]
        for index in 0..<count {
            let fan = try smc.fan(index)
            limits[index] = (fan.minRPM, fan.maxRPM)
        }
        state.withLock { $0.limits = limits }
        log.info("Ready with \(count) fans")
    }

    var hasForcedFans: Bool { state.withLock { !$0.forced.isEmpty } }

    func setFan(index: Int, rpm: Double) throws {
        guard let limits = state.withLock({ $0.limits[index] }) else { throw HelperError.unknownFan(index) }
        let clamped = min(max(rpm, limits.min), limits.max)
        try smc.setFanForced(index, true)
        try smc.setFanTarget(index, rpm: clamped)
        state.withLock { _ = $0.forced.insert(index) }
        log.info("Fan \(index) forced to \(clamped, format: .fixed(precision: 0)) RPM")
    }

    func setAuto(index: Int) throws {
        guard state.withLock({ $0.limits[index] != nil }) else { throw HelperError.unknownFan(index) }
        try smc.setFanForced(index, false)
        state.withLock { _ = $0.forced.remove(index) }
        log.info("Fan \(index) returned to auto")
    }

    func setAllAuto() throws {
        let indices = state.withLock { Array($0.limits.keys).sorted() }
        var firstError: Error?
        for index in indices {
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
