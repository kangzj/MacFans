import SwiftUI

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
