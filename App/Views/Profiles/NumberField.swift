import SwiftUI

struct NumberField: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String

    var body: some View {
        let clamped = Binding(get: { value }, set: { value = min(max($0, range.lowerBound), range.upperBound) })
        HStack(spacing: 2) {
            TextField("", value: clamped, format: .number.precision(.fractionLength(0)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
            Stepper("", value: clamped, in: range, step: step)
                .labelsHidden()
            Text(suffix)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
    }
}
