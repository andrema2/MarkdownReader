import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @ObservedObject var document: DocumentModel

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        // Font
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .textColor

        // Layout
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true

        // Text container fills width, wraps
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]

        // Insets
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Background
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor

        // Delegate
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Load initial content
        textView.string = document.content

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Only update if content changed externally (file load, new doc)
        if context.coordinator.isUpdatingFromTextView { return }

        if textView.string != document.content {
            let selectedRanges = textView.selectedRanges
            textView.string = document.content
            textView.selectedRanges = selectedRanges
        }

        // Update window isDocumentEdited
        textView.window?.isDocumentEdited = document.isDirty
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let document: DocumentModel
        weak var textView: NSTextView?
        var isUpdatingFromTextView = false

        init(document: DocumentModel) {
            self.document = document
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true
            document.updateContent(textView.string)
            textView.window?.isDocumentEdited = document.isDirty
            isUpdatingFromTextView = false
        }
    }
}
