import XCTest
@testable import MarkEdit

final class BookmarkEngineTests: XCTestCase {
    var engine: BookmarkEngine!

    override func setUp() {
        super.setUp()
        engine = BookmarkEngine()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(engine.bookmarkedLines.isEmpty)
    }

    // MARK: - Toggle

    func testToggleAddsBookmark() {
        engine.toggleBookmark(at: 5)
        XCTAssertTrue(engine.isBookmarked(5))
    }

    func testToggleRemovesBookmark() {
        engine.toggleBookmark(at: 5)
        engine.toggleBookmark(at: 5)
        XCTAssertFalse(engine.isBookmarked(5))
    }

    func testIsBookmarked() {
        XCTAssertFalse(engine.isBookmarked(1))
        engine.toggleBookmark(at: 1)
        XCTAssertTrue(engine.isBookmarked(1))
    }

    // MARK: - Navigation

    func testNextBookmark() {
        engine.toggleBookmark(at: 3)
        engine.toggleBookmark(at: 7)
        engine.toggleBookmark(at: 15)

        XCTAssertEqual(engine.nextBookmark(after: 1), 3)
        XCTAssertEqual(engine.nextBookmark(after: 3), 7)
        XCTAssertEqual(engine.nextBookmark(after: 7), 15)
    }

    func testNextBookmarkWrapsAround() {
        engine.toggleBookmark(at: 3)
        engine.toggleBookmark(at: 7)

        // After last bookmark, wraps to first
        XCTAssertEqual(engine.nextBookmark(after: 7), 3)
        XCTAssertEqual(engine.nextBookmark(after: 100), 3)
    }

    func testPreviousBookmark() {
        engine.toggleBookmark(at: 3)
        engine.toggleBookmark(at: 7)
        engine.toggleBookmark(at: 15)

        XCTAssertEqual(engine.previousBookmark(before: 15), 7)
        XCTAssertEqual(engine.previousBookmark(before: 7), 3)
    }

    func testPreviousBookmarkWrapsAround() {
        engine.toggleBookmark(at: 3)
        engine.toggleBookmark(at: 7)

        // Before first bookmark, wraps to last
        XCTAssertEqual(engine.previousBookmark(before: 3), 7)
        XCTAssertEqual(engine.previousBookmark(before: 1), 7)
    }

    func testNextBookmarkEmptyReturnsNil() {
        XCTAssertNil(engine.nextBookmark(after: 1))
    }

    func testPreviousBookmarkEmptyReturnsNil() {
        XCTAssertNil(engine.previousBookmark(before: 1))
    }

    func testNextBookmarkSingleBookmark() {
        engine.toggleBookmark(at: 5)
        // With only one bookmark, next from that bookmark wraps to itself
        XCTAssertEqual(engine.nextBookmark(after: 5), 5)
    }

    func testPreviousBookmarkSingleBookmark() {
        engine.toggleBookmark(at: 5)
        XCTAssertEqual(engine.previousBookmark(before: 5), 5)
    }

    // MARK: - Clear All

    func testClearAll() {
        engine.toggleBookmark(at: 1)
        engine.toggleBookmark(at: 5)
        engine.toggleBookmark(at: 10)
        engine.clearAll()
        XCTAssertTrue(engine.bookmarkedLines.isEmpty)
    }

    // MARK: - Adjust For Edit

    func testAdjustForEditInsertLine() {
        engine.toggleBookmark(at: 5)
        engine.toggleBookmark(at: 10)
        engine.adjustForEdit(atLine: 3, delta: 2) // Insert 2 lines at line 3

        XCTAssertTrue(engine.isBookmarked(7))  // 5 + 2
        XCTAssertTrue(engine.isBookmarked(12)) // 10 + 2
        XCTAssertFalse(engine.isBookmarked(5))
        XCTAssertFalse(engine.isBookmarked(10))
    }

    func testAdjustForEditDeleteLine() {
        engine.toggleBookmark(at: 5)
        engine.toggleBookmark(at: 10)
        engine.adjustForEdit(atLine: 3, delta: -1) // Delete 1 line at line 3

        XCTAssertTrue(engine.isBookmarked(4))  // 5 - 1
        XCTAssertTrue(engine.isBookmarked(9))  // 10 - 1
    }

    func testAdjustForEditDoesNotMoveBookmarksBefore() {
        engine.toggleBookmark(at: 2)
        engine.toggleBookmark(at: 10)
        engine.adjustForEdit(atLine: 5, delta: 3)

        XCTAssertTrue(engine.isBookmarked(2))   // Before edit line, unchanged
        XCTAssertTrue(engine.isBookmarked(13))  // 10 + 3
    }
}
