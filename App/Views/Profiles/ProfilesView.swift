import MacFansCore
import SwiftUI

struct ProfilesView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedProfileID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            profileList
                .frame(width: 180)
            Divider()
            editor
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { selectedProfileID = selectedProfileID ?? model.configuration.activeProfileID }
    }

    private var profileList: some View {
        VStack(spacing: 0) {
            List(model.configuration.allProfiles, selection: $selectedProfileID) { profile in
                HStack {
                    Text(profile.name)
                    Spacer()
                    if profile.id == model.configuration.activeProfileID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .help("Active profile")
                    }
                    if model.configuration.isModifiedBuiltIn(id: profile.id) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.tertiary)
                            .help("Built-in profile with your changes. Reset to Default restores it.")
                    }
                }
                .tag(profile.id)
            }
            .listStyle(.inset)
            Divider()
            HStack(spacing: 4) {
                Button { addProfile() } label: { Image(systemName: "plus") }
                    .help("New profile")
                Button { duplicateSelected() } label: { Image(systemName: "plus.square.on.square") }
                    .disabled(selectedProfile == nil)
                    .help("Duplicate profile")
                Button { deleteSelected() } label: { Image(systemName: "minus") }
                    .disabled(!canDeleteSelected)
                    .help("Delete profile")
                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(6)
        }
    }

    @ViewBuilder
    private var editor: some View {
        if let profile = selectedProfile {
            ProfileEditor(profile: profile)
                .id(profile.id)
        } else {
            ContentUnavailableView("Select a Profile", systemImage: "slider.horizontal.3", description: Text("Profiles hold the rules Custom mode follows."))
        }
    }

    private var selectedProfile: Profile? {
        selectedProfileID.flatMap { model.configuration.profile(id: $0) }
    }

    private var canDeleteSelected: Bool {
        selectedProfileID.map { model.configuration.canDeleteProfile(id: $0) } ?? false
    }

    private func addProfile() {
        selectedProfileID = model.configuration.addProfile().id
    }

    private func duplicateSelected() {
        guard let id = selectedProfileID, let copy = model.configuration.duplicateProfile(id: id) else { return }
        selectedProfileID = copy.id
    }

    private func deleteSelected() {
        guard canDeleteSelected, let id = selectedProfileID else { return }
        model.configuration.deleteProfile(id: id)
        selectedProfileID = model.configuration.activeProfileID
    }
}
