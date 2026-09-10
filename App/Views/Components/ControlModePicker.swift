import MacFansCore
import SwiftUI

struct ControlModePicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Picker("Mode", selection: Binding(
            get: { model.controller.mode },
            set: { model.setMode($0) }
        )) {
            ForEach(ControlMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .help("Auto lets macOS drive the fans. Constant holds fixed speeds. Custom follows the active profile's rules.")
    }
}
