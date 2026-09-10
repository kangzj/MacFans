import SwiftUI

struct SidebarCommands: Commands {
    @FocusedBinding(\.sidebarSelection) private var selection

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Divider()
            ForEach(Array(SidebarItem.allCases.enumerated()), id: \.element) { index, item in
                Button(item.title) { selection = item }
                    .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                    .disabled(selection == nil)
            }
        }
    }
}

private struct SidebarSelectionKey: FocusedValueKey {
    typealias Value = Binding<SidebarItem>
}

extension FocusedValues {
    var sidebarSelection: Binding<SidebarItem>? {
        get { self[SidebarSelectionKey.self] }
        set { self[SidebarSelectionKey.self] = newValue }
    }
}
