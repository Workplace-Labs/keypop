import Foundation

public struct KeywordCollision: Sendable, Equatable {
    public let keyword: String
    public let collidesWith: String

    public init(keyword: String, collidesWith: String) {
        self.keyword = keyword
        self.collidesWith = collidesWith
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
        let normalized = Set(keywords.filter { !$0.isEmpty && $0 != keyword })
        return normalized.compactMap { other in
            guard keyword.hasPrefix(other) || other.hasPrefix(keyword) else {
                return nil
            }
            return KeywordCollision(keyword: keyword, collidesWith: other)
        }
        .sorted { left, right in
            left.collidesWith.localizedStandardCompare(right.collidesWith) == .orderedAscending
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
