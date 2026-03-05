import Foundation

/// Computes a line-level diff between the current editor content and the on-disk version.
class DiffEngine: ObservableObject {
    @Published var hunks: [DiffHunk] = []
    @Published var hasChanges: Bool = false

    /// Computes diff between current content and the saved file on disk.
    func computeDiff(currentContent: String, fileURL: URL?) {
        guard let url = fileURL else {
            hunks = []
            hasChanges = false
            return
        }

        let diskContent: String
        do {
            diskContent = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // Try with detected encoding
            var enc: String.Encoding = .utf8
            guard let content = try? String(contentsOf: url, usedEncoding: &enc) else {
                hunks = []
                hasChanges = false
                return
            }
            diskContent = content
        }

        let oldLines = diskContent.components(separatedBy: "\n")
        let newLines = currentContent.components(separatedBy: "\n")
        hunks = myersDiff(old: oldLines, new: newLines)
        hasChanges = !hunks.isEmpty
    }

    /// Simple Myers-like diff producing hunks of changes.
    private func myersDiff(old: [String], new: [String]) -> [DiffHunk] {
        // Build LCS table for line-level diff
        let m = old.count
        let n = new.count

        // For very large files, use a simpler approach
        if m + n > 50000 {
            return simpleLineDiff(old: old, new: new)
        }

        // LCS lengths table (space-optimized with two rows)
        var prev = [Int](repeating: 0, count: n + 1)
        var curr = [Int](repeating: 0, count: n + 1)

        for i in 1...max(m, 1) {
            guard i <= m else { break }
            for j in 1...max(n, 1) {
                guard j <= n else { break }
                if old[i - 1] == new[j - 1] {
                    curr[j] = prev[j - 1] + 1
                } else {
                    curr[j] = max(prev[j], curr[j - 1])
                }
            }
            prev = curr
            curr = [Int](repeating: 0, count: n + 1)
        }

        // Full table for backtracking (only for reasonable sizes)
        guard m <= 10000 && n <= 10000 else {
            return simpleLineDiff(old: old, new: new)
        }

        var table = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        for i in 1...max(m, 1) {
            guard i <= m else { break }
            for j in 1...max(n, 1) {
                guard j <= n else { break }
                if old[i - 1] == new[j - 1] {
                    table[i][j] = table[i - 1][j - 1] + 1
                } else {
                    table[i][j] = max(table[i - 1][j], table[i][j - 1])
                }
            }
        }

        // Backtrack to produce edit script
        var edits: [(kind: DiffHunk.Kind, oldLine: Int, newLine: Int, text: String)] = []
        var i = m, j = n
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && old[i - 1] == new[j - 1] {
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || table[i][j - 1] >= table[i - 1][j]) {
                edits.append((.added, i, j, new[j - 1]))
                j -= 1
            } else if i > 0 {
                edits.append((.removed, i, j, old[i - 1]))
                i -= 1
            } else {
                break
            }
        }

        edits.reverse()

        // Group consecutive edits into hunks
        return groupIntoHunks(edits: edits)
    }

    private func simpleLineDiff(old: [String], new: [String]) -> [DiffHunk] {
        var hunks: [DiffHunk] = []
        let maxLines = max(old.count, new.count)

        var i = 0
        while i < maxLines {
            let oldLine = i < old.count ? old[i] : nil
            let newLine = i < new.count ? new[i] : nil

            if oldLine != newLine {
                if oldLine != nil && newLine != nil {
                    hunks.append(DiffHunk(kind: .modified, oldLineStart: i + 1, newLineStart: i + 1, lines: [newLine!]))
                } else if oldLine == nil {
                    hunks.append(DiffHunk(kind: .added, oldLineStart: i + 1, newLineStart: i + 1, lines: [newLine!]))
                } else {
                    hunks.append(DiffHunk(kind: .removed, oldLineStart: i + 1, newLineStart: i + 1, lines: [oldLine!]))
                }
            }
            i += 1
        }
        return hunks
    }

    private func groupIntoHunks(edits: [(kind: DiffHunk.Kind, oldLine: Int, newLine: Int, text: String)]) -> [DiffHunk] {
        guard !edits.isEmpty else { return [] }

        var hunks: [DiffHunk] = []
        var currentKind = edits[0].kind
        var currentOldStart = edits[0].oldLine
        var currentNewStart = edits[0].newLine
        var currentLines = [edits[0].text]

        for edit in edits.dropFirst() {
            // Group adjacent edits of same kind
            if edit.kind == currentKind &&
               (edit.oldLine <= currentOldStart + currentLines.count + 1) {
                currentLines.append(edit.text)
            } else {
                hunks.append(DiffHunk(kind: currentKind, oldLineStart: currentOldStart, newLineStart: currentNewStart, lines: currentLines))
                currentKind = edit.kind
                currentOldStart = edit.oldLine
                currentNewStart = edit.newLine
                currentLines = [edit.text]
            }
        }
        hunks.append(DiffHunk(kind: currentKind, oldLineStart: currentOldStart, newLineStart: currentNewStart, lines: currentLines))

        return hunks
    }
}

/// A contiguous group of changed lines.
struct DiffHunk: Identifiable, Equatable {
    let id = UUID()
    let kind: Kind
    let oldLineStart: Int
    let newLineStart: Int
    let lines: [String]

    enum Kind: Equatable {
        case added
        case removed
        case modified
    }

    var lineCount: Int { lines.count }

    /// The line numbers in the new file affected by this hunk.
    var affectedNewLines: ClosedRange<Int> {
        newLineStart...(newLineStart + max(lineCount - 1, 0))
    }
}
