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

struct ProfilePicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Picker("Profile", selection: Binding(
            get: { model.configuration.activeProfileID },
            set: { model.activateProfile($0) }
        )) {
            ForEach(model.configuration.allProfiles) { profile in
                Text(profile.name).tag(profile.id)
            }
        }
    }
}

extension ControlMode {
    var title: String {
        switch self {
        case .auto: "Auto"
        case .constant: "Constant"
        case .custom: "Custom"
        }
    }

    var symbolName: String {
        switch self {
        case .auto: "wand.and.sparkles"
        case .constant: "dial.medium"
        case .custom: "slider.horizontal.3"
        }
    }
}
