import AppKit

/// Describes a rectangular (column/block) selection in the editor.
struct ColumnSelectionState {
    var anchorLine: Int
    var anchorColumn: Int
    var activeLine: Int
    var activeColumn: Int

    var lineRange: ClosedRange<Int> {
        min(anchorLine, activeLine)...max(anchorLine, activeLine)
    }

    var columnRange: ClosedRange<Int> {
        min(anchorColumn, activeColumn)...max(anchorColumn, activeColumn)
    }
}

/// Info published to the document model for the status bar.
struct ColumnSelectionInfo {
    var lineRange: ClosedRange<Int>
    var columnRange: ClosedRange<Int>
}

enum ColumnSelectionHelper {
    /// Converts a mouse point (in text view coordinates) to a (line, column) pair using monospaced character width.
    static func lineAndColumn(
        for point: NSPoint,
        in textView: NSTextView,
        layoutManager: NSLayoutManager,
        textContainer: NSTextContainer,
        charWidth: CGFloat
    ) -> (line: Int, column: Int) {
        let insetPoint = NSPoint(
            x: point.x - textView.textContainerInset.width,
            y: point.y - textView.textContainerInset.height
        )

        // Find the glyph index at the point to determine the line
        var fraction: CGFloat = 0
        let glyphIndex = layoutManager.glyphIndex(for: insetPoint, in: textContainer, fractionOfDistanceThroughGlyph: &fraction)
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        let string = textView.string as NSString

        // Count lines up to charIndex
        var line = 1
        var lineStart = 0
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: min(charIndex, string.length)),
            options: [.byLines, .substringNotRequired]
        ) { _, range, _, _ in
            line += 1
            lineStart = NSMaxRange(range)
        }

        // If charIndex is beyond last enumerated line start, we're on the right line already
        // Compute column from x position using monospaced width
        let column = max(1, Int(round(insetPoint.x / charWidth)) + 1)

        return (line, column)
    }

    /// Converts a rectangular column selection to an array of NSRange (one per line, same column span).
    static func ranges(for state: ColumnSelectionState, in string: NSString) -> [NSRange] {
        var result: [NSRange] = []
        let lines = state.lineRange
        let cols = state.columnRange

        var currentLine = 1
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length),
            options: [.byLines, .substringNotRequired]
        ) { _, range, _, stop in
            if currentLine > lines.upperBound {
                stop.pointee = true
                return
            }
            if lines.contains(currentLine) {
                let lineContentStart = range.location
                let lineContentEnd = range.location + range.length

                // Column is 1-based; clamp to actual line length
                let startOffset = lineContentStart + (cols.lowerBound - 1)
                let endOffset = lineContentStart + cols.upperBound

                let clampedStart = min(startOffset, lineContentEnd)
                let clampedEnd = min(endOffset, lineContentEnd)

                if clampedEnd >= clampedStart {
                    result.append(NSRange(location: clampedStart, length: clampedEnd - clampedStart))
                }
            }
            currentLine += 1
        }

        // Handle case where selection extends past last line
        if result.isEmpty {
            result.append(NSRange(location: string.length, length: 0))
        }

        return result
    }
}
