import Charts
import SwiftUI

struct Sparkline: View {
    let samples: [HistorySample]
    var tint: Color = .accentColor

    var body: some View {
        Chart(samples) { sample in
            AreaMark(x: .value("Time", sample.id), y: .value("Value", sample.value))
                .foregroundStyle(tint.opacity(0.15))
                .interpolationMethod(.monotone)
            LineMark(x: .value("Time", sample.id), y: .value("Value", sample.value))
                .foregroundStyle(tint)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                .interpolationMethod(.monotone)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain)
        .chartLegend(.hidden)
    }

    private var yDomain: ClosedRange<Double> {
        let values = samples.map(\.value)
        guard let low = values.min(), let high = values.max() else { return 0...1 }
        let padding = max((high - low) * 0.2, 1)
        return (low - padding)...(high + padding)
    }
}
