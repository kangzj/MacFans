import MacFansCore
import SwiftUI

struct FanGauge: View {
    let fan: FanState
    let diameter: CGFloat

    private var fraction: Double {
        guard fan.limits.maxRPM > 0 else { return 0 }
        return min(max(fan.actualRPM / fan.limits.maxRPM, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                ring
                VStack(spacing: 2) {
                    Text(Formatters.rpmValue(fan.actualRPM))
                        .font(.system(size: diameter * 0.2, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("RPM")
                        .font(.system(size: diameter * 0.09, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: diameter, height: diameter)
            .overlay(alignment: .bottom) {
                Text(fan.targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .offset(y: 4)
            }
            Text(fan.name)
                .font(.headline)
        }
    }

    private var ring: some View {
        ZStack {
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(.quaternary, style: StrokeStyle(lineWidth: diameter * 0.09, lineCap: .round))
            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * fraction)
                .stroke(
                    AngularGradient(colors: [.teal, .blue, .indigo], center: .center, startAngle: .degrees(36), endAngle: .degrees(324)),
                    style: StrokeStyle(lineWidth: diameter * 0.09, lineCap: .round)
                )
                .animation(.easeInOut(duration: 0.6), value: fraction)
        }
        .rotationEffect(.degrees(90))
    }
}
