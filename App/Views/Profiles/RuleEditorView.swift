import MacFansCore
import SwiftUI

struct RuleEditorView: View {
    @Environment(AppModel.self) private var model
    @Binding var rule: Rule
    let profile: Profile
    let isEditable: Bool
    let onDelete: () -> Void

    private enum TriggerKind: String, CaseIterable { case group = "Group", sensor = "Sensor" }
    private enum SpeedKind: String, CaseIterable { case percent = "Percent", rpm = "RPM", max = "Max" }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                titleRow
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                    GridRow {
                        Text("When").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                        triggerControls
                    }
                    GridRow {
                        Text("Set").gridColumnAlignment(.trailing).foregroundStyle(.secondary)
                        speedControls
                    }
                }
                if !rule.isValid {
                    Label("“Until below” must be lower than “above”.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .disabled(!isEditable)
        }
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
            Spacer()
            statusPill
            if isEditable {
                Button(role: .destructive, action: onDelete) { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
                    .help("Delete rule")
            }
        }
    }

    private var statusPill: some View {
        let value = RuleEngine.triggerValue(rule.trigger, readings: model.monitor.sensorReadings, sensors: model.monitor.sensors)
        let isLive = model.controller.mode == .custom && model.configuration.activeProfileID == profile.id
        let isActive = isLive
            ? model.controller.lastEvaluation?.state.activeRuleIDs.contains(rule.id) ?? false
            : (value.map { $0 >= rule.onAbove } ?? false) && rule.isEnabled && rule.isValid
        let unit = model.configuration.temperatureUnit
        return HStack(spacing: 6) {
            if let value {
                Text(Formatters.temperature(value, unit: unit))
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

    private var triggerControls: some View {
        HStack(spacing: 8) {
            Picker("", selection: triggerKind) {
                ForEach(TriggerKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 140)
            switch rule.trigger {
            case .group(let group, let aggregate):
                Picker("", selection: Binding(get: { group }, set: { rule.trigger = .group($0, aggregate) })) {
                    ForEach(SensorGroup.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                Picker("", selection: Binding(get: { aggregate }, set: { rule.trigger = .group(group, $0) })) {
                    Text("max").tag(Aggregate.max)
                    Text("average").tag(Aggregate.average)
                }
                .labelsHidden()
            case .sensor(let id):
                Picker("", selection: Binding(get: { id }, set: { rule.trigger = .sensor($0) })) {
                    ForEach(sensorChoices) { sensor in
                        Text(sensor.isFavorite ? "★ \(sensor.name)" : sensor.name).tag(sensor.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
            }
            Text("is above")
            temperatureField($rule.onAbove)
            Text("until below")
            temperatureField($rule.offBelow)
        }
    }

    private var speedControls: some View {
        HStack(spacing: 8) {
            Picker("", selection: fanChoice) {
                Text("All fans").tag(FanSelection.all)
                ForEach(model.monitor.fans) { fan in
                    Text(fan.name).tag(FanSelection.some([fan.id]))
                }
            }
            .labelsHidden()
            .frame(width: 140)
            Text("to")
            Picker("", selection: speedKind) {
                ForEach(SpeedKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 180)
            switch rule.speed {
            case .percent(let value):
                numberField(value, range: 0...100, suffix: "%") { rule.speed = .percent($0) }
            case .rpm(let value):
                numberField(value, range: 0...10_000, suffix: "RPM") { rule.speed = .rpm($0) }
            case .max:
                EmptyView()
            }
        }
    }

    private var sensorChoices: [Sensor] {
        model.monitor.sensorsWithReadings.sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    private var triggerKind: Binding<TriggerKind> {
        Binding(
            get: { if case .sensor = rule.trigger { .sensor } else { .group } },
            set: { kind in
                switch kind {
                case .group: rule.trigger = .group(.cpu, .max)
                case .sensor: rule.trigger = .sensor(sensorChoices.first?.id ?? SensorID(rawValue: "Tp00"))
                }
            }
        )
    }

    private var fanChoice: Binding<FanSelection> {
        Binding(
            get: {
                if case .some(let ids) = rule.fans, ids.count == 1 { return rule.fans }
                return .all
            },
            set: { rule.fans = $0 }
        )
    }

    private var speedKind: Binding<SpeedKind> {
        Binding(
            get: {
                switch rule.speed {
                case .percent: .percent
                case .rpm: .rpm
                case .max: .max
                }
            },
            set: { kind in
                switch kind {
                case .percent: rule.speed = .percent(60)
                case .rpm: rule.speed = .rpm(model.monitor.fans.first.map { ($0.limits.minRPM + $0.limits.maxRPM) / 2 } ?? 3000)
                case .max: rule.speed = .max
                }
            }
        )
    }

    private func temperatureField(_ celsius: Binding<Double>) -> some View {
        let unit = model.configuration.temperatureUnit
        let display = Binding(
            get: { Formatters.converted(celsius.wrappedValue, to: unit).rounded() },
            set: { celsius.wrappedValue = Formatters.celsius($0, from: unit) }
        )
        return HStack(spacing: 2) {
            TextField("", value: display, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 56)
                .multilineTextAlignment(.trailing)
            Stepper("", value: display, in: -40...150, step: 1)
                .labelsHidden()
            Text(unit == .celsius ? "°C" : "°F")
                .foregroundStyle(.secondary)
        }
    }

    private func numberField(_ value: Double, range: ClosedRange<Double>, suffix: String, set: @escaping (Double) -> Void) -> some View {
        let binding = Binding(get: { value }, set: { set(min(max($0, range.lowerBound), range.upperBound)) })
        return HStack(spacing: 2) {
            TextField("", value: binding, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
            Stepper("", value: binding, in: range, step: suffix == "%" ? 5 : 100)
                .labelsHidden()
            Text(suffix)
                .foregroundStyle(.secondary)
        }
    }
}
