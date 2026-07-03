import Foundation

public struct UsageRecord: Codable, Equatable, Sendable {
    public let count: Int
    public let lastUsedAt: String

    public init(count: Int, lastUsedAt: String) {
        self.count = count
        self.lastUsedAt = lastUsedAt
    }
}

public final class UsageStore {
    public static let usagePathEnvironmentKey = "KEYPOP_USAGE"

    public static var defaultPath: String {
        if let override = ProcessInfo.processInfo.environment[usagePathEnvironmentKey], !override.isEmpty {
            return override
        }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.config/keypop/usage.json"
    }

    private let path: String
    private let fileManager: FileManager

    public init(path: String = UsageStore.defaultPath, fileManager: FileManager = .default) {
        self.path = path
        self.fileManager = fileManager
    }

    public func records() throws -> [String: UsageRecord] {
        guard fileManager.fileExists(atPath: path) else {
            return [:]
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        guard !data.isEmpty else {
            return [:]
        }
        return try JSONDecoder().decode([String: UsageRecord].self, from: data)
    }

    public func recordUse(keyword: String, at date: Date = Date()) throws {
        var current = try records()
        let previous = current[keyword]
        current[keyword] = UsageRecord(
            count: (previous?.count ?? 0) + 1,
            lastUsedAt: Self.timestamp(for: date)
        )
        try write(current)
    }

    public func reset(keyword: String? = nil) throws {
        if let keyword {
            var current = try records()
            current.removeValue(forKey: keyword)
            try write(current)
            return
        }
        try write([:])
    }

    public func records(prefix: String?) throws -> [String: UsageRecord] {
        let current = try records()
        guard let prefix else {
            return current
        }
        return current.filter { keyword, _ in keyword.hasPrefix(prefix) }
    }

    private func write(_ records: [String: UsageRecord]) throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: url, options: .atomic)
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
