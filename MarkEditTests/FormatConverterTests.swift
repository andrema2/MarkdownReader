import XCTest
@testable import MarkEdit

final class FormatConverterTests: XCTestCase {

    // MARK: - canTransform

    func testCanTransformJSONToYAML() {
        XCTAssertTrue(FormatConverter.canTransform(from: .json, to: .yaml))
    }

    func testCanTransformYAMLToJSON() {
        XCTAssertTrue(FormatConverter.canTransform(from: .yaml, to: .json))
    }

    func testCanTransformMarkdownToPlain() {
        XCTAssertTrue(FormatConverter.canTransform(from: .markdown, to: .plain))
    }

    func testCanTransformPlainToMarkdown() {
        XCTAssertTrue(FormatConverter.canTransform(from: .plain, to: .markdown))
    }

    func testCannotTransformJSToJSON() {
        XCTAssertFalse(FormatConverter.canTransform(from: .javascript, to: .json))
    }

    func testCannotTransformSameType() {
        for type in DocumentModel.FileType.allCases {
            XCTAssertFalse(FormatConverter.canTransform(from: type, to: type))
        }
    }

    // MARK: - Same type returns nil

    func testConvertSameTypeReturnsNil() {
        let result = FormatConverter.convert("{}", from: .json, to: .json)
        XCTAssertNil(result)
    }

    // MARK: - JSON → YAML

    func testJSONToYAMLSimple() {
        let json = """
        {"name": "test", "count": 42}
        """
        let result = FormatConverter.convert(json, from: .json, to: .yaml)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("name:"))
        XCTAssertTrue(result!.contains("count:"))
        XCTAssertTrue(result!.contains("42"))
    }

    func testJSONToYAMLArray() {
        let json = """
        {"items": ["a", "b", "c"]}
        """
        let result = FormatConverter.convert(json, from: .json, to: .yaml)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("items:"))
        XCTAssertTrue(result!.contains("- a"))
    }

    func testJSONToYAMLBooleans() {
        let json = """
        {"enabled": true, "debug": false}
        """
        let result = FormatConverter.convert(json, from: .json, to: .yaml)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("true"))
        XCTAssertTrue(result!.contains("false"))
    }

    func testJSONToYAMLInvalidJSON() {
        let result = FormatConverter.convert("not json", from: .json, to: .yaml)
        XCTAssertNil(result)
    }

    // MARK: - YAML → JSON

    func testYAMLToJSONSimple() {
        let yaml = """
        name: test
        count: 42
        """
        let result = FormatConverter.convert(yaml, from: .yaml, to: .json)
        XCTAssertNotNil(result)
        let data = result!.data(using: .utf8)!
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(obj)
        XCTAssertEqual(obj?["name"] as? String, "test")
        XCTAssertEqual(obj?["count"] as? Int, 42)
    }

    func testYAMLToJSONBooleans() {
        let yaml = """
        enabled: true
        debug: false
        """
        let result = FormatConverter.convert(yaml, from: .yaml, to: .json)
        XCTAssertNotNil(result)
        let data = result!.data(using: .utf8)!
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertEqual(obj?["enabled"] as? Bool, true)
        XCTAssertEqual(obj?["debug"] as? Bool, false)
    }

    func testYAMLToJSONNull() {
        let yaml = "value: null\n"
        let result = FormatConverter.convert(yaml, from: .yaml, to: .json)
        XCTAssertNotNil(result)
    }

    func testYAMLToJSONSkipsComments() {
        let yaml = """
        # This is a comment
        key: value
        """
        let result = FormatConverter.convert(yaml, from: .yaml, to: .json)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("value"))
        XCTAssertFalse(result!.contains("comment"))
    }

    // MARK: - Markdown → Plain

    func testStripHeaders() {
        let md = "# Title\n## Subtitle\nText"
        let result = FormatConverter.convert(md, from: .markdown, to: .plain)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.contains("#"))
        XCTAssertTrue(result!.contains("Title"))
        XCTAssertTrue(result!.contains("Subtitle"))
    }

    func testStripBoldItalic() {
        let md = "This is **bold** and _italic_ text"
        let result = FormatConverter.convert(md, from: .markdown, to: .plain)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("bold"))
        XCTAssertTrue(result!.contains("italic"))
        XCTAssertFalse(result!.contains("**"))
        XCTAssertFalse(result!.contains("_italic_"))
    }

    func testStripLinks() {
        let md = "Click [here](https://example.com) please"
        let result = FormatConverter.convert(md, from: .markdown, to: .plain)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("here"))
        XCTAssertFalse(result!.contains("https://"))
        XCTAssertFalse(result!.contains("["))
    }

    func testStripInlineCode() {
        let md = "Use `let x = 1` in Swift"
        let result = FormatConverter.convert(md, from: .markdown, to: .plain)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("let x = 1"))
        // Check backticks removed
        XCTAssertFalse(result!.contains("`"))
    }

    func testStripStrikethrough() {
        let md = "This is ~~removed~~ text"
        let result = FormatConverter.convert(md, from: .markdown, to: .plain)
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("removed"))
        XCTAssertFalse(result!.contains("~~"))
    }

    // MARK: - Plain → Markdown

    func testPlainToMarkdownPassthrough() {
        let text = "Just plain text"
        let result = FormatConverter.convert(text, from: .plain, to: .markdown)
        XCTAssertEqual(result, text)
    }
}
