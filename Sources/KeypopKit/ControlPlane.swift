import Foundation

/// Out-of-band daemon control that does not depend on the keyboard event tap.
///
/// `keypop heal` writes a request file; the running daemon's control watcher consumes it
/// and reinstalls the tap. If the daemon is dead, the CLI falls back to LaunchAgent restart.
public enum ControlPlane: Sendable {
    public static let controlDirectoryEnvironmentKey = "KEYPOP_CONTROL_DIR"

    public static var directoryPath: String {
        if let override = ProcessInfo.processInfo.environment[controlDirectoryEnvironmentKey], !override.isEmpty {
            return override
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.config/keypop/control"
    }

    public static var healRequestPath: String {
        "\(directoryPath)/heal"
    }

    public static func ensureDirectory(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true
        )
    }

    public static func requestHeal(
        reason: String,
        fileManager: FileManager = .default,
        now: Date = Date()
    ) throws {
        try ensureDirectory(fileManager: fileManager)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let body = [
            "reason=\(sanitize(reason))",
            "requested_at=\(formatter.string(from: now))",
            "",
        ].joined(separator: "\n")
        try Data(body.utf8).write(to: URL(fileURLWithPath: healRequestPath), options: .atomic)
    }

    /// Returns the request reason if a heal file was present, and deletes it.
    public static func consumeHealRequest(fileManager: FileManager = .default) -> String? {
        let path = healRequestPath
        guard fileManager.fileExists(atPath: path) else { return nil }
        let reason = (try? String(contentsOfFile: path, encoding: .utf8))
            .flatMap { lineValue(named: "reason", in: $0) } ?? "control"
        try? fileManager.removeItem(atPath: path)
        return reason
    }

    public static func healRequestPending(fileManager: FileManager = .default) -> Bool {
        fileManager.fileExists(atPath: healRequestPath)
    }

    private static func lineValue(named key: String, in body: String) -> String? {
        let prefix = "\(key)="
        for line in body.split(whereSeparator: \.isNewline) {
            let text = String(line)
            if text.hasPrefix(prefix) {
                return String(text.dropFirst(prefix.count))
            }
        }
        return nil
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "\n", with: "_")
            .replacingOccurrences(of: "\r", with: "_")
    }
}
