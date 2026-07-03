import Foundation
import KeypopKit

enum StatsCommands {
    struct Row: Codable {
        let keyword: String
        let count: Int
        let lastUsedAt: String
    }

    static func usage() -> String {
        """
        keypop stats — local KeyPop runtime usage counts

        Usage:
          keypop stats [--prefix <prefix>]
          keypop stats reset [--shortcut <shortcut>|--all]
        """
    }

    static func optionalValue(after flag: String, in args: [String]) -> String? {
        guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
            return nil
        }
        return args[index + 1]
    }

    static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        FileHandle.standardOutput.write(data)
        print("")
    }

    static func run(args: [String]) throws {
        let store = UsageStore()
        if args.first == "reset" {
            let rest = Array(args.dropFirst())
            if rest.contains("--all") {
                try store.reset()
                try printJSON(["reset": "all"])
                return
            }
            if let shortcut = optionalValue(after: "--shortcut", in: rest) {
                try store.reset(keyword: shortcut)
                try printJSON(["reset": shortcut])
                return
            }
            throw CLIError.usage(usage())
        }

        let prefix = optionalValue(after: "--prefix", in: args)
        let rows = try store.records(prefix: prefix)
            .map { keyword, record in
                Row(keyword: keyword, count: record.count, lastUsedAt: record.lastUsedAt)
            }
            .sorted { left, right in
                if left.count == right.count {
                    return left.keyword.localizedStandardCompare(right.keyword) == .orderedAscending
                }
                return left.count > right.count
            }
        try printJSON(rows)
    }
}
