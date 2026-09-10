import Foundation

public struct Profile: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var rules: [Rule]
    public var isBuiltIn: Bool

    public init(id: UUID, name: String, rules: [Rule], isBuiltIn: Bool) {
        self.id = id
        self.name = name
        self.rules = rules
        self.isBuiltIn = isBuiltIn
    }
}
