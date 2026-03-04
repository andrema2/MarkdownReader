import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    var goToLine: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document, lintEngine: lintEngine)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = MarkEditTextView.scrollableMarkEditTextView()
        guard let textView = scrollView.documentView as? MarkEditTextView else { return scrollView }

        // Delegate
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Load initial content
        textView.string = document.content

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? MarkEditTextView else { return }

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

        // Update error line highlights
        context.coordinator.updateErrorHighlights()

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

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        let document: DocumentModel
        let lintEngine: LintEngine
        weak var textView: MarkEditTextView?
        var isUpdatingFromTextView = false
        var lastGoToLine: Int?
        private var errorOverlays: [NSView] = []

        init(document: DocumentModel, lintEngine: LintEngine) {
            self.document = document
            self.lintEngine = lintEngine
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true
            document.updateContent(textView.string)
            textView.window?.isDocumentEdited = document.isDirty
            isUpdatingFromTextView = false
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = textView else { return }
            let cursorLine = currentLineNumber(in: textView)
            document.cursorLine = cursorLine
            document.cursorColumn = currentColumn(in: textView)

            // Find issue at cursor line
            let issueAtCursor = lintEngine.issues.first { $0.line == cursorLine }
            document.currentLineIssue = issueAtCursor
        }

        private func currentLineNumber(in textView: NSTextView) -> Int {
            let location = textView.selectedRange().location
            let string = textView.string as NSString
            let prefix = string.substring(to: min(location, string.length))
            return prefix.components(separatedBy: .newlines).count
        }

        private func currentColumn(in textView: NSTextView) -> Int {
            let location = textView.selectedRange().location
            let string = textView.string as NSString
            let lineRange = string.lineRange(for: NSRange(location: min(location, string.length), length: 0))
            return location - lineRange.location + 1
        }

        // MARK: - Error Line Highlights

        func updateErrorHighlights() {
            guard let textView else { return }

            // Remove old overlays
            for overlay in errorOverlays {
                overlay.removeFromSuperview()
            }
            errorOverlays.removeAll()

            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            let string = textView.string as NSString
            let errorLines = Set(lintEngine.issues.filter { $0.severity == .error }.map(\.line))
            let warningLines = Set(lintEngine.issues.filter { $0.severity == .warning }.map(\.line))
                .subtracting(errorLines) // errors take priority

            addHighlights(for: errorLines, color: NSColor.systemRed, string: string,
                         layoutManager: layoutManager, textContainer: textContainer, textView: textView)
            addHighlights(for: warningLines, color: NSColor.systemOrange, string: string,
                         layoutManager: layoutManager, textContainer: textContainer, textView: textView)
        }

        private func addHighlights(
            for lines: Set<Int>,
            color: NSColor,
            string: NSString,
            layoutManager: NSLayoutManager,
            textContainer: NSTextContainer,
            textView: NSTextView
        ) {
            var currentLine = 1
            string.enumerateSubstrings(
                in: NSRange(location: 0, length: string.length),
                options: [.byLines, .substringNotRequired]
            ) { _, range, _, stop in
                if currentLine > (lines.max() ?? 0) {
                    stop.pointee = true
                    return
                }
                if lines.contains(currentLine) {
                    let lineRange = string.lineRange(for: NSRange(location: range.location, length: 0))
                    let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
                    var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                    rect.origin.x = 0
                    rect.size.width = textView.bounds.width
                    rect = rect.offsetBy(dx: textView.textContainerInset.width, dy: textView.textContainerInset.height)

                    let overlay = NSView(frame: rect)
                    overlay.wantsLayer = true
                    overlay.layer?.backgroundColor = color.withAlphaComponent(0.08).cgColor

                    // Red/orange gutter mark
                    let gutter = NSView(frame: NSRect(x: 0, y: 0, width: 3, height: rect.height))
                    gutter.wantsLayer = true
                    gutter.layer?.backgroundColor = color.withAlphaComponent(0.6).cgColor
                    overlay.addSubview(gutter)

                    textView.addSubview(overlay, positioned: .below, relativeTo: nil)
                    self.errorOverlays.append(overlay)
                }
                currentLine += 1
            }
        }
    }
}

// MARK: - Custom NSTextView with ⌘K support

class MarkEditTextView: NSTextView {

    static func scrollableMarkEditTextView() -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = MarkEditTextView()

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
        textView.autoresizingMask = [.width, .height]

        // Insets
        textView.textContainerInset = NSSize(width: 8, height: 8)

        // Background
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor

        // Text container
        let textContainer = textView.textContainer!
        textContainer.widthTracksTextView = true
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        // Scroll view
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        return scrollView
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // ⌘K — Kill line from cursor to end of line
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k" {
            killLineFromCursor()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    private func killLineFromCursor() {
        let string = self.string as NSString
        let cursorLocation = selectedRange().location
        guard cursorLocation <= string.length else { return }

        let lineRange = string.lineRange(for: NSRange(location: cursorLocation, length: 0))
        let lineEnd = lineRange.location + lineRange.length

        // From cursor to end of line (including newline if at end)
        let killLength = lineEnd - cursorLocation
        guard killLength > 0 else { return }

        let killRange = NSRange(location: cursorLocation, length: killLength)

        // Use shouldChangeText for undo support
        if shouldChangeText(in: killRange, replacementString: "") {
            replaceCharacters(in: killRange, with: "")
            didChangeText()
        }
    }
}
