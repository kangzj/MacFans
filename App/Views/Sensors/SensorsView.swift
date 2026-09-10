import MacFansCore
import SwiftUI

struct SensorsView: View {
    @Environment(AppModel.self) private var model
    @State private var search = ""

    var body: some View {
        @Bindable var model = model
        Group {
            if model.configuration.showAllSensors {
                allSensors
            } else {
                summaryList
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Toggle("All Sensors", systemImage: "list.bullet.indent", isOn: $model.configuration.showAllSensors)
                    .help("Show every sensor the SMC exposes instead of the summary.")
            }
        }
    }

    private var summaryList: some View {
        List(model.monitor.summaries) { summary in
            HStack(spacing: 12) {
                Image(systemName: summary.group.symbolName)
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.title).font(.body.weight(.medium))
                    Text(summaryCaption(summary)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Sparkline(samples: model.monitor.history.samples(summary.id), tint: TemperatureTint.color(for: summary.max))
                    .frame(width: 120, height: 28)
                TemperatureText(celsius: summary.max, style: .title2)
                    .frame(width: 70, alignment: .trailing)
            }
            .padding(.vertical, 6)
        }
        .listStyle(.inset)
    }

    private func summaryCaption(_ summary: SensorSummary) -> String {
        let unit = model.configuration.temperatureUnit
        if summary.sensorIDs.count == 1 { return summary.sensorIDs[0].rawValue }
        return "Average \(Formatters.temperature(summary.average, unit: unit)) across \(summary.sensorIDs.count) sensors"
    }

    private var allSensors: some View {
        List {
            ForEach(SensorGroup.allCases, id: \.self) { group in
                let sensors = filteredSensors(in: group)
                if !sensors.isEmpty {
                    Section {
                        ForEach(sensors) { sensor in
                            sensorRow(sensor)
                        }
                    } header: {
                        HStack {
                            Label(group.title, systemImage: group.symbolName)
                            Spacer()
                            if let max = model.monitor.value(for: group, .max) {
                                Text("max \(Formatters.temperature(max, unit: model.configuration.temperatureUnit))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .searchable(text: $search, placement: .toolbar, prompt: "Filter by name or key")
    }

    private func filteredSensors(in group: SensorGroup) -> [Sensor] {
        model.monitor.sensorsWithReadings.filter { sensor in
            sensor.group == group && (search.isEmpty || sensor.name.localizedCaseInsensitiveContains(search) || sensor.id.rawValue.localizedCaseInsensitiveContains(search))
        }
    }

    private func sensorRow(_ sensor: Sensor) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleFavorite(sensor)
            } label: {
                Image(systemName: sensor.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(sensor.isFavorite ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help("Favourite sensors are offered as the menu bar readout.")
            VStack(alignment: .leading, spacing: 2) {
                TextField("Name", text: nameBinding(sensor))
                    .textFieldStyle(.plain)
                    .font(.body.weight(.medium))
                Text(sensor.id.rawValue)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Sparkline(samples: model.monitor.history.samples(sensor.id.rawValue), tint: TemperatureTint.color(for: model.monitor.readings[sensor.id] ?? 0))
                .frame(width: 100, height: 24)
            TemperatureText(celsius: model.monitor.readings[sensor.id], style: .title3)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private func nameBinding(_ sensor: Sensor) -> Binding<String> {
        Binding(
            get: { sensor.name },
            set: { newName in
                var override = model.configuration.sensorOverrides[sensor.id] ?? SensorOverride(name: nil, isFavorite: false)
                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                override.name = trimmed.isEmpty ? nil : trimmed
                model.configuration.sensorOverrides[sensor.id] = override
            }
        )
    }

    private func toggleFavorite(_ sensor: Sensor) {
        var override = model.configuration.sensorOverrides[sensor.id] ?? SensorOverride(name: nil, isFavorite: false)
        override.isFavorite.toggle()
        model.configuration.sensorOverrides[sensor.id] = override
    }
}
