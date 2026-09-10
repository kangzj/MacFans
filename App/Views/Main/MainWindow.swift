import SwiftUI

struct MainWindow: View {
    static let id = "fanwright.main"

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
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                detail
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(nsColor: .windowBackgroundColor).ignoresSafeArea())
            .navigationTitle(selection.title)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if model.controller.mode == .custom {
                        ProfilePicker()
                            .labelsHidden()
                    }
                    ControlModePicker()
                    BoostButton()
                }
            }
        }
        .modifier(MainWindowSizing(selection: selection, bannerVisible: isBannerVisible))
        .navigationSplitViewStyle(.balanced)
        .focusedSceneValue(\.sidebarSelection, $selection)
    }

    private var isBannerVisible: Bool {
        model.controller.lastError != nil || !model.helper.isEnabled
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
