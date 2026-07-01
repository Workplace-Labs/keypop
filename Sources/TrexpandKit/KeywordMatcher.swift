import Foundation

/// Immediate-mode matcher: expand when buffer equals a keyword and no longer keyword shares that prefix.
public struct KeywordMatcher: Sendable {
    private let keywords: Set<String>
    private let maxKeywordLength: Int

    public init(keywords: [String]) {
        let normalized = Set(keywords.filter { !$0.isEmpty })
        self.keywords = normalized
        self.maxKeywordLength = normalized.map(\.count).max() ?? 0
    }

    public var bufferCapacity: Int {
        max(maxKeywordLength, 1)
    }

    public func match(in buffer: String) -> String? {
        guard keywords.contains(buffer) else { return nil }

        let longerPrefixExists = keywords.contains { keyword in
            keyword.count > buffer.count && keyword.hasPrefix(buffer)
        }
        return longerPrefixExists ? nil : buffer
    }

    public func shouldResetBuffer(for character: Character) -> Bool {
        if character == "\n" || character == "\t" {
            return true
        }
        let whitespace = CharacterSet.whitespacesAndNewlines
        return character.unicodeScalars.allSatisfy { whitespace.contains($0) }
    }
}
