import Foundation

/// Always-on runtime keywords. Merged over user phrases so heal/self-test cannot be shadowed.
public enum BuiltInSnippets: Sendable {
    public static let fixKeyword = ";kpfix"
    public static let fixPhrase = "KeyPop OK"

    public static let phrases: [String: String] = [
        fixKeyword: fixPhrase,
    ]

    public static func merging(with userPhrases: [String: String]) -> [String: String] {
        var merged = userPhrases
        for (keyword, phrase) in phrases {
            merged[keyword] = phrase
        }
        return merged
    }
}
