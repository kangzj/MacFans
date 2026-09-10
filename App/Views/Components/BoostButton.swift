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
        .help(model.controlStatus.boostButtonHelp(duration: model.configuration.boostDuration))
    }
}
