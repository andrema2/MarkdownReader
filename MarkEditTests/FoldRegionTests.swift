import XCTest
@testable import MarkEdit

final class FoldRegionTests: XCTestCase {

    func testCreation() {
        let region = FoldRegion(startLine: 5, endLine: 10, kind: .braces)
        XCTAssertEqual(region.startLine, 5)
        XCTAssertEqual(region.endLine, 10)
        XCTAssertEqual(region.kind, .braces)
        XCTAssertEqual(region.nestingLevel, 0)
    }

    func testCreationWithNestingLevel() {
        let region = FoldRegion(startLine: 1, endLine: 3, kind: .brackets, nestingLevel: 2)
        XCTAssertEqual(region.nestingLevel, 2)
    }

    func testKindBraces() {
        let region = FoldRegion(startLine: 1, endLine: 2, kind: .braces)
        XCTAssertEqual(region.kind, .braces)
    }

    func testKindBrackets() {
        let region = FoldRegion(startLine: 1, endLine: 2, kind: .brackets)
        XCTAssertEqual(region.kind, .brackets)
    }

    func testKindMarkdownHeader() {
        let region = FoldRegion(startLine: 1, endLine: 5, kind: .markdownHeader(level: 2))
        if case .markdownHeader(let level) = region.kind {
            XCTAssertEqual(level, 2)
        } else {
            XCTFail("Expected markdownHeader kind")
        }
    }

    func testIdentifiable() {
        let a = FoldRegion(startLine: 1, endLine: 2, kind: .braces)
        let b = FoldRegion(startLine: 1, endLine: 2, kind: .braces)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testEquatable() {
        let region = FoldRegion(startLine: 1, endLine: 2, kind: .braces)
        XCTAssertEqual(region, region)
    }

    func testKindEquality() {
        XCTAssertEqual(FoldRegion.Kind.braces, FoldRegion.Kind.braces)
        XCTAssertEqual(FoldRegion.Kind.brackets, FoldRegion.Kind.brackets)
        XCTAssertNotEqual(FoldRegion.Kind.braces, FoldRegion.Kind.brackets)
        XCTAssertEqual(FoldRegion.Kind.markdownHeader(level: 1), FoldRegion.Kind.markdownHeader(level: 1))
        XCTAssertNotEqual(FoldRegion.Kind.markdownHeader(level: 1), FoldRegion.Kind.markdownHeader(level: 2))
    }
}
