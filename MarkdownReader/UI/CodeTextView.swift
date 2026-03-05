import SwiftUI
import AppKit

struct CodeTextView: NSViewRepresentable {
    @ObservedObject var document: DocumentModel
    @ObservedObject var lintEngine: LintEngine
    var goToLine: Int?
    @ObservedObject var findEngine: FindReplaceEngine
    @ObservedObject var foldingEngine: FoldingEngine
    @ObservedObject var diffEngine: DiffEngine
    @ObservedObject var bookmarkEngine: BookmarkEngine

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document, lintEngine: lintEngine, findEngine: findEngine, foldingEngine: foldingEngine, bookmarkEngine: bookmarkEngine)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = MarkEditTextView.scrollableMarkEditTextView()
        guard let textView = scrollView.documentView as? MarkEditTextView else { return scrollView }

        // Delegate
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Load initial content
        textView.string = document.content

        // Fold gutter setup
        let foldLayoutDelegate = FoldLayoutManagerDelegate()
        foldLayoutDelegate.foldingEngine = foldingEngine
        textView.layoutManager?.delegate = foldLayoutDelegate
        context.coordinator.foldLayoutDelegate = foldLayoutDelegate

        let foldGutter = FoldGutterView(scrollView: scrollView, orientation: .verticalRuler)
        foldGutter.foldingEngine = foldingEngine
        foldGutter.clientView = textView
        scrollView.verticalRulerView = foldGutter
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        context.coordinator.foldGutter = foldGutter

        // Wire engines into the combined gutter
        foldGutter.lintEngine = lintEngine
        foldGutter.diffEngine = diffEngine
        foldGutter.bookmarkEngine = bookmarkEngine

        // Word wrap initial state
        Self.applyWordWrap(enabled: document.wordWrapEnabled, textView: textView, scrollView: scrollView)

        // Initial fold parse
        foldingEngine.parse(content: document.content, fileType: document.fileExtension)
        if let lm = textView.layoutManager {
            foldLayoutDelegate.updateHiddenRanges(from: foldingEngine, string: textView.string as NSString)
            lm.invalidateLayout(forCharacterRange: NSRange(location: 0, length: (textView.string as NSString).length), actualCharacterRange: nil)
        }

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

                // Re-parse fold regions on external content load
                foldingEngine.parse(content: document.content, fileType: document.fileExtension)
                if let lm = textView.layoutManager, let fld = context.coordinator.foldLayoutDelegate {
                    fld.updateHiddenRanges(from: foldingEngine, string: textView.string as NSString)
                    lm.invalidateLayout(forCharacterRange: NSRange(location: 0, length: (textView.string as NSString).length), actualCharacterRange: nil)
                }
                context.coordinator.foldGutter?.needsDisplay = true
            }
        }

        // Update window isDocumentEdited
        textView.window?.isDocumentEdited = document.isDirty

        // Update error line highlights
        context.coordinator.updateErrorHighlights()

        // Update search highlights
        if findEngine.needsSearch {
            findEngine.search(in: document.content)
        }
        context.coordinator.updateSearchHighlights(
            matches: findEngine.matches,
            currentIndex: findEngine.currentMatchIndex
        )

        // Word wrap toggle
        Self.applyWordWrap(enabled: document.wordWrapEnabled, textView: textView, scrollView: scrollView)

        // Redraw gutter (line numbers, fold triangles, issue dots)
        context.coordinator.foldGutter?.needsDisplay = true

        // Scroll to line if requested
        if let targetLine = goToLine, targetLine != context.coordinator.lastGoToLine {
            context.coordinator.lastGoToLine = targetLine
            scrollToLine(targetLine, in: textView)
        }
    }

    static func applyWordWrap(enabled: Bool, textView: NSTextView, scrollView: NSScrollView) {
        if enabled {
            textView.isHorizontallyResizable = false
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = false
        } else {
            textView.isHorizontallyResizable = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            scrollView.hasHorizontalScroller = true
        }
        textView.needsLayout = true
        textView.needsDisplay = true
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
                // HIG: Use findHighlightColor for go-to-line flash — consistent with system Find
                highlight.layer?.backgroundColor = NSColor.findHighlightColor.withAlphaComponent(0.5).cgColor
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
        let findEngine: FindReplaceEngine
        let foldingEngine: FoldingEngine
        let bookmarkEngine: BookmarkEngine
        weak var textView: MarkEditTextView?
        var isUpdatingFromTextView = false
        var lastGoToLine: Int?
        private var errorOverlays: [NSView] = []
        private var searchOverlays: [NSView] = []
        private var bracketOverlays: [NSView] = []
        private var lastSearchMatches: [NSRange] = []
        private var lastSearchCurrentIndex: Int = -1

        // Folding & gutter references
        var foldLayoutDelegate: FoldLayoutManagerDelegate?
        var foldGutter: FoldGutterView?
        weak var lineNumberGutter: LineNumberGutterView?  // kept for potential external access

        init(document: DocumentModel, lintEngine: LintEngine, findEngine: FindReplaceEngine, foldingEngine: FoldingEngine, bookmarkEngine: BookmarkEngine) {
            self.document = document
            self.lintEngine = lintEngine
            self.findEngine = findEngine
            self.foldingEngine = foldingEngine
            self.bookmarkEngine = bookmarkEngine
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true
            document.updateContent(textView.string)
            textView.window?.isDocumentEdited = document.isDirty
            isUpdatingFromTextView = false

            // Re-run search on content change
            if !findEngine.searchText.isEmpty {
                findEngine.search(in: textView.string)
            }

            // Re-parse fold regions
            foldingEngine.parse(content: textView.string, fileType: document.fileExtension)
            if let lm = textView.layoutManager, let fld = foldLayoutDelegate {
                fld.updateHiddenRanges(from: foldingEngine, string: textView.string as NSString)
                lm.invalidateLayout(forCharacterRange: NSRange(location: 0, length: (textView.string as NSString).length), actualCharacterRange: nil)
            }
            foldGutter?.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = textView else { return }
            let cursorLine = currentLineNumber(in: textView)
            document.cursorLine = cursorLine
            document.cursorColumn = currentColumn(in: textView)

            // Publish column selection info if active
            if let colSel = textView.columnSelection {
                document.columnSelectionInfo = ColumnSelectionInfo(
                    lineRange: colSel.lineRange,
                    columnRange: colSel.columnRange
                )
            } else {
                document.columnSelectionInfo = nil
            }

            // Find issue at cursor line
            let issueAtCursor = lintEngine.issues.first { $0.line == cursorLine }
            document.currentLineIssue = issueAtCursor

            // Bracket matching
            updateBracketMatching(in: textView)
        }

        // MARK: - Bracket Matching

        private func updateBracketMatching(in textView: MarkEditTextView) {
            // Remove old bracket overlays
            for overlay in bracketOverlays {
                overlay.removeFromSuperview()
            }
            bracketOverlays.removeAll()
            document.matchingBracketRange = nil

            let string = textView.string as NSString
            let location = textView.selectedRange().location
            guard string.length > 0 else { return }

            // Check character at cursor and before cursor
            guard let matchRange = BracketMatcher.findMatch(in: string, at: min(location, string.length - 1)) else { return }

            document.matchingBracketRange = matchRange

            // Draw highlight overlay for the matching bracket
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            let glyphRange = layoutManager.glyphRange(forCharacterRange: matchRange, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect = rect.offsetBy(dx: textView.textContainerInset.width, dy: textView.textContainerInset.height)
            // Slight expansion for visibility
            rect = rect.insetBy(dx: -1, dy: -1)

            let overlay = NSView(frame: rect)
            overlay.wantsLayer = true
            // HIG: Use controlAccentColor to respect the user's system accent color preference
            overlay.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            overlay.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
            overlay.layer?.borderWidth = 1
            overlay.layer?.cornerRadius = 2

            textView.addSubview(overlay, positioned: .below, relativeTo: nil)
            bracketOverlays.append(overlay)

            // Also highlight the bracket under cursor
            let cursorCharIdx = min(location, string.length - 1)
            let cursorChar = Character(UnicodeScalar(string.character(at: cursorCharIdx))!)
            let isBracketChar = BracketMatcher.openToClose[cursorChar] != nil ||
                                BracketMatcher.closeToOpen[cursorChar] != nil ||
                                BracketMatcher.quotes.contains(cursorChar)

            let bracketLocation = isBracketChar ? cursorCharIdx : (location > 0 ? location - 1 : cursorCharIdx)
            let cursorBracketRange = NSRange(location: bracketLocation, length: 1)

            if cursorBracketRange.location < string.length {
                let cursorGlyphRange = layoutManager.glyphRange(forCharacterRange: cursorBracketRange, actualCharacterRange: nil)
                var cursorRect = layoutManager.boundingRect(forGlyphRange: cursorGlyphRange, in: textContainer)
                cursorRect = cursorRect.offsetBy(dx: textView.textContainerInset.width, dy: textView.textContainerInset.height)
                cursorRect = cursorRect.insetBy(dx: -1, dy: -1)

                let cursorOverlay = NSView(frame: cursorRect)
                cursorOverlay.wantsLayer = true
                // HIG: Consistent accent color for both bracket highlights
                cursorOverlay.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
                cursorOverlay.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
                cursorOverlay.layer?.borderWidth = 1
                cursorOverlay.layer?.cornerRadius = 2

                textView.addSubview(cursorOverlay, positioned: .below, relativeTo: nil)
                bracketOverlays.append(cursorOverlay)
            }
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
                    // HIG: Subtle background tint with semantic error/warning colors
                    overlay.layer?.backgroundColor = color.withAlphaComponent(0.06).cgColor

                    // Left edge indicator bar
                    let gutter = NSView(frame: NSRect(x: 0, y: 0, width: 2.5, height: rect.height))
                    gutter.wantsLayer = true
                    gutter.layer?.backgroundColor = color.cgColor
                    overlay.addSubview(gutter)

                    textView.addSubview(overlay, positioned: .below, relativeTo: nil)
                    self.errorOverlays.append(overlay)
                }
                currentLine += 1
            }
        }

        // MARK: - Search Highlights

        func updateSearchHighlights(matches: [NSRange], currentIndex: Int) {
            // Skip if nothing changed
            if matches == lastSearchMatches && currentIndex == lastSearchCurrentIndex {
                return
            }
            lastSearchMatches = matches
            lastSearchCurrentIndex = currentIndex

            guard let textView else { return }

            // Remove old search overlays
            for overlay in searchOverlays {
                overlay.removeFromSuperview()
            }
            searchOverlays.removeAll()

            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            for (index, range) in matches.enumerated() {
                let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                rect = rect.offsetBy(dx: textView.textContainerInset.width, dy: textView.textContainerInset.height)

                // HIG: Use findHighlightColor for standard find highlights, accent for current match
                let isCurrent = index == currentIndex
                let overlay = NSView(frame: rect)
                overlay.wantsLayer = true
                overlay.layer?.backgroundColor = isCurrent
                    ? NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
                    : NSColor.findHighlightColor.withAlphaComponent(0.6).cgColor
                overlay.layer?.cornerRadius = 2

                textView.addSubview(overlay, positioned: .below, relativeTo: nil)
                searchOverlays.append(overlay)
            }

            // Auto-unfold and scroll to current match
            if currentIndex >= 0 && currentIndex < matches.count {
                let range = matches[currentIndex]

                // Auto-unfold any folded region containing this match
                let matchLine = lineNumber(for: range.location, in: textView)
                let hadFolds = !foldingEngine.foldedRegionIDs.isEmpty
                foldingEngine.unfoldRegionsContaining(line: matchLine)
                if hadFolds && foldingEngine.foldedRegionIDs.count < (hadFolds ? Int.max : 0) {
                    if let lm = textView.layoutManager, let fld = foldLayoutDelegate {
                        fld.updateHiddenRanges(from: foldingEngine, string: textView.string as NSString)
                        lm.invalidateLayout(forCharacterRange: NSRange(location: 0, length: (textView.string as NSString).length), actualCharacterRange: nil)
                    }
                    foldGutter?.needsDisplay = true
                }

                textView.scrollRangeToVisible(range)
            }
        }

        /// Returns the 1-based line number for a character location.
        private func lineNumber(for location: Int, in textView: NSTextView) -> Int {
            let string = textView.string as NSString
            let prefix = string.substring(to: min(location, string.length))
            return prefix.components(separatedBy: .newlines).count
        }
    }
}

