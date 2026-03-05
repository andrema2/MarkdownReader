import XCTest
@testable import MarkEdit

final class FoldingEngineTests: XCTestCase {
    var engine: FoldingEngine!

    override func setUp() {
        super.setUp()
        engine = FoldingEngine()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(engine.regions.isEmpty)
        XCTAssertTrue(engine.foldedRegionIDs.isEmpty)
    }

    // MARK: - Parse Braces

    func testParseBraces() {
        let content = """
        func foo() {
            let x = 1
        }
        """
        engine.parse(content: content, fileType: "swift")
        XCTAssertEqual(engine.regions.count, 1)
        XCTAssertEqual(engine.regions.first?.kind, .braces)
        XCTAssertEqual(engine.regions.first?.startLine, 1)
        XCTAssertEqual(engine.regions.first?.endLine, 3)
    }

    func testParseNestedBraces() {
        let content = """
        {
            {
                inner
            }
        }
        """
        engine.parse(content: content, fileType: "json")
        XCTAssertGreaterThanOrEqual(engine.regions.count, 2)
    }

    // MARK: - Parse Brackets

    func testParseBrackets() {
        let content = """
        [
            1,
            2,
            3
        ]
        """
        engine.parse(content: content, fileType: "json")
        let bracketRegions = engine.regions.filter { $0.kind == .brackets }
        XCTAssertFalse(bracketRegions.isEmpty)
    }

    // MARK: - Parse Markdown Headers

    func testParseMarkdownHeaders() {
        let content = """
        # Title
        Some content
        ## Subtitle
        More content
        ## Another
        End
        """
        engine.parse(content: content, fileType: "md")
        let headerRegions = engine.regions.filter {
            if case .markdownHeader = $0.kind { return true }
            return false
        }
        XCTAssertFalse(headerRegions.isEmpty)
    }

    func testParseMarkdownFileExtension() {
        let content = "# Header\nContent\n"
        engine.parse(content: content, fileType: "markdown")
        let headerRegions = engine.regions.filter {
            if case .markdownHeader = $0.kind { return true }
            return false
        }
        XCTAssertFalse(headerRegions.isEmpty)
    }

    // MARK: - Toggle Fold

    func testToggleFold() {
        let content = "{\n  x\n}\n"
        engine.parse(content: content, fileType: "json")
        guard let region = engine.regions.first else {
            XCTFail("Expected at least one region")
            return
        }

        XCTAssertFalse(engine.isFolded(region))
        engine.toggleFold(regionID: region.id)
        XCTAssertTrue(engine.isFolded(region))
        engine.toggleFold(regionID: region.id)
        XCTAssertFalse(engine.isFolded(region))
    }

    // MARK: - Fold All / Unfold All

    func testFoldAll() {
        let content = "{\n  a\n}\n[\n  b\n]\n"
        engine.parse(content: content, fileType: "json")
        XCTAssertTrue(engine.foldedRegionIDs.isEmpty)

        engine.foldAll()
        XCTAssertEqual(engine.foldedRegionIDs.count, engine.regions.count)
    }

    func testUnfoldAll() {
        let content = "{\n  a\n}\n"
        engine.parse(content: content, fileType: "json")
        engine.foldAll()
        XCTAssertFalse(engine.foldedRegionIDs.isEmpty)

        engine.unfoldAll()
        XCTAssertTrue(engine.foldedRegionIDs.isEmpty)
    }

    // MARK: - Unfold Regions Containing Line

    func testUnfoldRegionsContainingLine() {
        let content = "{\n  line2\n  line3\n}\n"
        engine.parse(content: content, fileType: "json")
        engine.foldAll()

        engine.unfoldRegionsContaining(line: 2)
        XCTAssertTrue(engine.foldedRegionIDs.isEmpty)
    }

    func testUnfoldRegionsContainingLineOutsideRegion() {
        let content = "line1\n{\n  line3\n}\nline5\n"
        engine.parse(content: content, fileType: "swift")
        engine.foldAll()
        let foldedBefore = engine.foldedRegionIDs.count

        engine.unfoldRegionsContaining(line: 1)
        // Line 1 is outside the fold region, so nothing should change
        XCTAssertEqual(engine.foldedRegionIDs.count, foldedBefore)
    }

    // MARK: - Hidden Character Range

    func testHiddenCharacterRange() {
        let content = "{\n  inner\n}\n"
        let nsString = content as NSString
        engine.parse(content: content, fileType: "json")
        guard let region = engine.regions.first else {
            XCTFail("Expected a region")
            return
        }

        engine.toggleFold(regionID: region.id)
        let range = engine.hiddenCharacterRange(for: region, in: nsString)
        XCTAssertNotNil(range)
        XCTAssertGreaterThan(range!.length, 0)
    }

    func testHiddenCharacterRangeWhenNotFolded() {
        let content = "{\n  inner\n}\n"
        let nsString = content as NSString
        engine.parse(content: content, fileType: "json")
        guard let region = engine.regions.first else {
            XCTFail("Expected a region")
            return
        }

        // Not folded — hiddenCharacterRange may return nil since region is not folded
        // The method computes the range regardless, but implementation may filter by fold state
        // Just verify it doesn't crash; actual hiding only happens when folded
        let _ = engine.hiddenCharacterRange(for: region, in: nsString)
    }

    // MARK: - All Hidden Ranges

    func testAllHiddenRangesEmpty() {
        let content = "{\n  a\n}\n"
        let nsString = content as NSString
        engine.parse(content: content, fileType: "json")
        // Nothing folded
        let ranges = engine.allHiddenRanges(in: nsString)
        XCTAssertTrue(ranges.isEmpty)
    }

    func testAllHiddenRangesWithFolded() {
        let content = "{\n  a\n}\n"
        let nsString = content as NSString
        engine.parse(content: content, fileType: "json")
        engine.foldAll()

        let ranges = engine.allHiddenRanges(in: nsString)
        XCTAssertFalse(ranges.isEmpty)
    }

    // MARK: - Empty Content

    func testParseEmptyContent() {
        engine.parse(content: "", fileType: "swift")
        XCTAssertTrue(engine.regions.isEmpty)
    }

    // MARK: - Re-parse Clears Folds

    func testReParseClearsFoldedIDs() {
        let content = "{\n  a\n}\n"
        engine.parse(content: content, fileType: "json")
        engine.foldAll()
        XCTAssertFalse(engine.foldedRegionIDs.isEmpty)

        // Re-parse replaces regions, IDs change
        engine.parse(content: content, fileType: "json")
        // Old folded IDs no longer match new region IDs
        let stillFolded = engine.regions.filter { engine.isFolded($0) }
        // After re-parse, old UUIDs are stale, so nothing should be folded
        XCTAssertTrue(stillFolded.isEmpty)
    }
}
