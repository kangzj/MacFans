import ServiceManagement
import SwiftUI

struct HelperSettingsTab: View {
    @Environment(AppModel.self) private var model
    @State private var helperVersion: Int?

    var body: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    Label(model.helper.status.summary, systemImage: model.helper.isEnabled ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundStyle(model.helper.isEnabled ? .green : .secondary)
                }
                if let helperVersion {
                    LabeledContent("Protocol version", value: "\(helperVersion)")
                }
                if let error = model.helperInstallError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
            Section {
                HStack {
                    Button(model.helper.isEnabled ? "Reinstall" : "Install Helper") { model.installHelper() }
                    if model.helper.status == .requiresApproval {
                        Button("Open Login Items") { SMAppService.openSystemSettingsLoginItems() }
                    }
                    if model.helper.status != .notRegistered {
                        Button("Remove", role: .destructive) { Task { await model.removeHelper() } }
                    }
                    Spacer()
                    Button("Refresh") { model.helper.refreshStatus() }
                }
                Text("Fanwright installs a small root daemon that is the only component allowed to change fan speed. It clamps every request to the fan's hardware range and returns fans to Auto if the app stops responding for 10 seconds.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task(id: model.helper.status) {
            helperVersion = model.helper.isEnabled ? try? await model.helper.version() : nil
        }
    }
}
