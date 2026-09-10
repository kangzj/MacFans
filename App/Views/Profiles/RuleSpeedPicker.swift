import MacFansCore
import SwiftUI

struct RuleSpeedPicker: View {
    private enum Kind: String, CaseIterable { case percent = "Percent", rpm = "RPM", max = "Max" }

    static let defaultPercent: Double = 60
    private static let percentRange: ClosedRange<Double> = 0...100
    private static let percentStep: Double = 5
    private static let rpmRange: ClosedRange<Double> = 0...10_000
    private static let rpmStep: Double = 100
    private static let fallbackRPM: Double = 3000

    @Environment(AppModel.self) private var model
    @Binding var speed: FanSpeed
    @Binding var fans: FanSelection

    var body: some View {
        HStack(spacing: 8) {
            Picker("", selection: fanChoice) {
                Text("All fans").tag(FanSelection.all)
                ForEach(model.monitor.fans) { fan in
                    Text(fan.name).tag(FanSelection.some([fan.id]))
                }
            }
            .labelsHidden()
            .frame(width: 120)
            Text("to")
            Picker("", selection: kind) {
                ForEach(Kind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            switch speed {
            case .percent(let value):
                NumberField(value: Binding(get: { value }, set: { speed = .percent($0) }), range: Self.percentRange, step: Self.percentStep, suffix: "%")
            case .rpm(let value):
                NumberField(value: Binding(get: { value }, set: { speed = .rpm($0) }), range: Self.rpmRange, step: Self.rpmStep, suffix: "RPM")
            case .max:
                EmptyView()
            }
        }
    }

    private var fanChoice: Binding<FanSelection> {
        Binding(
            get: {
                if case .some(let ids) = fans, ids.count == 1, model.monitor.fans.contains(where: { ids.contains($0.id) }) { return fans }
                return .all
            },
            set: { fans = $0 }
        )
    }

    private var kind: Binding<Kind> {
        Binding(
            get: {
                switch speed {
                case .percent: .percent
                case .rpm: .rpm
                case .max: .max
                }
            },
            set: { kind in
                switch kind {
                case .percent: speed = .percent(Self.defaultPercent)
                case .rpm: speed = .rpm(model.monitor.fans.first.map { ($0.limits.minRPM + $0.limits.maxRPM) / 2 } ?? Self.fallbackRPM)
                case .max: speed = .max
                }
            }
        )
    }
}
