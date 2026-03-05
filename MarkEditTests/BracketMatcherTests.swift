import XCTest
@testable import MarkEdit

final class BracketMatcherTests: XCTestCase {

    // MARK: - Curly Braces

    func testMatchOpeningBrace() {
        let str = "{ hello }" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0) // at {
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 8) // closing }
        XCTAssertEqual(match?.length, 1)
    }

    func testMatchClosingBrace() {
        let str = "{ hello }" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 8) // at }
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 0) // opening {
    }

    // MARK: - Square Brackets

    func testMatchOpeningBracket() {
        let str = "[1, 2, 3]" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 8) // closing ]
    }

    func testMatchClosingBracket() {
        let str = "[1, 2, 3]" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 8)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 0) // opening [
    }

    // MARK: - Parentheses

    func testMatchOpeningParen() {
        let str = "(a + b)" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 6) // closing )
    }

    func testMatchClosingParen() {
        let str = "(a + b)" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 6)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 0)
    }

    // MARK: - Angle Brackets

    func testMatchAngleBrackets() {
        let str = "<div></div>" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNotNil(match)
    }

    // MARK: - Nested Brackets

    func testMatchNestedBraces() {
        let str = "{ { inner } }" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0) // outer {
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 12) // outer }
    }

    func testMatchInnerNestedBraces() {
        let str = "{ { inner } }" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 2) // inner {
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 10) // inner }
    }

    // MARK: - Quotes

    func testMatchDoubleQuotes() {
        let str = "\"hello world\"" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0) // opening "
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 12) // closing "
    }

    func testMatchSingleQuotes() {
        let str = "'hello'" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0) // opening '
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 6) // closing '
    }

    func testMatchBackticks() {
        let str = "`code`" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0) // opening `
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.location, 5) // closing `
    }

    // MARK: - Escaped Quotes

    func testEscapedQuoteSkipped() {
        let str = "\"hello \\\" world\"" as NSString // "hello \" world"
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNotNil(match)
        // Should match the final ", not the escaped one
        XCTAssertEqual(match?.location, str.length - 1)
    }

    // MARK: - No Match

    func testNoMatchOnNonBracket() {
        let str = "hello world" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 3)
        XCTAssertNil(match)
    }

    func testNoMatchUnbalancedBrace() {
        let str = "{ hello" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNil(match)
    }

    func testEmptyString() {
        let str = "" as NSString
        let match = BracketMatcher.findMatch(in: str, at: 0)
        XCTAssertNil(match)
    }

    // MARK: - Static Properties

    func testOpenToCloseMapping() {
        XCTAssertEqual(BracketMatcher.openToClose["{"], "}")
        XCTAssertEqual(BracketMatcher.openToClose["["], "]")
        XCTAssertEqual(BracketMatcher.openToClose["("], ")")
        XCTAssertEqual(BracketMatcher.openToClose["<"], ">")
    }

    func testCloseToOpenMapping() {
        XCTAssertEqual(BracketMatcher.closeToOpen["}"], "{")
        XCTAssertEqual(BracketMatcher.closeToOpen["]"], "[")
        XCTAssertEqual(BracketMatcher.closeToOpen[")"], "(")
        XCTAssertEqual(BracketMatcher.closeToOpen[">"], "<")
    }

    func testQuotesSet() {
        XCTAssertTrue(BracketMatcher.quotes.contains("\""))
        XCTAssertTrue(BracketMatcher.quotes.contains("'"))
        XCTAssertTrue(BracketMatcher.quotes.contains("`"))
    }
}
