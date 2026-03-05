import SwiftUI

/// Main ribbon container: QAT + Tab Strip + Body.
/// Collapse/expand with double-click on tab strip.
struct RibbonView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    @State private var selectedTab: RibbonTab = .home
    @AppStorage("ribbonCollapsed") private var isCollapsed: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // QAT — always visible (28pt)
            QuickAccessToolbar(document: document)

            Divider()

            // Tab Strip — always visible (26pt)
            RibbonTabStrip(
                selectedTab: $selectedTab,
                fileType: document.fileType,
                hasConvertTargets: !document.fileType.convertibleTargets.isEmpty,
                onDoubleClick: { isCollapsed.toggle() }
            )

            // Body — collapsible (76pt)
            if !isCollapsed {
                Divider()

                RibbonBody(
                    selectedTab: selectedTab,
                    document: document,
                    lintEngine: lintEngine,
                    showLintPanel: $showLintPanel,
                    showPreview: $showPreview
                )
            }
        }
        .background(.bar)
        .animation(.easeInOut(duration: 0.15), value: isCollapsed)
    }
}
