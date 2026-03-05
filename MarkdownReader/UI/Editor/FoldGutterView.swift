import AppKit

/// NSRulerView subclass that draws line numbers, fold disclosure triangles,
/// diff indicators, bookmark markers, and error/warning dots in a combined gutter.
///
/// Layout (left to right within 56pt):
///   [0-3]   Diff change indicator bar
///   [3-10]  Bookmark diamond / error dot / warning dot
///   [10-40] Right-aligned line number
///   [42-56] Fold disclosure triangle
class FoldGutterView: NSRulerView {
    weak var foldingEngine: FoldingEngine?
    weak var lintEngine: LintEngine?
    weak var diffEngine: DiffEngine?
    weak var bookmarkEngine: BookmarkEngine?
    weak var lineNumberGutter: LineNumberGutterView?

    private let triangleSize: CGFloat = 10

    // HIG: Use system monospaced digit font at standard small size
    private let lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    private let currentLineFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)

    override var requiredThickness: CGFloat { 56 }

    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation: orientation)
        ruleThickness = 56
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let scrollView = scrollView,
              let textView = scrollView.documentView as? NSTextView,
              let layoutManager = textView.layoutManager else { return }

        let string = textView.string as NSString
        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height
        let rulerOffset = convert(NSPoint.zero, from: scrollView.contentView).y

        // HIG: Use windowBackgroundColor for gutter — adapts to light/dark mode
        NSColor.windowBackgroundColor.setFill()
        rect.fill()

        // HIG: Use separatorColor at 1pt for crisp retina-safe line
        NSColor.separatorColor.setStroke()
        let sep = NSBezierPath()
        sep.move(to: NSPoint(x: bounds.maxX - 0.5, y: rect.minY))
        sep.line(to: NSPoint(x: bounds.maxX - 0.5, y: rect.maxY))
        sep.lineWidth = 1
        sep.stroke()

        // Current cursor line
        let cursorLocation = textView.selectedRange().location
        let cursorPrefix = string.substring(to: min(cursorLocation, string.length))
        let currentCursorLine = cursorPrefix.components(separatedBy: .newlines).count

        // Lint issue lines
        var errorLines = Set<Int>()
        var warningLines = Set<Int>()
        if let engine = lintEngine {
            for issue in engine.issues {
                switch issue.severity {
                case .error: errorLines.insert(issue.line)
                case .warning: warningLines.insert(issue.line)
                case .info: break
                }
            }
        }

        // Fold region lookup by start line
        var foldRegionAtLine: [Int: FoldRegion] = [:]
        if let engine = foldingEngine {
            for region in engine.regions {
                foldRegionAtLine[region.startLine] = region
            }
        }

        // Diff hunks
        let hunks = diffEngine?.hunks ?? []

        // Enumerate visible lines
        var lineNumber = 1
        var glyphIndex = 0
        let totalGlyphs = layoutManager.numberOfGlyphs

        while glyphIndex < totalGlyphs {
            var effectiveGlyphRange = NSRange(location: 0, length: 0)
            let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveGlyphRange)

            if lineFragmentRect.height == 0 {
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                if charIndex == 0 || (charIndex > 0 && (string.character(at: charIndex - 1) == 0x0A || string.character(at: charIndex - 1) == 0x0D)) {
                    lineNumber += 1
                }
                glyphIndex = NSMaxRange(effectiveGlyphRange)
                continue
            }

            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let isFirstFragment = charIndex == 0 || (charIndex > 0 && (string.character(at: charIndex - 1) == 0x0A || string.character(at: charIndex - 1) == 0x0D))

            if isFirstFragment {
                let lineY = lineFragmentRect.origin.y + insetY
                let yInRuler = lineY - visibleRect.origin.y + rulerOffset

                if yInRuler + lineFragmentRect.height >= rect.minY && yInRuler <= rect.maxY {
                    let isCurrent = lineNumber == currentCursorLine
                    let lineHeight = lineFragmentRect.height

                    // Current line subtle background highlight
                    if isCurrent {
                        NSColor.labelColor.withAlphaComponent(0.04).setFill()
                        NSRect(x: 0, y: yInRuler, width: bounds.width, height: lineHeight).fill()
                    }

                    // 1. Diff indicator bar (x: 0-3)
                    drawDiffIndicator(hunks: hunks, lineNumber: lineNumber, at: yInRuler, lineHeight: lineHeight)

                    // 2. Bookmark / error / warning indicator (x: 3-10)
                    if let bEngine = bookmarkEngine, bEngine.isBookmarked(lineNumber) {
                        drawBookmarkMarker(at: yInRuler, lineHeight: lineHeight)
                    } else if errorLines.contains(lineNumber) {
                        drawIssueDot(at: yInRuler, lineHeight: lineHeight, isError: true)
                    } else if warningLines.contains(lineNumber) {
                        drawIssueDot(at: yInRuler, lineHeight: lineHeight, isError: false)
                    }

                    // 3. Line number (x: 10-40)
                    // HIG: Use secondaryLabelColor for non-current, labelColor + medium weight for current
                    let font = isCurrent ? currentLineFont : lineNumberFont
                    let color: NSColor = isCurrent ? .labelColor : .tertiaryLabelColor
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let numStr = "\(lineNumber)" as NSString
                    let size = numStr.size(withAttributes: attrs)
                    let x = 38 - size.width
                    let y = yInRuler + (lineHeight - size.height) / 2
                    numStr.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

                    // 4. Fold disclosure triangle (x: 42-56)
                    if let region = foldRegionAtLine[lineNumber], let engine = foldingEngine {
                        drawDisclosureTriangle(at: yInRuler, lineHeight: lineHeight, folded: engine.isFolded(region))
                    }
                } else if yInRuler > rect.maxY {
                    break
                }

                lineNumber += 1
            }

            glyphIndex = NSMaxRange(effectiveGlyphRange)
        }

        // Trailing empty line number
        if string.length == 0 || (string.length > 0 && string.character(at: string.length - 1) == 0x0A) {
            let lastLineY: CGFloat
            if totalGlyphs > 0 {
                lastLineY = layoutManager.extraLineFragmentRect.origin.y + insetY - visibleRect.origin.y + rulerOffset
            } else {
                lastLineY = insetY - visibleRect.origin.y + rulerOffset
            }

            if lastLineY + 14 >= rect.minY && lastLineY <= rect.maxY {
                let isCurrent = lineNumber == currentCursorLine
                let font = isCurrent ? currentLineFont : lineNumberFont
                let color: NSColor = isCurrent ? .labelColor : .tertiaryLabelColor
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let numStr = "\(lineNumber)" as NSString
                let size = numStr.size(withAttributes: attrs)
                numStr.draw(at: NSPoint(x: 38 - size.width, y: lastLineY), withAttributes: attrs)
            }
        }
    }

    // MARK: - Drawing Helpers

    private func drawDiffIndicator(hunks: [DiffHunk], lineNumber: Int, at y: CGFloat, lineHeight: CGFloat) {
        for hunk in hunks {
            guard hunk.affectedNewLines.contains(lineNumber) else { continue }

            // HIG: Use semantic colors that adapt to appearance
            let color: NSColor
            switch hunk.kind {
            case .added:    color = .systemGreen
            case .modified: color = .systemBlue
            case .removed:  color = .systemRed
            }

            let rect = NSRect(x: 0, y: y, width: 2.5, height: lineHeight)
            color.setFill()
            rect.fill()
            return
        }
    }

    private func drawBookmarkMarker(at y: CGFloat, lineHeight: CGFloat) {
        let size: CGFloat = 7
        let centerX: CGFloat = 6.5
        let centerY = y + lineHeight / 2
        let path = NSBezierPath()
        path.move(to: NSPoint(x: centerX, y: centerY - size / 2))
        path.line(to: NSPoint(x: centerX + size / 2, y: centerY))
        path.line(to: NSPoint(x: centerX, y: centerY + size / 2))
        path.line(to: NSPoint(x: centerX - size / 2, y: centerY))
        path.close()
        // HIG: Use controlAccentColor to respect user's accent color preference
        NSColor.controlAccentColor.setFill()
        path.fill()
    }

    private func drawIssueDot(at y: CGFloat, lineHeight: CGFloat, isError: Bool) {
        let dotSize: CGFloat = 6
        let centerY = y + (lineHeight - dotSize) / 2
        let dotRect = NSRect(x: 3.5, y: centerY, width: dotSize, height: dotSize)
        // HIG: Use system semantic colors for error/warning states
        let color: NSColor = isError ? .systemRed : .systemOrange
        let path = NSBezierPath(ovalIn: dotRect)
        color.setFill()
        path.fill()
    }

    private func drawDisclosureTriangle(at y: CGFloat, lineHeight: CGFloat, folded: Bool) {
        let centerY = y + lineHeight / 2
        let centerX: CGFloat = 49
        let halfSize = triangleSize / 2 * 0.6

        let path = NSBezierPath()

        if folded {
            // Right-pointing (collapsed)
            path.move(to: NSPoint(x: centerX - halfSize * 0.7, y: centerY - halfSize))
            path.line(to: NSPoint(x: centerX + halfSize * 0.7, y: centerY))
            path.line(to: NSPoint(x: centerX - halfSize * 0.7, y: centerY + halfSize))
        } else {
            // Down-pointing (expanded)
            path.move(to: NSPoint(x: centerX - halfSize, y: centerY - halfSize * 0.7))
            path.line(to: NSPoint(x: centerX + halfSize, y: centerY - halfSize * 0.7))
            path.line(to: NSPoint(x: centerX, y: centerY + halfSize * 0.7))
        }
        path.close()

        // HIG: Use tertiaryLabelColor for disclosure — matches Xcode's subtle fold indicators
        NSColor.tertiaryLabelColor.setFill()
        path.fill()
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        let pointInRuler = convert(event.locationInWindow, from: nil)

        if pointInRuler.x > 40 {
            handleFoldClick(at: pointInRuler)
        } else {
            handleLineClick(at: pointInRuler)
        }
    }

    private func handleFoldClick(at point: NSPoint) {
        guard let engine = foldingEngine,
              let scrollView = scrollView,
              let textView = scrollView.documentView as? NSTextView,
              let layoutManager = textView.layoutManager else { return }

        let string = textView.string as NSString
        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height
        let rulerOffset = convert(NSPoint.zero, from: scrollView.contentView).y

        var lineStarts: [Int: Int] = [:]
        var currentLine = 1
        lineStarts[1] = 0
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length),
            options: [.byLines, .substringNotRequired]
        ) { _, _, enclosingRange, _ in
            currentLine += 1
            lineStarts[currentLine] = NSMaxRange(enclosingRange)
        }

        for region in engine.regions {
            guard let charLocation = lineStarts[region.startLine] else { continue }

            let glyphIndex = layoutManager.glyphIndexForCharacter(at: min(charLocation, string.length - 1))
            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            lineRect.origin.y += insetY

            let yInRuler = lineRect.origin.y - visibleRect.origin.y + rulerOffset

            if point.y >= yInRuler && point.y <= yInRuler + lineRect.height {
                engine.toggleFold(regionID: region.id)

                if let foldDelegate = layoutManager.delegate as? FoldLayoutManagerDelegate {
                    foldDelegate.updateHiddenRanges(from: engine, string: string)
                }
                layoutManager.invalidateLayout(
                    forCharacterRange: NSRange(location: 0, length: string.length),
                    actualCharacterRange: nil
                )
                textView.needsDisplay = true
                needsDisplay = true
                return
            }
        }
    }

    private func handleLineClick(at point: NSPoint) {
        guard let scrollView = scrollView,
              let textView = scrollView.documentView as? NSTextView,
              let layoutManager = textView.layoutManager else { return }

        let string = textView.string as NSString
        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height
        let rulerOffset = convert(NSPoint.zero, from: scrollView.contentView).y

        var glyphIndex = 0
        let totalGlyphs = layoutManager.numberOfGlyphs

        while glyphIndex < totalGlyphs {
            var effectiveGlyphRange = NSRange(location: 0, length: 0)
            let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveGlyphRange)

            if lineFragmentRect.height == 0 {
                glyphIndex = NSMaxRange(effectiveGlyphRange)
                continue
            }

            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let isFirstFragment = charIndex == 0 || (charIndex > 0 && (string.character(at: charIndex - 1) == 0x0A || string.character(at: charIndex - 1) == 0x0D))

            if isFirstFragment {
                let lineY = lineFragmentRect.origin.y + insetY - visibleRect.origin.y + rulerOffset

                if point.y >= lineY && point.y <= lineY + lineFragmentRect.height {
                    let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))
                    textView.setSelectedRange(lineRange)
                    textView.scrollRangeToVisible(lineRange)
                    return
                }
            }

            glyphIndex = NSMaxRange(effectiveGlyphRange)
        }
    }
}
