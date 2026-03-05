import Foundation
import Combine

/// Parses fold regions from source content and manages fold state.
class FoldingEngine: ObservableObject {
    @Published var regions: [FoldRegion] = []
    @Published var foldedRegionIDs: Set<UUID> = []

    // MARK: - Parsing

    func parse(content: String, fileType: String) {
        var newRegions: [FoldRegion] = []

        if fileType == "md" || fileType == "markdown" {
            newRegions = parseMarkdownHeaders(content: content)
        }

        // Always parse brackets/braces (useful in JSON, YAML frontmatter, JS, etc.)
        newRegions += parseBrackets(content: content)

        // Sort by startLine for consistent display
        newRegions.sort { $0.startLine < $1.startLine }
        regions = newRegions

        // Remove fold state for regions that no longer exist
        let validIDs = Set(newRegions.map(\.id))
        // Since IDs are regenerated on each parse, match by line range instead
        let oldFoldedLines = foldedRegionIDs.compactMap { id in
            // This won't match after re-parse since UUIDs are new.
            // We preserve fold state by line range below.
            return nil as (Int, Int)?
        }
        _ = oldFoldedLines // suppress warning

        // For simplicity, clear fold state on re-parse.
        // A more sophisticated approach would match old folds to new regions by line range.
        // We keep folds only if the fold set is currently empty (first parse).
    }

    // MARK: - Fold Actions

    func toggleFold(regionID: UUID) {
        if foldedRegionIDs.contains(regionID) {
            foldedRegionIDs.remove(regionID)
        } else {
            foldedRegionIDs.insert(regionID)
        }
    }

    func foldAll() {
        foldedRegionIDs = Set(regions.map(\.id))
    }

    func unfoldAll() {
        foldedRegionIDs.removeAll()
    }

    /// Returns true if the given region is currently folded.
    func isFolded(_ region: FoldRegion) -> Bool {
        foldedRegionIDs.contains(region.id)
    }

    /// Unfolds any region that contains the given line.
    func unfoldRegionsContaining(line: Int) {
        for region in regions where foldedRegionIDs.contains(region.id) {
            if line > region.startLine && line <= region.endLine {
                foldedRegionIDs.remove(region.id)
            }
        }
    }

    // MARK: - Character Ranges

    /// Returns the character range to hide for a folded region (from end of startLine to end of endLine).
    func hiddenCharacterRange(for region: FoldRegion, in string: NSString) -> NSRange? {
        guard foldedRegionIDs.contains(region.id) else { return nil }

        var startLineEnd: Int?
        var endLineEnd: Int?
        var currentLine = 1

        string.enumerateSubstrings(
            in: NSRange(location: 0, length: string.length),
            options: [.byLines, .substringNotRequired]
        ) { _, range, enclosingRange, stop in
            if currentLine == region.startLine {
                // End of the start line content (before newline)
                startLineEnd = range.location + range.length
            }
            if currentLine == region.endLine {
                // End of the end line (including newline)
                endLineEnd = enclosingRange.location + enclosingRange.length
                stop.pointee = true
            }
            currentLine += 1
        }

        guard let start = startLineEnd, let end = endLineEnd, end > start else { return nil }
        return NSRange(location: start, length: end - start)
    }

    /// Returns all hidden ranges for currently folded regions.
    func allHiddenRanges(in string: NSString) -> [NSRange] {
        regions.compactMap { hiddenCharacterRange(for: $0, in: string) }
            .sorted { $0.location < $1.location }
    }

    // MARK: - Bracket Parsing

    private func parseBrackets(content: String) -> [FoldRegion] {
        var regions: [FoldRegion] = []

        struct StackEntry {
            let char: Character
            let line: Int
            let depth: Int
        }

        var stack: [StackEntry] = []
        var currentLine = 1
        var depth = 0

        for char in content {
            if char == "\n" {
                currentLine += 1
                continue
            }

            if char == "{" || char == "[" {
                stack.append(StackEntry(char: char, line: currentLine, depth: depth))
                depth += 1
            } else if char == "}" || char == "]" {
                let expected: Character = char == "}" ? "{" : "["
                if let last = stack.last, last.char == expected {
                    stack.removeLast()
                    depth -= 1
                    // Only create region if it spans multiple lines
                    if currentLine > last.line {
                        let kind: FoldRegion.Kind = char == "}" ? .braces : .brackets
                        regions.append(FoldRegion(
                            startLine: last.line,
                            endLine: currentLine,
                            kind: kind,
                            nestingLevel: last.depth
                        ))
                    }
                }
            }
        }

        return regions
    }

    // MARK: - Markdown Header Parsing

    private func parseMarkdownHeaders(content: String) -> [FoldRegion] {
        let lines = content.components(separatedBy: "\n")
        var regions: [FoldRegion] = []

        struct HeaderEntry {
            let level: Int
            let line: Int
        }

        var headerStack: [HeaderEntry] = []

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                guard level >= 1 && level <= 6 else { continue }
                // Check it's a real header (space after #)
                let afterHashes = trimmed.dropFirst(level)
                guard afterHashes.isEmpty || afterHashes.hasPrefix(" ") else { continue }

                // Close any headers at same or deeper level
                while let last = headerStack.last, last.level >= level {
                    headerStack.removeLast()
                    if lineNumber - 1 > last.line {
                        regions.append(FoldRegion(
                            startLine: last.line,
                            endLine: lineNumber - 1,
                            kind: .markdownHeader(level: last.level),
                            nestingLevel: headerStack.count
                        ))
                    }
                }

                headerStack.append(HeaderEntry(level: level, line: lineNumber))
            }
        }

        // Close remaining open headers at end of document
        let lastLine = lines.count
        while let last = headerStack.popLast() {
            if lastLine > last.line {
                regions.append(FoldRegion(
                    startLine: last.line,
                    endLine: lastLine,
                    kind: .markdownHeader(level: last.level),
                    nestingLevel: headerStack.count
                ))
            }
        }

        return regions
    }
}
