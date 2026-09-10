import MacFansCore
import SwiftUI

struct TemperatureRing: View {
    @Environment(AppModel.self) private var model
    let celsius: Double?
    var diameter: CGFloat = 160

    private static let scale: ClosedRange<Double> = 0...110
    private static let sweep = 0.75

    private var fraction: Double {
        guard let celsius else { return 0 }
        let clamped = min(max(celsius, Self.scale.lowerBound), Self.scale.upperBound)
        return (clamped - Self.scale.lowerBound) / (Self.scale.upperBound - Self.scale.lowerBound)
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: Self.sweep)
                .stroke(.quaternary, style: StrokeStyle(lineWidth: diameter * 0.075, lineCap: .round))
            Circle()
                .trim(from: 0, to: Self.sweep * fraction)
                .stroke(
                    AngularGradient(
                        colors: [.green, .green, .yellow, .orange, .red],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * Self.sweep)
                    ),
                    style: StrokeStyle(lineWidth: diameter * 0.075, lineCap: .round)
                )
                .animation(.easeInOut(duration: 0.8), value: fraction)
        }
        .rotationEffect(.degrees(135))
        .frame(width: diameter, height: diameter)
        .overlay {
            VStack(spacing: 2) {
                TemperatureText(celsius: celsius, style: .largeTitle)
                    .font(.system(size: diameter * 0.28, weight: .semibold, design: .rounded))
                Text(celsius.map(Self.status) ?? "—")
                    .font(.system(size: diameter * 0.085, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .offset(y: diameter * 0.03)
        }
    }

    static func status(for celsius: Double) -> String {
        switch celsius {
        case ..<60: "Running cool"
        case ..<80: "Getting warm"
        case ..<95: "Running hot"
        default: "Very hot"
        }
    }
}
