import MacFansCore
import SwiftUI

struct TemperatureField: View {
    @Binding var celsius: Double
    let unit: TemperatureUnit

    var body: some View {
        let display = Binding(
            get: { unit.convert(celsius: celsius).rounded() },
            set: { celsius = unit.celsius(from: $0) }
        )
        HStack(spacing: 2) {
            TextField("", value: display, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 56)
                .multilineTextAlignment(.trailing)
            Stepper("", value: display, in: displayRange, step: 1)
                .labelsHidden()
            Text(unit.symbol)
                .foregroundStyle(.secondary)
        }
    }

    private var displayRange: ClosedRange<Double> {
        let range = SensorCatalog.plausibleRange
        return unit.convert(celsius: range.lowerBound)...unit.convert(celsius: range.upperBound)
    }
}
