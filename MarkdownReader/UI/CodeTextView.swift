import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @ObservedObject var document: DocumentModel
    var goToLine: Int?

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
        if !context.coordinator.isUpdatingFromTextView {
            if textView.string != document.content {
                let selectedRanges = textView.selectedRanges
                textView.string = document.content
                textView.selectedRanges = selectedRanges
            }
        }

        // Update window isDocumentEdited
        textView.window?.isDocumentEdited = document.isDirty

        // Scroll to line if requested
        if let targetLine = goToLine, targetLine != context.coordinator.lastGoToLine {
            context.coordinator.lastGoToLine = targetLine
            scrollToLine(targetLine, in: textView)
        }
    }

    private func scrollToLine(_ line: Int, in textView: NSTextView) {
        let string = textView.string as NSString
        var currentLine = 1
        var lineStart = 0

        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length),
            options: [.byLines, .substringNotRequired]
        ) { _, range, _, stop in
            if currentLine == line {
                lineStart = range.location
                stop.pointee = true
                return
            }
            currentLine += 1
        }

        if currentLine >= line || line == 1 {
            let lineRange = string.lineRange(for: NSRange(location: lineStart, length: 0))

            // Select the line
            textView.setSelectedRange(lineRange)
            textView.scrollRangeToVisible(lineRange)

            // Flash highlight
            if let layoutManager = textView.layoutManager,
               let textContainer = textView.textContainer {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                rect.origin.x = 0
                rect.size.width = textView.bounds.width
                rect = rect.offsetBy(dx: textView.textContainerInset.width, dy: textView.textContainerInset.height)

                let highlight = NSView(frame: rect)
                highlight.wantsLayer = true
                highlight.layer?.backgroundColor = NSColor.systemYellow.withAlphaComponent(0.25).cgColor
                highlight.layer?.cornerRadius = 3
                textView.addSubview(highlight)

                NSAnimationContext.runAnimationGroup({ ctx in
                    ctx.duration = 1.5
                    highlight.animator().alphaValue = 0
                }, completionHandler: {
                    highlight.removeFromSuperview()
                })
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let document: DocumentModel
        weak var textView: NSTextView?
        var isUpdatingFromTextView = false
        var lastGoToLine: Int?

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
