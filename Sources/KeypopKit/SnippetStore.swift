import Foundation

public struct SnippetStore: Sendable {
    public private(set) var phrases: [String: String]

    public init(phrases: [String: String]) {
        self.phrases = phrases
    }

    public static func defaultPath() -> String {
        RuntimeExport.defaultSnippetsPath
    }

    public static func load(from path: String) throws -> SnippetStore {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let replacements = try KitFormat.parseReplacements(from: data)
        var map: [String: String] = [:]
        for replacement in replacements {
            map[replacement.shortcut] = replacement.phrase
        }
        return SnippetStore(phrases: map)
    }

    public mutating func replace(with other: SnippetStore) {
        phrases = other.phrases
    }

    public var keywords: [String] {
        Array(phrases.keys)
    }
}
