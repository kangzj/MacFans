import SwiftUI

struct BoostButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            model.toggleBoost()
        } label: {
            Label(model.controller.isBoosting ? "Stop" : "Full Blast", systemImage: "wind")
        }
        .labelStyle(.titleAndIcon)
        .tint(model.controller.isBoosting ? .orange : nil)
        .disabled(!model.helper.isEnabled)
        .help(model.controller.isBoosting ? "Stop full blast and return to the current mode." : "Run every fan at maximum speed for five minutes, then return to the current mode.")
    }
}
