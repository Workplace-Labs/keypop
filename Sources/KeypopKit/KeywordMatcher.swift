import Foundation

public struct KeywordCollision: Sendable, Equatable {
    public let prefix: String
    public let keyword: String

    public init(prefix: String, keyword: String) {
        self.prefix = prefix
        self.keyword = keyword
    }
}

struct KeywordMatcherStep: Sendable, Equatable {
    let state: String
    let match: String?

    init(state: String, match: String? = nil) {
        self.state = state
        self.match = match
    }
}

/// Immediate-mode matcher: expand when buffer equals a keyword and no longer keyword shares that prefix.
public struct KeywordMatcher: Sendable {
    private let keywords: Set<String>
    private let prefixes: Set<String>

    public init(keywords: [String]) {
        let normalized = Set(keywords.filter { !$0.isEmpty })
        self.keywords = normalized
        self.prefixes = Set(normalized.flatMap { keyword in
            (1...keyword.count).map { String(keyword.prefix($0)) }
        })
    }

    /// Keeps only the longest suffix that can still become a keyword.
    func advance(_ character: Character, from state: String) -> KeywordMatcherStep {
        let input = state + String(character)
        let matches = keywords.filter { input.hasSuffix($0) }

        if let match = matches.max(by: { $0.count < $1.count }) {
            let longerPrefixExists = keywords.contains { keyword in
                keyword.count > match.count && keyword.hasPrefix(match)
            }
            if !longerPrefixExists {
                return KeywordMatcherStep(state: "", match: match)
            }
        }

        let candidate = prefixes
            .filter { input.hasSuffix($0) }
            .max(by: { $0.count < $1.count }) ?? ""
        return KeywordMatcherStep(state: candidate)
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

}
