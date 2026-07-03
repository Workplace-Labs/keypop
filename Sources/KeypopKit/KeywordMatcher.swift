import Foundation

public struct KeywordCollision: Sendable, Equatable {
    public let prefix: String
    public let keyword: String

    public init(prefix: String, keyword: String) {
        self.prefix = prefix
        self.keyword = keyword
    }
}

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

    public static func collisions(for keyword: String, among keywords: [String]) -> [KeywordCollision] {
        collisions(among: keywords + [keyword]).filter { collision in
            collision.prefix == keyword || collision.keyword == keyword
        }
    }

    public static func collisions(among keywords: [String]) -> [KeywordCollision] {
        let normalized = Set(keywords.filter { !$0.isEmpty }).sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }

        var collisions: [KeywordCollision] = []
        for (index, prefix) in normalized.enumerated() {
            for keyword in normalized.dropFirst(index + 1) where keyword.hasPrefix(prefix) {
                collisions.append(KeywordCollision(prefix: prefix, keyword: keyword))
            }
        }

        return collisions.sorted { left, right in
            if left.prefix == right.prefix {
                return left.keyword.localizedStandardCompare(right.keyword) == .orderedAscending
            }
            return left.prefix.localizedStandardCompare(right.prefix) == .orderedAscending
        }
    }

    public func shouldResetBuffer(for character: Character) -> Bool {
        if character == "\n" || character == "\t" {
            return true
        }
        let whitespace = CharacterSet.whitespacesAndNewlines
        return character.unicodeScalars.allSatisfy { whitespace.contains($0) }
    }
}
