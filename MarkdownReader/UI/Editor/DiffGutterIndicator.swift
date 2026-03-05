import AppKit

/// Draws colored diff indicators in the gutter area to show added/modified/removed lines
/// relative to the on-disk version.
enum DiffGutterIndicator {
    /// Draws diff indicators for visible lines in the gutter.
    /// Call this from within `drawHashMarksAndLabels(in:)`.
    static func draw(
        hunks: [DiffHunk],
        lineNumber: Int,
        at y: CGFloat,
        lineHeight: CGFloat,
        gutterWidth: CGFloat
    ) {
        let indicatorWidth: CGFloat = 3
        let x = gutterWidth - indicatorWidth - 1  // right edge of gutter, before separator

        for hunk in hunks {
            guard hunk.affectedNewLines.contains(lineNumber) else { continue }

            let color: NSColor
            switch hunk.kind {
            case .added: color = .systemGreen
            case .modified: color = .systemBlue
            case .removed: color = .systemRed
            }

            // HIG: Use system semantic colors at full opacity for clear visibility
            let rect = NSRect(x: x, y: y, width: indicatorWidth, height: lineHeight)
            color.setFill()
            rect.fill()
            return
        }
    }

    /// Returns the color for a diff hunk kind.
    static func color(for kind: DiffHunk.Kind) -> NSColor {
        switch kind {
        case .added: return .systemGreen
        case .modified: return .systemBlue
        case .removed: return .systemRed
        }
    }
}