// MARK: - Custom NSTextView

class MarkEditTextView: NSTextView {

    // MARK: - Column Selection

    var columnSelection: ColumnSelectionState?
    var isColumnSelecting = false
    lazy var monoCharWidth: CGFloat = {
        let font = self.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return NSAttributedString(string: "M", attributes: attributes).size().width
    }()

    override func mouseDown(with event: NSEvent) {
        // Option+click starts column selection
        if event.modifierFlags.contains(.option) {
            guard let layoutManager = layoutManager, let textContainer = textContainer else {
                super.mouseDown(with: event)
                return
            }
            let point = convert(event.locationInWindow, from: nil)
            let pos = ColumnSelectionHelper.lineAndColumn(
                for: point, in: self, layoutManager: layoutManager,
                textContainer: textContainer, charWidth: monoCharWidth
            )
            columnSelection = ColumnSelectionState(
                anchorLine: pos.line, anchorColumn: pos.column,
                activeLine: pos.line, activeColumn: pos.column
            )
            isColumnSelecting = true
            return
        }

        // Normal click clears column selection
        columnSelection = nil
        isColumnSelecting = false
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isColumnSelecting,
              let layoutManager = layoutManager,
              let textContainer = textContainer else {
            super.mouseDragged(with: event)
            return
        }

        let point = convert(event.locationInWindow, from: nil)
        let pos = ColumnSelectionHelper.lineAndColumn(
            for: point, in: self, layoutManager: layoutManager,
            textContainer: textContainer, charWidth: monoCharWidth
        )
        columnSelection?.activeLine = pos.line
        columnSelection?.activeColumn = pos.column

        // Compute and apply rectangular selection ranges
        if let state = columnSelection {
            let ranges = ColumnSelectionHelper.ranges(for: state, in: string as NSString)
            let nsRanges = ranges.map { NSValue(range: $0) }
            if !nsRanges.isEmpty {
                setSelectedRanges(nsRanges, affinity: .downstream, stillSelecting: true)
            }
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard isColumnSelecting else {
            super.mouseUp(with: event)
            return
        }

        isColumnSelecting = false

        // Finalize selection
        if let state = columnSelection {
            let ranges = ColumnSelectionHelper.ranges(for: state, in: string as NSString)
            let nsRanges = ranges.map { NSValue(range: $0) }
            if !nsRanges.isEmpty {
                setSelectedRanges(nsRanges, affinity: .downstream, stillSelecting: false)
            }
        }
    }

    override func copy(_ sender: Any?) {
        // When column selection is active, build rectangular block text
        if let state = columnSelection {
            let nsString = string as NSString
            let ranges = ColumnSelectionHelper.ranges(for: state, in: nsString)
            let lines = ranges.map { nsString.substring(with: $0) }
            let blockText = lines.joined(separator: "\n")
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(blockText, forType: .string)
            return
        }
        super.copy(sender)
    }

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
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // ⌘K — Kill line from cursor to end of line
        if flags == .command && event.charactersIgnoringModifiers == "k" {
            killLineFromCursor()
            return true
        }
        // ⌘F — Find
        if flags == .command && event.charactersIgnoringModifiers == "f" {
            NotificationCenter.default.post(name: .toggleFind, object: nil)
            return true
        }
        // ⌘H — Find and Replace
        if flags == .command && event.charactersIgnoringModifiers == "h" {
            NotificationCenter.default.post(name: .toggleFindReplace, object: nil)
            return true
        }
        // F2 key = keyCode 120
        if event.keyCode == 120 {
            if flags == .command {
                // ⌘F2 — Toggle bookmark
                NotificationCenter.default.post(name: .toggleBookmark, object: nil)
                return true
            } else if flags == [.shift] {
                // Shift+F2 — Previous bookmark
                NotificationCenter.default.post(name: .previousBookmark, object: nil)
                return true
            } else if flags.isEmpty || flags == [.function] {
                // F2 — Next bookmark
                NotificationCenter.default.post(name: .nextBookmark, object: nil)
                return true
            }
        }
        // ⌘D — Show diff with disk
        if flags == .command && event.charactersIgnoringModifiers == "d" {
            NotificationCenter.default.post(name: .showDiff, object: nil)
            return true
        }
        // Esc — Close find panel
        if event.keyCode == 53 {
            NotificationCenter.default.post(name: .closeFindPanel, object: nil)
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
