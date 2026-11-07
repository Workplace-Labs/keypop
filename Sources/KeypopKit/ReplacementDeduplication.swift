import Darwin
import Foundation

public struct ReplacementDuplicateWarning: Equatable, Sendable {
    public let shortcut: String
    public let keptPhrase: String
    public let droppedPhrases: [String]

    public init(shortcut: String, keptPhrase: String, droppedPhrases: [String]) {
        self.shortcut = shortcut
        self.keptPhrase = keptPhrase
        self.droppedPhrases = droppedPhrases
    }
}

/// Collapses duplicate shortcut/keyword rows to one entry per key.
public enum ReplacementDeduplication {
    /// When several rows share a shortcut, the **last** row in source order wins (matches prior daemon map behavior).
    public static func deduplicate(_ rows: [Replacement]) -> (deduplicated: [Replacement], warnings: [ReplacementDuplicateWarning]) {
        deduplicate(entries: rows, key: \.shortcut, phrase: \.phrase, make: { $0 })
    }

    public static func deduplicateEntries(_ entries: [SnippetEntry]) -> (deduplicated: [SnippetEntry], warnings: [ReplacementDuplicateWarning]) {
        deduplicate(
            entries: entries,
            key: \.keyword,
            phrase: \.text,
            make: { $0 }
        )
    }

    public static func emitWarnings(_ warnings: [ReplacementDuplicateWarning], to stream: UnsafeMutablePointer<FILE> = stderr) {
        guard !warnings.isEmpty else { return }
        for warning in warnings {
            let dropped = warning.droppedPhrases.joined(separator: ";;")
            fputs(
                "keypop_duplicate|shortcut=\(warning.shortcut)|kept=\(warning.keptPhrase)|dropped=\(dropped)\n",
                stream
            )
        }
    }

    private static func deduplicate<Element>(
        entries: [Element],
        key: KeyPath<Element, String>,
        phrase: KeyPath<Element, String>,
        make: (Element) -> Element
    ) -> (deduplicated: [Element], warnings: [ReplacementDuplicateWarning]) {
        var order: [String] = []
        var byKey: [String: Element] = [:]
        var droppedPhrases: [String: [String]] = [:]

        for entry in entries {
            let shortcut = entry[keyPath: key]
            if let existing = byKey[shortcut] {
                droppedPhrases[shortcut, default: []].append(existing[keyPath: phrase])
                byKey[shortcut] = make(entry)
            } else {
                order.append(shortcut)
                byKey[shortcut] = make(entry)
            }
        }

        let deduplicated = order.compactMap { byKey[$0] }
        let warnings = droppedPhrases.keys.sorted().compactMap { shortcut -> ReplacementDuplicateWarning? in
            guard let kept = byKey[shortcut], let dropped = droppedPhrases[shortcut], !dropped.isEmpty else {
                return nil
            }
            return ReplacementDuplicateWarning(
                shortcut: shortcut,
                keptPhrase: kept[keyPath: phrase],
                droppedPhrases: dropped
            )
        }
        return (deduplicated, warnings)
    }
}
