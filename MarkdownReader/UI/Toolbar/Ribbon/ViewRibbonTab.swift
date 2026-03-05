import SwiftUI

/// View tab: Preview/Lint Panel toggles + New Tab/Close Tab.
struct ViewRibbonTab: View {
    @ObservedObject var lintEngine: LintEngine
    @Binding var showLintPanel: Bool
    @Binding var showPreview: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Layout
            RibbonGroup(label: "Layout") {
                RibbonLargeButton(
                    "Preview",
                    icon: showPreview ? "eye.fill" : "eye.slash",
                    active: showPreview
                ) {
                    showPreview.toggle()
                }
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        RibbonSmallButton(
                            "Lint Panel",
                            icon: lintIcon
                        ) {
                            showLintPanel.toggle()
                        }
                        if lintEngine.issues.count > 0 {
                            Text("\(lintEngine.issues.count)")
                                .font(.system(size: 9, weight: .bold))
                                .monospacedDigit()
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            RibbonGroupSeparator()

            // Window
            RibbonGroup(label: "Window") {
                RibbonLargeButton("New Tab", icon: "plus.square") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                VStack(spacing: 4) {
                    RibbonSmallButton("Close Tab", icon: "xmark.square") {
                        NotificationCenter.default.post(name: .closeTab, object: nil)
                    }
                }
            }
        }
    }

    private var lintIcon: String {
        if lintEngine.isRunning { return "arrow.triangle.2.circlepath" }
        if lintEngine.issues.isEmpty { return "checkmark.circle" }
        let hasErrors = lintEngine.issues.contains { $0.severity == .error }
        return hasErrors ? "xmark.circle" : "exclamationmark.triangle"
    }
}
