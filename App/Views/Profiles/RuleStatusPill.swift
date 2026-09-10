import FanwrightCore
import SwiftUI

struct RuleStatusPill: View {
    @Environment(AppModel.self) private var model
    let rule: Rule
    let profileID: UUID

    var body: some View {
        let value = triggerValue
        let isActive = isLive
            ? model.controller.lastEvaluation?.state.activeRuleIDs.contains(rule.id) ?? false
            : (value.map { $0 >= rule.onAbove } ?? false) && rule.isEnabled && rule.isValid
        HStack(spacing: 6) {
            if let value {
                Text(Formatters.temperature(value, unit: model.configuration.temperatureUnit))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Text(isActive ? (isLive ? "Active" : "Would be active") : (isLive ? "Idle" : "Would be idle"))
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isActive ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12), in: Capsule())
                .foregroundStyle(isActive ? .green : .secondary)
        }
        .font(.caption)
    }

    private var isLive: Bool {
        model.controller.mode == .custom && model.configuration.activeProfileID == profileID
    }

    private var triggerValue: Double? {
        if isLive, let value = model.controller.lastEvaluation?.triggerValues[rule.id] {
            return value
        }
        return RuleEngine.triggerValue(rule.trigger, readings: model.monitor.sensorReadings, sensors: model.monitor.sensors)
    }
}
