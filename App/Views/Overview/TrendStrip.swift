import SwiftUI

struct TrendStrip: View {
    let title: String
    let samples: [HistorySample]
    let tint: Color
    @AppStorage(OverviewView.trendsExpandedKey) private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            if isExpanded {
                Sparkline(samples: samples, tint: tint)
                    .frame(height: 34)
                    .transition(.opacity)
            }
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 5) {
                    Text(title)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.6), in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .help(isExpanded ? "Hide the last 30 minutes" : "Show the last 30 minutes")
        }
    }
}
