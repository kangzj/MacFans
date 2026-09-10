import MacFansCore
import SwiftUI

struct ProfilesView: View {
    @Environment(AppModel.self) private var model
    @State private var selectedProfileID: UUID?
    @State private var showDuplicatePrompt = false

    var body: some View {
        HSplitView {
            profileList
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 280)
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
                    if profile.isBuiltIn {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.tertiary)
                            .help("Built-in profiles can be duplicated but not edited.")
                    }
                }
                .tag(profile.id)
            }
            .listStyle(.sidebar)
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
            ProfileEditor(profile: profile, isEditable: !profile.isBuiltIn, onDuplicate: duplicateSelected)
                .id(profile.id)
        } else {
            ContentUnavailableView("Select a Profile", systemImage: "slider.horizontal.3", description: Text("Profiles hold the rules Custom mode follows."))
        }
    }

    private var selectedProfile: Profile? {
        selectedProfileID.flatMap { model.configuration.profile(id: $0) }
    }

    private var canDeleteSelected: Bool {
        guard let profile = selectedProfile else { return false }
        return !profile.isBuiltIn && profile.id != model.configuration.activeProfileID
    }

    private func addProfile() {
        let profile = Profile(id: UUID(), name: uniqueName("New Profile"), rules: [], isBuiltIn: false)
        model.configuration.profiles.append(profile)
        selectedProfileID = profile.id
    }

    private func duplicateSelected() {
        guard let source = selectedProfile else { return }
        let copy = Profile(
            id: UUID(),
            name: uniqueName("\(source.name) Copy"),
            rules: source.rules.map { rule in
                var rule = rule
                rule.id = UUID()
                return rule
            },
            isBuiltIn: false
        )
        model.configuration.profiles.append(copy)
        selectedProfileID = copy.id
    }

    private func deleteSelected() {
        guard canDeleteSelected, let id = selectedProfileID else { return }
        model.configuration.profiles.removeAll { $0.id == id }
        selectedProfileID = model.configuration.activeProfileID
    }

    private func uniqueName(_ base: String) -> String {
        let names = Set(model.configuration.allProfiles.map(\.name))
        guard names.contains(base) else { return base }
        return (2...).lazy.map { "\(base) \($0)" }.first { !names.contains($0) } ?? base
    }
}

private struct ProfileEditor: View {
    @Environment(AppModel.self) private var model
    let profile: Profile
    let isEditable: Bool
    let onDuplicate: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if profile.rules.isEmpty {
                    ContentUnavailableView("No Rules", systemImage: "list.bullet.rectangle", description: Text("Add a rule to spin fans up when a sensor gets hot."))
                        .frame(height: 200)
                } else {
                    ForEach(profile.rules) { rule in
                        RuleEditorView(rule: ruleBinding(rule), profile: profile, isEditable: isEditable, onDelete: { removeRule(rule) })
                    }
                }
                if isEditable {
                    Button { addRule() } label: { Label("Add Rule", systemImage: "plus") }
                }
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TextField("Profile name", text: nameBinding)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .disabled(!isEditable)
                .frame(maxWidth: 320)
            Spacer()
            if !isEditable {
                Button("Duplicate to Edit", action: onDuplicate)
            }
            if profile.id == model.configuration.activeProfileID {
                Label("Active", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Activate") {
                    model.activateProfile(profile.id)
                    if model.controller.mode != .custom { model.setMode(.custom) }
                }
                .disabled(!profile.rules.allSatisfy(\.isValid))
                .help("Activates this profile and switches to Custom mode.")
            }
        }
    }

    private var nameBinding: Binding<String> {
        Binding(get: { profile.name }, set: { name in update { $0.name = name } })
    }

    private func ruleBinding(_ rule: Rule) -> Binding<Rule> {
        Binding(
            get: { model.configuration.profile(id: profile.id)?.rules.first { $0.id == rule.id } ?? rule },
            set: { newRule in
                update { profile in
                    if let index = profile.rules.firstIndex(where: { $0.id == rule.id }) { profile.rules[index] = newRule }
                }
            }
        )
    }

    private func addRule() {
        let rule = Rule(name: "Rule \(profile.rules.count + 1)", trigger: .group(.cpu, .max), onAbove: 80, speed: .percent(60))
        update { $0.rules.append(rule) }
    }

    private func removeRule(_ rule: Rule) {
        update { $0.rules.removeAll { $0.id == rule.id } }
    }

    private func update(_ change: (inout Profile) -> Void) {
        guard let index = model.configuration.profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        change(&model.configuration.profiles[index])
        if profile.id == model.configuration.activeProfileID { model.controller.resetEngine() }
    }
}
