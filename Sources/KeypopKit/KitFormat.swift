import Foundation

public struct Replacement: Codable, Equatable {
    public let shortcut: String
    public let phrase: String

    public init(shortcut: String, phrase: String) {
        self.shortcut = shortcut
        self.phrase = phrase
    }
}

/// JSON kit entry: `name`, `keyword`, `text` (Raycast-compatible shape).
public struct SnippetEntry: Codable, Equatable {
    public let name: String
    public let keyword: String
    public let text: String

    public init(name: String, keyword: String, text: String) {
        self.name = name
        self.keyword = keyword
        self.text = text
    }

    public init(replacement: Replacement, name: String? = nil) {
        self.name = name ?? SnippetEntry.defaultName(for: replacement.shortcut)
        self.keyword = replacement.shortcut
        self.text = replacement.phrase
    }

    public var replacement: Replacement {
        Replacement(shortcut: keyword, phrase: text)
    }

    public static func defaultName(for shortcut: String) -> String {
        let bare = shortcut.hasPrefix(";") ? String(shortcut.dropFirst()) : shortcut
        return bare.isEmpty ? shortcut : bare.prefix(1).uppercased() + bare.dropFirst()
    }
}

public enum KitFormatError: Error, CustomStringConvertible {
    case invalidRoot
    case invalidEntry(Int)
    case missingKeyword(Int)
    case missingText(Int)

    public var description: String {
        switch self {
        case .invalidRoot:
            return "Kit file must be a JSON array of snippet objects (name, keyword, text)"
        case .invalidEntry(let index):
            return "Kit entry \(index) is not a valid snippet object"
        case .missingKeyword(let index):
            return "Kit entry \(index) is missing keyword"
        case .missingText(let index):
            return "Kit entry \(index) is missing text"
        }
    }
}

public enum KitFormat {
    public static func parseReplacements(from data: Data) throws -> [Replacement] {
        let entries: [SnippetEntry]
        do {
            entries = try JSONDecoder().decode([SnippetEntry].self, from: data)
        } catch {
            throw KitFormatError.invalidRoot
        }

        return try entries.enumerated().map { index, entry in
            guard !entry.keyword.isEmpty else {
                throw KitFormatError.missingKeyword(index)
            }
            guard !entry.text.isEmpty else {
                throw KitFormatError.missingText(index)
            }
            return entry.replacement
        }
    }

    public static func snippetEntries(from replacements: [Replacement]) -> [SnippetEntry] {
        replacements.map { SnippetEntry(replacement: $0) }
    }

    public static func encode(_ replacements: [Replacement]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(snippetEntries(from: replacements))
    }
}
