import SwiftUI

/// Routes the selected ribbon tab to its content view (76pt height).
struct RibbonBody: View {
    let selectedTab: RibbonTab
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    var body: some View {
        HStack(spacing: 0) {
            switch selectedTab {
            case .home:
                HomeRibbonTab(document: document)
            case .insert:
                InsertRibbonTab(document: document)
            case .view:
                ViewRibbonTab(
                    lintEngine: lintEngine,
                    showLintPanel: $showLintPanel,
                    showPreview: $showPreview
                )
            case .fileType:
                FileTypeRibbonTab(document: document)
            case .convert:
                ConvertRibbonTab(document: document)
            }
            Spacer()
        }
        .frame(height: 76)
        .padding(.horizontal, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}
