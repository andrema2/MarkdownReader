import XCTest
@testable import MarkEdit

final class DiffEngineTests: XCTestCase {
    var engine: DiffEngine!

    override func setUp() {
        super.setUp()
        engine = DiffEngine()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(engine.hunks.isEmpty)
        XCTAssertFalse(engine.hasChanges)
    }

    // MARK: - DiffHunk

    func testDiffHunkIdentifiable() {
        let a = DiffHunk(kind: .added, oldLineStart: 1, newLineStart: 1, lines: ["a"])
        let b = DiffHunk(kind: .added, oldLineStart: 1, newLineStart: 1, lines: ["a"])
        XCTAssertNotEqual(a.id, b.id)
    }

    func testDiffHunkLineCount() {
        let hunk = DiffHunk(kind: .modified, oldLineStart: 1, newLineStart: 1, lines: ["a", "b", "c"])
        XCTAssertEqual(hunk.lineCount, 3)
    }

    func testDiffHunkAffectedNewLines() {
        let hunk = DiffHunk(kind: .added, oldLineStart: 0, newLineStart: 5, lines: ["x", "y"])
        XCTAssertEqual(hunk.affectedNewLines, 5...6)
    }

    func testDiffHunkAffectedNewLinesSingle() {
        let hunk = DiffHunk(kind: .modified, oldLineStart: 3, newLineStart: 3, lines: ["changed"])
        XCTAssertEqual(hunk.affectedNewLines, 3...3)
    }

    func testDiffHunkKindEquality() {
        XCTAssertEqual(DiffHunk.Kind.added, DiffHunk.Kind.added)
        XCTAssertEqual(DiffHunk.Kind.removed, DiffHunk.Kind.removed)
        XCTAssertEqual(DiffHunk.Kind.modified, DiffHunk.Kind.modified)
        XCTAssertNotEqual(DiffHunk.Kind.added, DiffHunk.Kind.removed)
    }

    // MARK: - Compute Diff (no file URL)

    @MainActor
    func testComputeDiffNoURLProducesNoHunks() {
        engine.computeDiff(currentContent: "hello", fileURL: nil)
        XCTAssertTrue(engine.hunks.isEmpty)
    }

    // MARK: - Compute Diff (with temp file)

    @MainActor
    func testComputeDiffIdenticalContent() {
        let content = "line1\nline2\nline3\n"
        let tempURL = writeTempFile(content: content)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        engine.computeDiff(currentContent: content, fileURL: tempURL)
        XCTAssertTrue(engine.hunks.isEmpty)
        XCTAssertFalse(engine.hasChanges)
    }

    @MainActor
    func testComputeDiffAddedLines() {
        let original = "line1\nline2\n"
        let current = "line1\nline2\nline3\nline4\n"
        let tempURL = writeTempFile(content: original)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        engine.computeDiff(currentContent: current, fileURL: tempURL)
        XCTAssertTrue(engine.hasChanges)

        let addedHunks = engine.hunks.filter { $0.kind == .added }
        XCTAssertFalse(addedHunks.isEmpty)
    }

    @MainActor
    func testComputeDiffRemovedLines() {
        let original = "line1\nline2\nline3\n"
        let current = "line1\n"
        let tempURL = writeTempFile(content: original)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        engine.computeDiff(currentContent: current, fileURL: tempURL)
        XCTAssertTrue(engine.hasChanges)
    }

    @MainActor
    func testComputeDiffModifiedLines() {
        let original = "line1\nline2\nline3\n"
        let current = "line1\nCHANGED\nline3\n"
        let tempURL = writeTempFile(content: original)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        engine.computeDiff(currentContent: current, fileURL: tempURL)
        XCTAssertTrue(engine.hasChanges)
    }

    // MARK: - Helpers

    private func writeTempFile(content: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent("difftest_\(UUID().uuidString).txt")
        try! content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
