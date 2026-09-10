import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case overview, fans, sensors, profiles, history

    var id: SidebarItem { self }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .fans: "Fans"
        case .sensors: "Sensors"
        case .profiles: "Profiles"
        case .history: "History"
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "gauge.with.dots.needle.33percent"
        case .fans: "fanblades"
        case .sensors: "thermometer.medium"
        case .profiles: "slider.horizontal.3"
        case .history: "clock.arrow.circlepath"
        }
    }
}

struct SidebarSelectionKey: FocusedValueKey {
    typealias Value = Binding<SidebarItem>
}

extension FocusedValues {
    var sidebarSelection: Binding<SidebarItem>? {
        get { self[SidebarSelectionKey.self] }
        set { self[SidebarSelectionKey.self] = newValue }
    }
}

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

struct MainWindow: View {
    static let id = "dashboard"

    @Environment(AppModel.self) private var model
    @State private var selection: SidebarItem = .overview
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.symbolName)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            VStack(spacing: 0) {
                StatusBanner()
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                detail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle(selection.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if model.controller.mode == .custom {
                        ProfilePicker()
                            .labelsHidden()
                    }
                    ControlModePicker()
                }
            }
        }
        .frame(minWidth: 800, idealWidth: 860, maxWidth: .infinity, minHeight: 360, idealHeight: 370, maxHeight: .infinity)
        .navigationSplitViewStyle(.balanced)
        .focusedSceneValue(\.sidebarSelection, $selection)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .overview: OverviewView()
        case .fans: FansView()
        case .sensors: SensorsView()
        case .profiles: ProfilesView()
        case .history: HistoryView()
        }
    }
}
