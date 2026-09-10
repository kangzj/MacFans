import FanwrightCore
import SwiftUI

struct FansView: View {
    @Environment(AppModel.self) private var model
    @AppStorage("linkFanSpeeds") private var linkFanSpeeds = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.monitor.fans.isEmpty {
                    ContentUnavailableView("No Fans Detected", systemImage: "fanblades", description: Text("This Mac does not report any SMC-controlled fans."))
                } else {
                    HStack(spacing: 16) {
                        ForEach(model.monitor.fans) { fan in
                            fanCard(fan)
                        }
                    }
                    if model.monitor.fans.count > 1 {
                        Toggle("Move all fans together in Constant mode", isOn: $linkFanSpeeds)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }
            }
            .padding(20)
        }
    }

    private func fanCard(_ fan: FanState) -> some View {
        Card {
            VStack(spacing: 16) {
                FanGauge(fan: fan, diameter: 150)
                    .frame(maxWidth: .infinity)
                HStack {
                    limit("Min", fan.limits.minRPM)
                    Spacer()
                    modeChip(fan)
                    Spacer()
                    limit("Max", fan.limits.maxRPM)
                }
                constantControl(fan)
            }
        }
    }

    private func limit(_ title: String, _ rpm: Double) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(Formatters.rpm(rpm)).font(.callout).monospacedDigit()
        }
    }

    private func modeChip(_ fan: FanState) -> some View {
        Text(fan.isForced ? "Manual" : "System")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(fan.isForced ? Color.orange.opacity(0.2) : Color.green.opacity(0.15), in: Capsule())
            .foregroundStyle(fan.isForced ? .orange : .green)
    }

    @ViewBuilder
    private func constantControl(_ fan: FanState) -> some View {
        let isConstant = model.controller.mode == .constant
        let percent = percentBinding(for: fan)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Constant speed")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Formatters.percent(percent.wrappedValue)) · \(Formatters.rpm(FanSpeed.percent(percent.wrappedValue).rpm(for: fan.limits)))")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: percent, in: 0...100, step: 1)
                .disabled(!isConstant)
            if !isConstant {
                Text("Switch to Constant mode to use this slider.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func percentBinding(for fan: FanState) -> Binding<Double> {
        Binding(
            get: { model.constantPercent(for: fan) },
            set: { model.setConstantPercent($0, for: linkFanSpeeds ? model.monitor.fans.map(\.id) : [fan.id]) }
        )
    }
}
