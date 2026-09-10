import SwiftUI

struct StatusBanner: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let error = model.controller.lastError {
            banner(symbol: "exclamationmark.triangle.fill", tint: .red, text: error) {
                Button("Dismiss") { model.controller.clearError() }
            }
        } else if !model.helper.isEnabled {
            banner(symbol: "lock.shield", tint: .blue, text: helperText) {
                Button(model.helper.status == .requiresApproval ? "Open Login Items" : "Install Helper") {
                    model.installHelper()
                }
            }
        }
    }

    private var helperText: String {
        switch model.helper.status {
        case .requiresApproval: "Approve MacFans Helper in System Settings › Login Items to enable fan control."
        default: "Fan control needs a small privileged helper. Reading sensors works without it."
        }
    }

    private func banner<Action: View>(symbol: String, tint: Color, text: String, @ViewBuilder action: () -> Action) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .font(.title3)
            Text(text)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            action()
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(tint.opacity(0.3)))
    }
}
