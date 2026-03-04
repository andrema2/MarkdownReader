import XCTest
@testable import MarkEdit

final class FileIOTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Read

    func testReadUTF8File() throws {
        let file = tempDir.appendingPathComponent("test.txt")
        let content = "Hello, World! 🌍"
        try content.write(to: file, atomically: true, encoding: .utf8)

        let (readContent, encoding) = try FileIO.read(from: file)
        XCTAssertEqual(readContent, content)
        XCTAssertEqual(encoding, .utf8)
    }

    func testReadEmptyFile() throws {
        let file = tempDir.appendingPathComponent("empty.txt")
        try "".write(to: file, atomically: true, encoding: .utf8)

        let (readContent, _) = try FileIO.read(from: file)
        XCTAssertEqual(readContent, "")
    }

    func testReadMultilineFile() throws {
        let file = tempDir.appendingPathComponent("multi.txt")
        let content = "Line 1\nLine 2\nLine 3"
        try content.write(to: file, atomically: true, encoding: .utf8)

        let (readContent, _) = try FileIO.read(from: file)
        XCTAssertEqual(readContent, content)
    }

    func testReadNonExistentFileThrows() {
        let file = tempDir.appendingPathComponent("doesnotexist.txt")
        XCTAssertThrowsError(try FileIO.read(from: file))
    }

    // MARK: - Write

    func testWriteFile() throws {
        let file = tempDir.appendingPathComponent("output.txt")
        try FileIO.write("Test content", to: file)

        let readBack = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(readBack, "Test content")
    }

    func testWriteOverwritesExisting() throws {
        let file = tempDir.appendingPathComponent("overwrite.txt")
        try FileIO.write("First", to: file)
        try FileIO.write("Second", to: file)

        let readBack = try String(contentsOf: file, encoding: .utf8)
        XCTAssertEqual(readBack, "Second")
    }

    func testWriteWithEncoding() throws {
        let file = tempDir.appendingPathComponent("utf16.txt")
        try FileIO.write("Hello", to: file, encoding: .utf16)

        let data = try Data(contentsOf: file)
        XCTAssertGreaterThan(data.count, 5) // UTF-16 uses 2 bytes per char + BOM
    }

    // MARK: - Round Trip

    func testReadWriteRoundTrip() throws {
        let file = tempDir.appendingPathComponent("roundtrip.json")
        let json = """
        {
          "name": "test",
          "value": 42
        }
        """
        try FileIO.write(json, to: file)
        let (readContent, _) = try FileIO.read(from: file)
        XCTAssertEqual(readContent, json)
    }

    func testReadWriteUnicode() throws {
        let file = tempDir.appendingPathComponent("unicode.md")
        let content = "# Título com acentos 日本語 🎉"
        try FileIO.write(content, to: file)
        let (readContent, _) = try FileIO.read(from: file)
        XCTAssertEqual(readContent, content)
    }
}
