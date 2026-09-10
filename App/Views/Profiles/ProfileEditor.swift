import MacFansCore
import SwiftUI

struct ProfileEditor: View {
    @Environment(AppModel.self) private var model
    let profile: Profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if profile.rules.isEmpty {
                    ContentUnavailableView("No Rules", systemImage: "list.bullet.rectangle", description: Text("Add a rule to spin fans up when a sensor gets hot."))
                        .frame(height: 200)
                } else {
                    ForEach(profile.rules) { rule in
                        RuleEditorView(rule: ruleBinding(rule), profileID: profile.id, onDelete: { removeRule(rule) })
                    }
                }
                Button { addRule() } label: { Label("Add Rule", systemImage: "plus") }
            }
            .padding(20)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            TextField("Profile name", text: nameBinding)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .frame(maxWidth: 320)
            Spacer()
            if model.configuration.isModifiedBuiltIn(id: profile.id) {
                Button("Reset to Default") { model.configuration.resetBuiltInProfile(id: profile.id) }
                    .help("Discard your changes and restore the built-in rules.")
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
        let rule = Rule(name: "Rule \(profile.rules.count + 1)", trigger: .group(.cpu, .max), onAbove: 80, speed: .percent(RuleSpeedPicker.defaultPercent))
        update { $0.rules.append(rule) }
    }

    private func removeRule(_ rule: Rule) {
        update { $0.rules.removeAll { $0.id == rule.id } }
    }

    private func update(_ change: (inout Profile) -> Void) {
        model.configuration.updateProfile(id: profile.id, change)
    }
}
