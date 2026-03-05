import Foundation
import Combine

class FindReplaceEngine: ObservableObject {
    @Published var searchText = ""
    @Published var replaceText = ""
    @Published var caseSensitive = false
    @Published var useRegex = false
    @Published var wholeWord = false
    @Published var matches: [NSRange] = []
    @Published var currentMatchIndex: Int = -1

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Re-run search whenever search text or options change
        Publishers.CombineLatest4(
            $searchText,
            $caseSensitive,
            $useRegex,
            $wholeWord
        )
        .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.needsSearch = true
        }
        .store(in: &cancellables)
    }

    /// Flag set when search parameters change; the view layer triggers the actual search
    /// by calling `search(in:)` with the current content.
    @Published var needsSearch = false

    // MARK: - Search

    func search(in content: String) {
        needsSearch = false
        guard !searchText.isEmpty else {
            matches = []
            currentMatchIndex = -1
            return
        }

        let nsContent = content as NSString
        var results: [NSRange] = []

        if useRegex {
            var options: NSRegularExpression.Options = []
            if !caseSensitive {
                options.insert(.caseInsensitive)
            }
            var pattern = searchText
            if wholeWord {
                pattern = "\\b\(pattern)\\b"
            }
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                matches = []
                currentMatchIndex = -1
                return
            }
            let nsMatches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
            results = nsMatches.map(\.range)
        } else {
            var searchOptions: NSString.CompareOptions = []
            if !caseSensitive {
                searchOptions.insert(.caseInsensitive)
            }

            let term: String
            if wholeWord {
                // For non-regex whole word, we use regex internally
                var regexOptions: NSRegularExpression.Options = []
                if !caseSensitive {
                    regexOptions.insert(.caseInsensitive)
                }
                let escaped = NSRegularExpression.escapedPattern(for: searchText)
                let pattern = "\\b\(escaped)\\b"
                guard let regex = try? NSRegularExpression(pattern: pattern, options: regexOptions) else {
                    matches = []
                    currentMatchIndex = -1
                    return
                }
                let nsMatches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
                results = nsMatches.map(\.range)
                matches = results
                adjustCurrentIndex()
                return
            }

            term = searchText
            var searchRange = NSRange(location: 0, length: nsContent.length)
            while searchRange.location < nsContent.length {
                let foundRange = nsContent.range(of: term, options: searchOptions, range: searchRange)
                if foundRange.location == NSNotFound { break }
                results.append(foundRange)
                searchRange.location = foundRange.location + max(foundRange.length, 1)
                searchRange.length = nsContent.length - searchRange.location
            }
        }

        matches = results
        adjustCurrentIndex()
    }

    private func adjustCurrentIndex() {
        if matches.isEmpty {
            currentMatchIndex = -1
        } else if currentMatchIndex < 0 || currentMatchIndex >= matches.count {
            currentMatchIndex = 0
        }
    }

    // MARK: - Navigation

    func nextMatch() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % matches.count
    }

    func previousMatch() {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + matches.count) % matches.count
    }

    // MARK: - Replace

    func replaceCurrent(in content: inout String) {
        guard currentMatchIndex >= 0 && currentMatchIndex < matches.count else { return }
        let range = matches[currentMatchIndex]
        guard let swiftRange = Range(range, in: content) else { return }
        content.replaceSubrange(swiftRange, with: replaceText)
        // Re-search after replacement
        search(in: content)
    }

    func replaceAll(in content: inout String) {
        guard !matches.isEmpty else { return }
        // Replace from end to start to preserve ranges
        for range in matches.reversed() {
            guard let swiftRange = Range(range, in: content) else { continue }
            content.replaceSubrange(swiftRange, with: replaceText)
        }
        search(in: content)
    }
}
