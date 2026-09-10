import FanwrightCore
import SwiftUI

struct RuleEditorView: View {
    @Environment(AppModel.self) private var model
    @Binding var rule: Rule
    let profileID: UUID
    let onDelete: () -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                titleRow
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        rowLabel("When")
                        RuleTriggerPicker(trigger: $rule.trigger)
                    }
                    GridRow {
                        rowLabel("Threshold")
                        thresholdControls
                    }
                    GridRow {
                        rowLabel("Set")
                        RuleSpeedPicker(speed: $rule.speed, fans: $rule.fans)
                    }
                }
                if !rule.isValid {
                    Label("“Until below” must be lower than “above”.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func rowLabel(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(width: 66, alignment: .trailing)
    }

    private var titleRow: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $rule.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
            TextField("Rule name", text: $rule.name)
                .textFieldStyle(.plain)
                .font(.headline)
            Spacer(minLength: 8)
            RuleStatusPill(rule: rule, profileID: profileID)
                .fixedSize()
            Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                .buttonStyle(.borderless)
                .help("Delete rule")
        }
    }

    private var thresholdControls: some View {
        let unit = model.configuration.temperatureUnit
        return HStack(spacing: 8) {
            Text("is above")
            TemperatureField(celsius: $rule.onAbove, unit: unit)
            Text("until below")
            TemperatureField(celsius: $rule.offBelow, unit: unit)
        }
        .fixedSize()
    }
}
