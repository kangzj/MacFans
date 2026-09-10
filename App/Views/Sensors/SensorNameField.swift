import SwiftUI

struct SensorNameField: View {
    let name: String
    let commit: (String) -> Void
    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Name", text: $draft)
            .textFieldStyle(.plain)
            .font(.body.weight(.medium))
            .focused($isFocused)
            .onAppear { draft = name }
            .onChange(of: name) { _, newName in if !isFocused { draft = newName } }
            .onSubmit { commit(draft) }
            .onChange(of: isFocused) { _, focused in if !focused { commit(draft) } }
    }
}
