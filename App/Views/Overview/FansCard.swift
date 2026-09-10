import MacFansCore
import SwiftUI

struct FansCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Card(title: "Fans", symbol: "fanblades") {
            HStack(spacing: 24) {
                ForEach(model.monitor.fans) { fan in
                    FanGauge(fan: fan, diameter: 112)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 4)
            modeDetail
                .frame(maxWidth: .infinity)
            Spacer(minLength: 0)
            if let first = model.monitor.fans.first {
                TrendStrip(
                    title: "\(first.name) · last 30 min",
                    samples: model.monitor.history.samples(.fan(first.id)),
                    tint: .blue
                )
            }
        }
    }

    @ViewBuilder
    private var modeDetail: some View {
        if let detail = model.controlStatus.detail {
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .frame(minHeight: 22)
        } else {
            constantSlider
        }
    }

    private var constantSlider: some View {
        let fans = model.monitor.fans
        let percent = Binding<Double>(
            get: { fans.first.map { model.constantPercent(for: $0) } ?? 50 },
            set: { model.setConstantPercent($0, for: fans.map(\.id)) }
        )
        return HStack(spacing: 10) {
            Slider(value: percent, in: 0...100, step: 1)
            Text(Formatters.percent(percent.wrappedValue))
                .font(.callout)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
        .frame(minHeight: 22)
    }
}
