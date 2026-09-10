import MacFansCore
import SwiftUI

struct ThermalCard: View {
    @Environment(AppModel.self) private var model

    private var headline: Double? {
        [model.monitor.summary(.cpuPerformance)?.max, model.monitor.summary(.gpu)?.max].compactMap { $0 }.max()
            ?? model.monitor.hottest?.celsius
    }

    var body: some View {
        Card(title: "Temperature", symbol: "thermometer.medium") {
            HStack(spacing: 24) {
                TemperatureRing(celsius: headline, diameter: 150)
                VStack(spacing: 10) {
                    ForEach(SensorFamily.headlineFamilies, id: \.self) { family in
                        readingRow(family)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 4)
            Spacer(minLength: 0)
            TrendStrip(
                title: "CPU · last 30 min",
                samples: model.monitor.history.samples(.summary(.cpuPerformance)),
                tint: ThermalLevel(celsius: headline ?? 0).color
            )
        }
    }

    private func readingRow(_ family: SensorFamily) -> some View {
        HStack(spacing: 10) {
            Image(systemName: family.symbolName)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 22)
            Text(family.shortTitle)
                .font(.callout)
            Spacer()
            TemperatureText(celsius: model.monitor.summary(family)?.max, style: .title3)
        }
    }
}
