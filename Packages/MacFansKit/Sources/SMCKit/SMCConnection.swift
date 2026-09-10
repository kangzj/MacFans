import CSMC
import Foundation
import IOKit

public struct SMCKeyInfo: Sendable {
    public let dataSize: Int
    public let dataType: SMCDataType
    public let attributes: UInt8
}

public enum SMCError: Error {
    case serviceNotFound
    case openFailed(kern_return_t)
    case callFailed(kern_return_t)
    case smcResult(UInt8)
    case unsupportedType(SMCDataType)
    case notPrivileged
}

public final class SMCConnection: @unchecked Sendable {
    private static let notPrivilegedReturn = kern_return_t(bitPattern: 0xE000_02C1)
    private static let keyCountKey = SMCKey("#KEY")

    private let connection: io_connect_t
    let lock = NSLock()
    private var keyInfoCache: [SMCKey: SMCKeyInfo] = [:]
    var temperatureKeyCache: [SMCKey]?

    public init() throws {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { throw SMCError.serviceNotFound }
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = 0
        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        guard result == KERN_SUCCESS else { throw SMCError.openFailed(result) }
        self.connection = connection
    }

    deinit {
        IOServiceClose(connection)
    }

    public func keyInfo(_ key: SMCKey) throws -> SMCKeyInfo {
        if let cached = lock.withLock({ keyInfoCache[key] }) { return cached }

        var input = SMCParamStruct()
        input.key = key.code
        input.data8 = CChar(kSMCGetKeyInfo)
        let output = try call(input)
        let info = SMCKeyInfo(
            dataSize: Int(output.keyInfo.dataSize),
            dataType: SMCDataType(tag: SMCKey(code: output.keyInfo.dataType).string),
            attributes: UInt8(bitPattern: output.keyInfo.dataAttributes)
        )
        lock.withLock { keyInfoCache[key] = info }
        return info
    }

    public func readBytes(_ key: SMCKey) throws -> [UInt8] {
        let info = try keyInfo(key)
        var input = SMCParamStruct()
        input.key = key.code
        input.keyInfo.dataSize = UInt32(info.dataSize)
        input.data8 = CChar(kSMCReadKey)
        let output = try call(input)
        return withUnsafeBytes(of: output.bytes) { Array($0.prefix(info.dataSize)) }
    }

    public func readDouble(_ key: SMCKey) throws -> Double {
        let info = try keyInfo(key)
        guard let value = info.dataType.decode(try readBytes(key)) else {
            throw SMCError.unsupportedType(info.dataType)
        }
        return value
    }

    public func write(_ key: SMCKey, value: Double) throws {
        let info = try keyInfo(key)
        guard let bytes = info.dataType.encode(value) else { throw SMCError.unsupportedType(info.dataType) }

        var input = SMCParamStruct()
        input.key = key.code
        input.keyInfo.dataSize = UInt32(info.dataSize)
        input.data8 = CChar(kSMCWriteKey)
        withUnsafeMutableBytes(of: &input.bytes) { $0.copyBytes(from: bytes.prefix($0.count)) }
        _ = try call(input)
    }

    public func allKeys() throws -> [SMCKey] {
        let count = Int(try readDouble(Self.keyCountKey))
        return try (0..<count).map { index in
            var input = SMCParamStruct()
            input.data8 = CChar(kSMCGetKeyFromIndex)
            input.data32 = UInt32(index)
            return SMCKey(code: try call(input).key)
        }
    }

    private func call(_ input: SMCParamStruct) throws -> SMCParamStruct {
        var input = input
        var output = SMCParamStruct()
        var outputSize = MemoryLayout<SMCParamStruct>.size
        let result = lock.withLock {
            IOConnectCallStructMethod(
                connection, UInt32(kSMCHandleYPCEvent), &input, MemoryLayout<SMCParamStruct>.size, &output, &outputSize
            )
        }
        switch result {
        case KERN_SUCCESS: break
        case Self.notPrivilegedReturn: throw SMCError.notPrivileged
        default: throw SMCError.callFailed(result)
        }
        guard output.result == 0 else { throw SMCError.smcResult(UInt8(bitPattern: output.result)) }
        return output
    }
}
