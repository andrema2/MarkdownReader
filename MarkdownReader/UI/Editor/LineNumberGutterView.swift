import AppKit

/// NSRulerView subclass that draws clickable line numbers in the gutter,
/// with error/warning icons for lines that have lint issues.
class LineNumberGutterView: NSRulerView {
    weak var lintEngine: LintEngine?

    /// Callback when a line number is clicked.
    var onLineClicked: ((Int) -> Void)?

    private let lineNumberFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    private let lineNumberColor = NSColor.secondaryLabelColor
    private let currentLineColor = NSColor.labelColor

    override var requiredThickness: CGFloat { 40 }

    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        super.init(scrollView: scrollView, orientation: orientation)
        ruleThickness = 40
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let scrollView = scrollView,
              let textView = scrollView.documentView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let string = textView.string as NSString
        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height

        // Get current cursor line
        let cursorLocation = textView.selectedRange().location
        let cursorPrefix = string.substring(to: min(cursorLocation, string.length))
        let currentLine = cursorPrefix.components(separatedBy: .newlines).count

        // Build lint issue map
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

        // Draw background
        NSColor.controlBackgroundColor.withAlphaComponent(0.5).setFill()
        rect.fill()

        // Draw separator line on the right edge
        NSColor.separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: rect.minY))
        separatorPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: rect.maxY))
        separatorPath.lineWidth = 0.5
        separatorPath.stroke()

        // Enumerate lines and draw numbers
        var lineNumber = 1
        var glyphIndex = 0
        let totalGlyphs = layoutManager.numberOfGlyphs

        while glyphIndex < totalGlyphs {
            var lineFragmentRect = NSRect.zero
            var effectiveGlyphRange = NSRange(location: 0, length: 0)
            lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &effectiveGlyphRange)

            // Skip zero-height lines (folded)
            if lineFragmentRect.height == 0 {
                glyphIndex = NSMaxRange(effectiveGlyphRange)
                continue
            }

            let lineY = lineFragmentRect.origin.y + insetY
            let yInRuler = lineY - visibleRect.origin.y

            // Only draw if visible
            if yInRuler + lineFragmentRect.height >= rect.minY && yInRuler <= rect.maxY {
                // Check if this is the first glyph of a new line
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                let isFirstFragment: Bool
                if charIndex == 0 {
                    isFirstFragment = true
                } else {
                    let prevChar = string.character(at: charIndex - 1)
                    isFirstFragment = prevChar == 0x0A || prevChar == 0x0D // newline
                }

                if isFirstFragment {
                    let isCurrent = lineNumber == currentLine

                    // Draw error/warning icon
                    if errorLines.contains(lineNumber) {
                        drawIssueIcon(at: yInRuler, lineHeight: lineFragmentRect.height, isError: true)
                    } else if warningLines.contains(lineNumber) {
                        drawIssueIcon(at: yInRuler, lineHeight: lineFragmentRect.height, isError: false)
                    }

                    // Draw line number
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: lineNumberFont,
                        .foregroundColor: isCurrent ? currentLineColor : lineNumberColor
                    ]
                    let numberString = "\(lineNumber)" as NSString
                    let size = numberString.size(withAttributes: attrs)
                    let x = bounds.width - size.width - 6  // right-aligned with padding
                    let y = yInRuler + (lineFragmentRect.height - size.height) / 2
                    numberString.draw(at: NSPoint(x: x, y: y), withAttributes: attrs)

                    lineNumber += 1
                }
            } else if yInRuler > rect.maxY {
                break
            } else {
                // Off-screen above — still count lines
                let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
                if charIndex == 0 || string.character(at: charIndex - 1) == 0x0A || string.character(at: charIndex - 1) == 0x0D {
                    lineNumber += 1
                }
            }

            glyphIndex = NSMaxRange(effectiveGlyphRange)
        }

        // Draw number for last line if it's empty (no glyph)
        if string.length == 0 || (string.length > 0 && string.character(at: string.length - 1) == 0x0A) {
            let lastLineY: CGFloat
            if totalGlyphs > 0 {
                let lastRect = layoutManager.extraLineFragmentRect
                lastLineY = lastRect.origin.y + insetY - visibleRect.origin.y
            } else {
                lastLineY = insetY - visibleRect.origin.y
            }

            if lastLineY + 14 >= rect.minY && lastLineY <= rect.maxY {
                let isCurrent = lineNumber == currentLine
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: lineNumberFont,
                    .foregroundColor: isCurrent ? currentLineColor : lineNumberColor
                ]
                let numberString = "\(lineNumber)" as NSString
                let size = numberString.size(withAttributes: attrs)
                let x = bounds.width - size.width - 6
                numberString.draw(at: NSPoint(x: x, y: lastLineY), withAttributes: attrs)
            }
        }
    }

    private func drawIssueIcon(at y: CGFloat, lineHeight: CGFloat, isError: Bool) {
        let iconSize: CGFloat = 8
        let centerY = y + (lineHeight - iconSize) / 2
        let rect = NSRect(x: 2, y: centerY, width: iconSize, height: iconSize)
        let color: NSColor = isError ? .systemRed : .systemOrange
        let path = NSBezierPath(ovalIn: rect)
        color.withAlphaComponent(0.8).setFill()
        path.fill()
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        guard let scrollView = scrollView,
              let textView = scrollView.documentView as? NSTextView,
              let layoutManager = textView.layoutManager else { return }

        let pointInRuler = convert(event.locationInWindow, from: nil)
        let visibleRect = scrollView.contentView.bounds
        let string = textView.string as NSString
        let insetY = textView.textContainerInset.height

        // Find which line was clicked
        var lineNumber = 1
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
            let isFirstFragment = charIndex == 0 || string.character(at: charIndex - 1) == 0x0A || string.character(at: charIndex - 1) == 0x0D

            if isFirstFragment {
                let lineY = lineFragmentRect.origin.y + insetY - visibleRect.origin.y
                if pointInRuler.y >= lineY && pointInRuler.y <= lineY + lineFragmentRect.height {
                    // Select the entire line
                    let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))
                    textView.setSelectedRange(lineRange)
                    onLineClicked?(lineNumber)
                    return
                }
                lineNumber += 1
            }

            glyphIndex = NSMaxRange(effectiveGlyphRange)
        }
    }
}
