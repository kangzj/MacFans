import SwiftUI

struct BoostButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            model.toggleBoost()
        } label: {
            Label(model.controller.isBoosting ? "Stop Full Blast" : "Full Blast", systemImage: "wind")
        }
        .labelStyle(.iconOnly)
        .tint(model.controller.isBoosting ? .orange : nil)
        .disabled(!model.helper.isEnabled)
        .help(helpText)
    }

    private var helpText: String {
        if model.controller.isBoosting, let until = model.controller.boostUntil {
            return "Stop full blast (ends at \(until.formatted(date: .omitted, time: .shortened)))"
        }
        return "Full blast for \(Formatters.minutes(model.configuration.boostDuration)), then back to \(model.controller.mode.title)"
    }
}
