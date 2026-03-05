import AppKit

/// NSLayoutManagerDelegate that collapses folded lines to zero height.
/// Text storage is never modified — undo, find/replace work normally.
class FoldLayoutManagerDelegate: NSObject, NSLayoutManagerDelegate {
    weak var foldingEngine: FoldingEngine?
    private(set) var hiddenRanges: [NSRange] = []

    func updateHiddenRanges(from engine: FoldingEngine, string: NSString) {
        hiddenRanges = engine.allHiddenRanges(in: string)
    }

    // MARK: - NSLayoutManagerDelegate

    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<NSRect>,
        lineFragmentUsedRect: UnsafeMutablePointer<NSRect>,
        baselineOffset: UnsafeMutablePointer<CGFloat>,
        in textContainer: NSTextContainer,
        forGlyphRange glyphRange: NSRange
    ) -> Bool {
        guard !hiddenRanges.isEmpty else { return false }

        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        for hiddenRange in hiddenRanges {
            // If this line fragment is fully inside a hidden range, collapse it
            if hiddenRange.location <= charRange.location &&
               NSMaxRange(hiddenRange) >= NSMaxRange(charRange) {
                lineFragmentRect.pointee.size.height = 0
                lineFragmentUsedRect.pointee.size.height = 0
                baselineOffset.pointee = 0
                return true
            }
        }

        return false
    }

    /// Called to generate glyphs — we use this to add "..." placeholder for folded regions.
    func layoutManager(
        _ layoutManager: NSLayoutManager,
        shouldGenerateGlyphs glyphs: UnsafePointer<CGGlyph>,
        properties props: UnsafePointer<NSLayoutManager.GlyphProperty>,
        characterIndexes charIndexes: UnsafePointer<Int>,
        font aFont: NSFont,
        forGlyphRange glyphRange: NSRange
    ) -> Int {
        guard !hiddenRanges.isEmpty else { return 0 }

        // Check if any glyph in this range falls inside a hidden range
        let firstCharIndex = charIndexes[0]
        var needsModification = false

        for hiddenRange in hiddenRanges {
            if firstCharIndex >= hiddenRange.location && firstCharIndex < NSMaxRange(hiddenRange) {
                needsModification = true
                break
            }
        }

        guard needsModification else { return 0 }

        // Mark glyphs inside hidden ranges as null (invisible)
        var modifiedProps = Array(UnsafeBufferPointer(start: props, count: glyphRange.length))

        for i in 0..<glyphRange.length {
            let charIdx = charIndexes[i]
            for hiddenRange in hiddenRanges {
                if charIdx >= hiddenRange.location && charIdx < NSMaxRange(hiddenRange) {
                    modifiedProps[i] = .null
                    break
                }
            }
        }

        layoutManager.setGlyphs(
            glyphs,
            properties: &modifiedProps,
            characterIndexes: charIndexes,
            font: aFont,
            forGlyphRange: glyphRange
        )

        return glyphRange.length
    }
}
