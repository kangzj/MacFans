import AppKit
import SwiftUI

struct MainWindowSizing: ViewModifier {
    private static let trendHeight: CGFloat = 42
    private static let overviewCollapsedHeight: CGFloat = 332
    private static let defaultMinimumHeight: CGFloat = 320
    private static let bannerHeight: CGFloat = 72

    let selection: SidebarItem
    let bannerVisible: Bool
    @AppStorage(OverviewView.trendsExpandedKey) private var trendsExpanded = false
    @State private var window: NSWindow?

    func body(content: Content) -> some View {
        content
            .frame(minWidth: 800, idealWidth: 860, maxWidth: .infinity, minHeight: minimumHeight, maxHeight: .infinity)
            .background(WindowAccessor { window = $0 })
            .onChange(of: trendsExpanded) { _, expanded in
                if selection == .overview, !expanded { shrinkWindow(by: Self.trendHeight) }
            }
    }

    private var minimumHeight: CGFloat {
        guard selection == .overview else { return Self.defaultMinimumHeight }
        return Self.overviewCollapsedHeight + (trendsExpanded ? Self.trendHeight : 0) + (bannerVisible ? Self.bannerHeight : 0)
    }

    // SwiftUI grows the window when the minimum height rises but never shrinks it back, so collapsing is explicit.
    private func shrinkWindow(by height: CGFloat) {
        guard let window else { return }
        var frame = window.frame
        frame.size.height -= height
        frame.origin.y += height
        window.setFrame(frame, display: true, animate: true)
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { if let window = view.window { onWindow(window) } }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { onWindow(window) }
    }
}
