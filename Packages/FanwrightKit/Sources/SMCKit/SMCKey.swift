public struct SMCKey: Hashable, Comparable, Sendable, CustomStringConvertible {
    public let code: UInt32

    public init(code: UInt32) {
        self.code = code
    }

    public init(_ string: String) {
        precondition(string.utf8.count == 4, "SMC keys are exactly four ASCII characters")
        code = string.utf8.reduce(0) { ($0 << 8) | UInt32($1) }
    }

    public var string: String {
        String(decoding: [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: code >> $0) }, as: UTF8.self)
    }

    public var description: String { string }

    public func hasPrefix(_ prefix: String) -> Bool {
        string.hasPrefix(prefix)
    }

    public static func < (lhs: SMCKey, rhs: SMCKey) -> Bool {
        lhs.string < rhs.string
    }
}
