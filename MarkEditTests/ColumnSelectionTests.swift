import XCTest
@testable import MarkEdit

final class ColumnSelectionTests: XCTestCase {

    // MARK: - ColumnSelectionState

    func testStateCreation() {
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 5, activeLine: 3, activeColumn: 10)
        XCTAssertEqual(state.anchorLine, 1)
        XCTAssertEqual(state.anchorColumn, 5)
        XCTAssertEqual(state.activeLine, 3)
        XCTAssertEqual(state.activeColumn, 10)
    }

    func testLineRange() {
        let state = ColumnSelectionState(anchorLine: 5, anchorColumn: 1, activeLine: 2, activeColumn: 1)
        XCTAssertEqual(state.lineRange, 2...5)
    }

    func testLineRangeSameLine() {
        let state = ColumnSelectionState(anchorLine: 3, anchorColumn: 1, activeLine: 3, activeColumn: 10)
        XCTAssertEqual(state.lineRange, 3...3)
    }

    func testColumnRange() {
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 10, activeLine: 3, activeColumn: 3)
        XCTAssertEqual(state.columnRange, 3...10)
    }

    func testColumnRangeSameColumn() {
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 5, activeLine: 2, activeColumn: 5)
        XCTAssertEqual(state.columnRange, 5...5)
    }

    // MARK: - ColumnSelectionInfo

    func testInfoCreation() {
        let info = ColumnSelectionInfo(lineRange: 1...5, columnRange: 3...10)
        XCTAssertEqual(info.lineRange, 1...5)
        XCTAssertEqual(info.columnRange, 3...10)
    }

    // MARK: - ColumnSelectionHelper.ranges

    func testRangesSimple() {
        // 3 lines of "ABCDEFGH\n"
        let content = "ABCDEFGH\nABCDEFGH\nABCDEFGH" as NSString

        // Select columns 3-5 on lines 1-3
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 3, activeLine: 3, activeColumn: 5)
        let ranges = ColumnSelectionHelper.ranges(for: state, in: content)

        XCTAssertEqual(ranges.count, 3)
        for range in ranges {
            XCTAssertEqual(range.length, 3) // columns 3, 4, 5 = 3 chars
        }
    }

    func testRangesSingleLine() {
        let content = "Hello World" as NSString
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 1, activeLine: 1, activeColumn: 5)
        let ranges = ColumnSelectionHelper.ranges(for: state, in: content)

        XCTAssertEqual(ranges.count, 1)
        XCTAssertEqual(ranges.first?.length, 5)
    }

    func testRangesClampToLineLength() {
        // Short line — column range exceeds line length
        let content = "AB\nABCDEFGH" as NSString
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 1, activeLine: 2, activeColumn: 6)
        let ranges = ColumnSelectionHelper.ranges(for: state, in: content)

        XCTAssertEqual(ranges.count, 2)
        // First line "AB" has only 2 chars, so range is clamped
        XCTAssertLessThanOrEqual(ranges[0].location + ranges[0].length, 2)
    }

    func testRangesEmptyContent() {
        let content = "" as NSString
        let state = ColumnSelectionState(anchorLine: 1, anchorColumn: 1, activeLine: 1, activeColumn: 5)
        let ranges = ColumnSelectionHelper.ranges(for: state, in: content)

        // Empty content may produce empty ranges (zero-length) or no ranges
        for range in ranges {
            XCTAssertEqual(range.length, 0)
        }
    }
}
