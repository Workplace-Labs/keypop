import AppKit
import Foundation
import os

/// Privacy-safe runtime diagnostics. Event fields must be metadata, never typed
/// characters, snippet text, clipboard contents, window titles, or file paths.
public struct DiagnosticSession: Sendable {
    public static let enabledKey = "KEYPOP_DIAGNOSTICS"
    public static let expiresAtKey = "KEYPOP_DIAGNOSTICS_UNTIL"

    public let expiresAt: Date?
    private let testNow: Date?

    public init(environment: [String: String] = ProcessInfo.processInfo.environment, now: Date? = nil) {
        testNow = now
        guard environment[Self.enabledKey] == "1",
              let rawExpiry = environment[Self.expiresAtKey],
              let seconds = TimeInterval(rawExpiry)
        else {
            expiresAt = nil
            return
        }

        let expiry = Date(timeIntervalSince1970: seconds)
        expiresAt = expiry
    }

    public var isEnabled: Bool { expiresAt.map { $0 > (testNow ?? Date()) } ?? false }
}

public enum KeypopDiagnostics {
    private static let subsystem = "io.keypop"

    public static func event(_ name: String, fields: [String: String] = [:]) {
        let line = recordLine(name, fields: fields)
        fputs("\(line)\n", stderr)
        logger(for: name).info("\(line, privacy: .public)")
    }

    public static func debugEvent(_ session: DiagnosticSession, _ name: String, fields: [String: String] = [:]) {
        guard session.isEnabled else { return }
        event(name, fields: fields)
    }

    public static func frontmostBundleID() -> String {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "(none)"
    }

    /// Pure and intentionally strict so report generation can trust this format.
    public static func recordLine(_ name: String, fields: [String: String] = [:]) -> String {
        let safeName = sanitize(name)
        let encodedFields = fields
            .map { "\(sanitize($0.key))=\(sanitize($0.value))" }
            .sorted()
        return (["diagnostic", safeName] + encodedFields).joined(separator: "|")
    }

    private static func sanitize(_ value: String) -> String {
        value.replacingOccurrences(of: "|", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
            .replacingOccurrences(of: "\r", with: "_")
    }

    private static func logger(for event: String) -> Logger {
        let category: String
        switch event {
        case let name where name.hasPrefix("tap_"):
            category = "tap"
        case let name where name.hasPrefix("health_"):
            category = "health"
        case let name where name.hasPrefix("inject") || name == "expansion":
            category = "inject"
        case let name where name.hasPrefix("watcher_"):
            category = "watcher"
        case let name where name.hasPrefix("permission_"):
            category = "permissions"
        default:
            category = "runtime"
        }
        return Logger(subsystem: subsystem, category: category)
    }
}
