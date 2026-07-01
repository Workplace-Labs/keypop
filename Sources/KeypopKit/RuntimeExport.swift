import Foundation

/// Exports live replacements for the `keypop run` runtime.
public enum RuntimeExport {
    public static let snippetsPathEnvironmentKey = "KEYPOP_SNIPPETS"
    public static let disableEnvironmentKey = "KEYPOP_SYNC"

    public static var defaultSnippetsPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.config/keypop/snippets.json"
    }

    public static func snippetsPath() -> String {
        if let override = ProcessInfo.processInfo.environment[snippetsPathEnvironmentKey], !override.isEmpty {
            return override
        }
        return defaultSnippetsPath
    }

    public static func isEnabled(commandArgs: [String]) -> Bool {
        if commandArgs.contains("--no-sync") {
            return false
        }
        if let value = ProcessInfo.processInfo.environment[disableEnvironmentKey] {
            switch value.lowercased() {
            case "0", "false", "no", "off":
                return false
            default:
                break
            }
        }
        return true
    }

    @discardableResult
    public static func write(_ rows: [Replacement]) throws -> String {
        let path = snippetsPath()
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try KitFormat.encode(rows).write(to: URL(fileURLWithPath: path), options: .atomic)
        return path
    }
}
