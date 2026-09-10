public enum SMCDataType: Equatable, Sendable {
    case flt, sp78, fpe2, ui8, ui16, ui32, si8, si16
    case unknown(String)

    public init(tag: String) {
        switch tag {
        case "flt ": self = .flt
        case "sp78": self = .sp78
        case "fpe2": self = .fpe2
        case "ui8 ": self = .ui8
        case "ui16": self = .ui16
        case "ui32": self = .ui32
        case "si8 ": self = .si8
        case "si16": self = .si16
        default: self = .unknown(tag)
        }
    }

    public var tag: String {
        switch self {
        case .flt: "flt "
        case .sp78: "sp78"
        case .fpe2: "fpe2"
        case .ui8: "ui8 "
        case .ui16: "ui16"
        case .ui32: "ui32"
        case .si8: "si8 "
        case .si16: "si16"
        case .unknown(let tag): tag
        }
    }

    public func decode(_ bytes: [UInt8]) -> Double? {
        switch self {
        case .flt:
            guard bytes.count >= 4 else { return nil }
            return Double(Float(bitPattern: bytes.prefix(4).reversed().reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }))
        case .sp78:
            guard let raw = bigEndianUInt16(bytes) else { return nil }
            return Double(Int16(bitPattern: raw)) / 256
        case .fpe2:
            guard let raw = bigEndianUInt16(bytes) else { return nil }
            return Double(raw) / 4
        case .ui8:
            return bytes.first.map(Double.init)
        case .ui16:
            return bigEndianUInt16(bytes).map(Double.init)
        case .ui32:
            guard bytes.count >= 4 else { return nil }
            return Double(bytes.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) })
        case .si8:
            return bytes.first.map { Double(Int8(bitPattern: $0)) }
        case .si16:
            guard let raw = bigEndianUInt16(bytes) else { return nil }
            return Double(Int16(bitPattern: raw))
        case .unknown:
            return nil
        }
    }

    public func encode(_ value: Double) -> [UInt8]? {
        switch self {
        case .flt:
            return withUnsafeBytes(of: Float(value).bitPattern.littleEndian) { Array($0) }
        case .ui8:
            return [UInt8(clamping: Int(value))]
        case .ui16:
            let raw = UInt16(clamping: Int(value))
            return [UInt8(raw >> 8), UInt8(raw & 0xFF)]
        default:
            return nil
        }
    }

    private func bigEndianUInt16(_ bytes: [UInt8]) -> UInt16? {
        guard bytes.count >= 2 else { return nil }
        return UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    }
}
