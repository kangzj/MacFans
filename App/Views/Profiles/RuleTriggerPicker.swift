import MacFansCore
import SwiftUI

struct RuleTriggerPicker: View {
    private enum Kind: String, CaseIterable { case group = "Group", sensor = "Sensor" }

    private static let fallbackSensorID = SensorID(rawValue: "Tp00")

    @Environment(AppModel.self) private var model
    @Binding var trigger: RuleTrigger

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: kind) {
                ForEach(Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            switch trigger {
            case .group(let group, let aggregate):
                Picker("", selection: Binding(get: { group }, set: { trigger = .group($0, aggregate) })) {
                    ForEach(SensorGroup.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .frame(width: 120)
                Picker("", selection: Binding(get: { aggregate }, set: { trigger = .group(group, $0) })) {
                    Text("hottest sensor").tag(Aggregate.max)
                    Text("average").tag(Aggregate.average)
                }
                .labelsHidden()
                .frame(width: 150)
            case .sensor(let id):
                Picker("", selection: Binding(get: { id }, set: { trigger = .sensor($0) })) {
                    ForEach(sensorChoices) { sensor in
                        Text(sensor.isFavorite ? "★ \(sensor.name)" : sensor.name).tag(sensor.id)
                    }
                }
                .labelsHidden()
                .frame(width: 278)
            }
        }
    }

    private var sensorChoices: [Sensor] {
        model.monitor.sensorsWithReadings.sorted { ($0.isFavorite ? 0 : 1, $0.name) < ($1.isFavorite ? 0 : 1, $1.name) }
    }

    private var kind: Binding<Kind> {
        Binding(
            get: { if case .sensor = trigger { .sensor } else { .group } },
            set: { kind in
                switch kind {
                case .group: trigger = .group(.cpu, .max)
                case .sensor: trigger = .sensor(sensorChoices.first?.id ?? Self.fallbackSensorID)
                }
            }
        )
    }
}
