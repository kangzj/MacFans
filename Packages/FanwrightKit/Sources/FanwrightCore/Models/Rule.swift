import Foundation

public struct Rule: Identifiable, Codable, Hashable, Sendable {
    static let defaultHysteresis: Double = 5

    public var id: UUID
    public var name: String
    public var isEnabled: Bool
    public var trigger: RuleTrigger
    public var onAbove: Double
    public var offBelow: Double
    public var fans: FanSelection
    public var speed: FanSpeed

    public init(
        id: UUID = UUID(),
        name: String,
        isEnabled: Bool = true,
        trigger: RuleTrigger,
        onAbove: Double,
        offBelow: Double? = nil,
        fans: FanSelection = .all,
        speed: FanSpeed
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.onAbove = onAbove
        self.offBelow = offBelow ?? onAbove - Self.defaultHysteresis
        self.fans = fans
        self.speed = speed
    }

    public var isValid: Bool {
        offBelow < onAbove
    }
}
