import SwiftUI

struct ToolbarView: View {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    var body: some View {
        RibbonView(
            document: document,
            lintEngine: lintEngine,
            showLintPanel: $showLintPanel,
            showPreview: $showPreview
        )
    }
}
