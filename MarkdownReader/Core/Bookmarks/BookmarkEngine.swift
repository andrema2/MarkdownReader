import Foundation

/// Manages line bookmarks for a document. Bookmarks are stored as 1-based line numbers.
class BookmarkEngine: ObservableObject {
    @Published var bookmarkedLines: Set<Int> = []

    /// Toggle a bookmark at the given line.
    func toggleBookmark(at line: Int) {
        if bookmarkedLines.contains(line) {
            bookmarkedLines.remove(line)
        } else {
            bookmarkedLines.insert(line)
        }
    }

    /// Returns the next bookmarked line after the given line (wraps around).
    func nextBookmark(after currentLine: Int) -> Int? {
        guard !bookmarkedLines.isEmpty else { return nil }
        let sorted = bookmarkedLines.sorted()

        // Find the first bookmark after currentLine
        if let next = sorted.first(where: { $0 > currentLine }) {
            return next
        }
        // Wrap to the first bookmark
        return sorted.first
    }

    /// Returns the previous bookmarked line before the given line (wraps around).
    func previousBookmark(before currentLine: Int) -> Int? {
        guard !bookmarkedLines.isEmpty else { return nil }
        let sorted = bookmarkedLines.sorted()

        // Find the last bookmark before currentLine
        if let prev = sorted.last(where: { $0 < currentLine }) {
            return prev
        }
        // Wrap to the last bookmark
        return sorted.last
    }

    /// Removes all bookmarks.
    func clearAll() {
        bookmarkedLines.removeAll()
    }

    /// Adjusts bookmark positions after lines are inserted or deleted.
    func adjustForEdit(atLine line: Int, delta: Int) {
        var adjusted = Set<Int>()
        for bookmark in bookmarkedLines {
            if bookmark >= line {
                let newLine = bookmark + delta
                if newLine >= 1 {
                    adjusted.insert(newLine)
                }
            } else {
                adjusted.insert(bookmark)
            }
        }
        bookmarkedLines = adjusted
    }

    /// Whether a specific line is bookmarked.
    func isBookmarked(_ line: Int) -> Bool {
        bookmarkedLines.contains(line)
    }
}
