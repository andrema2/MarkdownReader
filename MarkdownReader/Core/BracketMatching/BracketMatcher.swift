import Foundation

/// Finds matching bracket/quote pairs in source text.
enum BracketMatcher {
    /// Characters that have a matching closing counterpart.
    static let openToClose: [Character: Character] = [
        "{": "}",
        "[": "]",
        "(": ")",
        "<": ">",
    ]

    static let closeToOpen: [Character: Character] = [
        "}": "{",
        "]": "[",
        ")": "(",
        ">": "<",
    ]

    /// Quote characters that are self-matching.
    static let quotes: Set<Character> = ["\"", "'", "`"]

    /// Finds the matching bracket/quote position for the character at the given location.
    /// Returns nil if no match found or character is not a bracket/quote.
    static func findMatch(in string: NSString, at location: Int) -> NSRange? {
        guard location >= 0 && location < string.length else { return nil }

        let char = Character(UnicodeScalar(string.character(at: location))!)

        // Check opening brackets
        if let closeChar = openToClose[char] {
            return findForward(in: string, from: location, open: char, close: closeChar)
        }

        // Check closing brackets
        if let openChar = closeToOpen[char] {
            return findBackward(in: string, from: location, open: openChar, close: char)
        }

        // Check quotes
        if quotes.contains(char) {
            return findMatchingQuote(in: string, at: location, quote: char)
        }

        // Also check the character before cursor (common case: cursor is after bracket)
        if location > 0 {
            let prevChar = Character(UnicodeScalar(string.character(at: location - 1))!)
            if let closeChar = openToClose[prevChar] {
                return findForward(in: string, from: location - 1, open: prevChar, close: closeChar)
            }
            if let openChar = closeToOpen[prevChar] {
                return findBackward(in: string, from: location - 1, open: openChar, close: prevChar)
            }
        }

        return nil
    }

    /// Searches forward for the matching close bracket, respecting nesting.
    private static func findForward(in string: NSString, from start: Int, open: Character, close: Character) -> NSRange? {
        var depth = 0
        let openScalar = open.unicodeScalars.first!.value
        let closeScalar = close.unicodeScalars.first!.value

        for i in start..<string.length {
            let ch = string.character(at: i)
            if ch == UInt16(openScalar) {
                depth += 1
            } else if ch == UInt16(closeScalar) {
                depth -= 1
                if depth == 0 {
                    return NSRange(location: i, length: 1)
                }
            }
        }
        return nil
    }

    /// Searches backward for the matching open bracket, respecting nesting.
    private static func findBackward(in string: NSString, from start: Int, open: Character, close: Character) -> NSRange? {
        var depth = 0
        let openScalar = open.unicodeScalars.first!.value
        let closeScalar = close.unicodeScalars.first!.value

        for i in stride(from: start, through: 0, by: -1) {
            let ch = string.character(at: i)
            if ch == UInt16(closeScalar) {
                depth += 1
            } else if ch == UInt16(openScalar) {
                depth -= 1
                if depth == 0 {
                    return NSRange(location: i, length: 1)
                }
            }
        }
        return nil
    }

    /// Finds the matching quote. For quotes, we look for the nearest unescaped quote
    /// of the same type in both directions and pick the one that makes a valid pair.
    private static func findMatchingQuote(in string: NSString, at location: Int, quote: Character) -> NSRange? {
        let quoteScalar = UInt16(quote.unicodeScalars.first!.value)
        let backslash = UInt16(UnicodeScalar("\\").value)

        // Count quotes before this position to determine if this is opening or closing
        var quotesBefore = 0
        for i in 0..<location {
            if string.character(at: i) == quoteScalar {
                // Check if escaped
                if i > 0 && string.character(at: i - 1) == backslash {
                    continue
                }
                quotesBefore += 1
            }
        }

        let isOpeningQuote = quotesBefore % 2 == 0

        if isOpeningQuote {
            // Search forward for closing quote
            for i in (location + 1)..<string.length {
                if string.character(at: i) == quoteScalar {
                    if i > 0 && string.character(at: i - 1) == backslash { continue }
                    return NSRange(location: i, length: 1)
                }
            }
        } else {
            // Search backward for opening quote
            for i in stride(from: location - 1, through: 0, by: -1) {
                if string.character(at: i) == quoteScalar {
                    if i > 0 && string.character(at: i - 1) == backslash { continue }
                    return NSRange(location: i, length: 1)
                }
            }
        }

        return nil
    }
}
