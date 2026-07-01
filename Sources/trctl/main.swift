import Darwin
import Foundation
import KSPrivateBridge
import TrctlKit

struct ImportPlan: Codable {
    let create: [Replacement]
    let update: [Replacement]
    let skip: [Replacement]
    let conflicts: [Replacement]
}

enum ConflictMode: String {
    case fail
    case skip
    case overwrite
}

enum CLIError: Error, CustomStringConvertible {
    case usage(String)
    case runtime(String)

    var description: String {
        switch self {
        case .usage(let message), .runtime(let message):
            return message
        }
    }
}

func printJSON<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    FileHandle.standardOutput.write(data)
    print("")
}

func printJSONObject(_ value: Any) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(data)
    print("")
}

func textReplacementDatabaseURL() -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/KeyboardServices/TextReplacements.db")
}

func runSQLite(_ arguments: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
    process.arguments = arguments

    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    try process.run()
    process.waitUntilExit()

    let stdout = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    let stderr = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    guard process.terminationStatus == 0 else {
        throw CLIError.runtime(stderr.isEmpty ? "sqlite3 exited with status \(process.terminationStatus)" : stderr)
    }
    return stdout
}

func databaseSummary() throws -> [String: Any] {
    let db = textReplacementDatabaseURL().path
    let tableOutput = try runSQLite([db, ".tables"])
    let schemaOutput = try runSQLite([
        db,
        ".schema ZTEXTREPLACEMENTENTRY",
        ".schema ZTRCLOUDKITSYNCSTATE",
        "select count(*) from ZTEXTREPLACEMENTENTRY where ZWASDELETED = 0;"
    ])

    return [
        "databasePath": db,
        "exists": FileManager.default.fileExists(atPath: db),
        "tables": tableOutput.split(whereSeparator: { $0.isWhitespace }).map(String.init),
        "schemaAndActiveCount": schemaOutput
    ]
}

func bridgeError(_ error: NSError?) -> CLIError {
    .runtime(error?.localizedDescription ?? "Unknown KeyboardServices bridge error")
}

func value(after flag: String, in args: [String]) throws -> String {
    guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
        throw CLIError.usage("Missing \(flag)")
    }
    return args[index + 1]
}

func optionalValue(after flag: String, in args: [String]) -> String? {
    guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
        return nil
    }
    return args[index + 1]
}

func replacements() throws -> [Replacement] {
    var nsError: NSError?
    let rows = KSTextReplacementList(&nsError)
    if let nsError {
        throw bridgeError(nsError)
    }

    return try rows.map { row in
        guard let shortcut = row["shortcut"] as? String, let phrase = row["phrase"] as? String else {
            throw CLIError.runtime("KeyboardServices returned a malformed replacement row")
        }
        return Replacement(shortcut: shortcut, phrase: phrase)
    }
    .sorted { left, right in
        left.shortcut.localizedStandardCompare(right.shortcut) == .orderedAscending
    }
}

func replacementMap(_ rows: [Replacement]) -> [String: Replacement] {
    Dictionary(uniqueKeysWithValues: rows.map { ($0.shortcut, $0) })
}

func filterReplacements(_ rows: [Replacement], prefix: String?) -> [Replacement] {
    guard let prefix else {
        return rows
    }
    return rows.filter { $0.shortcut.hasPrefix(prefix) }
}

func createReplacement(shortcut: String, phrase: String) throws {
    var nsError: NSError?
    guard KSPrivateCreate(shortcut, phrase, &nsError) else {
        throw bridgeError(nsError)
    }
}

func updateReplacement(shortcut: String, phrase: String) throws {
    var nsError: NSError?
    guard KSPrivateUpdate(shortcut, phrase, &nsError) else {
        throw bridgeError(nsError)
    }
}

func deleteReplacement(shortcut: String) throws {
    var nsError: NSError?
    guard KSPrivateDelete(shortcut, &nsError) else {
        throw bridgeError(nsError)
    }
}

func readImportFile(_ path: String) throws -> [Replacement] {
    let data: Data
    if path == "-" {
        data = FileHandle.standardInput.readDataToEndOfFile()
    } else {
        data = try Data(contentsOf: URL(fileURLWithPath: path))
    }
    return try KitFormat.parseReplacements(from: data)
}

func writeKitFile(_ replacements: [Replacement], to path: String) throws {
    try KitFormat.encode(replacements).write(to: URL(fileURLWithPath: path), options: .atomic)
}

func stableReplacements(maxAttempts: Int = 12, delayMicros: UInt32 = 250_000) throws -> [Replacement] {
    // KeyboardServices reads can lag writes; wait before sampling.
    usleep(500_000)

    var previous = try replacements()
    guard maxAttempts > 1 else { return previous }

    for _ in 1 ..< maxAttempts {
        usleep(delayMicros)
        let current = try replacements()
        if current == previous {
            return current
        }
        previous = current
    }
    return previous
}

func syncExpanderIfEnabled(commandArgs: [String]) {
    guard ExpanderExport.isEnabled(commandArgs: commandArgs) else { return }
    do {
        let rows = try stableReplacements()
        let path = try ExpanderExport.write(rows)
        fputs("trexpand_sync|\(path)|\(rows.count)\n", stderr)
        hintIfTrexpandNotRunning()
    } catch {
        fputs("trexpand_sync_error|\(error)\n", stderr)
    }
}

func trexpandProcessIsRunning() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-f", "trexpand run --snippets"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do {
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    } catch {
        return false
    }
}

func hintIfTrexpandNotRunning() {
    guard !trexpandProcessIsRunning() else { return }
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    fputs("trexpand_hint|daemon not running; run: ./scripts/launch-trexpand.sh restart\n", stderr)
    fputs("trexpand_hint|grant Input Monitoring + Accessibility to \(home)/.local/Trexpand.app\n", stderr)
}

func validateUniqueShortcuts(_ rows: [Replacement]) throws {
    var seen = Set<String>()
    var duplicates = Set<String>()
    for row in rows {
        if row.shortcut.isEmpty {
            throw CLIError.usage("Import contains an empty shortcut")
        }
        if !seen.insert(row.shortcut).inserted {
            duplicates.insert(row.shortcut)
        }
    }
    if !duplicates.isEmpty {
        throw CLIError.usage("Import contains duplicate shortcuts: \(duplicates.sorted().joined(separator: ", "))")
    }
}

func validatePrefix(_ rows: [Replacement], prefix: String) throws {
    let outOfScope = rows.map(\.shortcut).filter { !$0.hasPrefix(prefix) }.sorted()
    if !outOfScope.isEmpty {
        throw CLIError.usage("Import contains shortcuts outside prefix \(prefix): \(outOfScope.joined(separator: ", "))")
    }
}

func buildImportPlan(incoming: [Replacement], existing: [Replacement], conflictMode: ConflictMode) -> ImportPlan {
    let existingByShortcut = replacementMap(existing)
    var create: [Replacement] = []
    var update: [Replacement] = []
    var skip: [Replacement] = []
    var conflicts: [Replacement] = []

    for row in incoming {
        guard let current = existingByShortcut[row.shortcut] else {
            create.append(row)
            continue
        }

        if current == row {
            skip.append(row)
            continue
        }

        switch conflictMode {
        case .fail:
            conflicts.append(row)
        case .skip:
            skip.append(row)
        case .overwrite:
            update.append(row)
        }
    }

    return ImportPlan(create: create, update: update, skip: skip, conflicts: conflicts)
}

func backupsDirectory() -> URL {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("backups", isDirectory: true)
}

func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
}

func writeBackup(_ rows: [Replacement]) throws -> URL {
    let directory = backupsDirectory()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appendingPathComponent("text-replacements-\(timestamp()).json")
    try writeKitFile(rows, to: url.path)
    return url
}

func usage() -> String {
    """
    Kit files use JSON snippet format (name, keyword, text).

    Usage:
      trctl list [--prefix <prefix>]
      trctl get --shortcut <shortcut>
      trctl export [--prefix <prefix>] [--output <path>]
      trctl create --shortcut <shortcut> --phrase <phrase>
      trctl update --shortcut <shortcut> --phrase <phrase>
      trctl delete --shortcut <shortcut>
      trctl import <path|-> [--prefix <prefix>] [--dry-run|--apply] [--on-conflict fail|skip|overwrite] [--no-sync-expander]

    Mutations auto-export to ~/.config/trexpand/snippets.json for trexpand (disable: --no-sync-expander or TREXPAND_SYNC=0).

    Diagnostics:
      trctl inspect
      trctl read-sources
      trctl db-summary

    Examples:
      trctl create --shortcut ';wle' --phrase 'you@example.com'
      trctl update --shortcut ';pcr' --phrase 'Review this change…'
      trctl list --prefix ';p'
      trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run
      trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
      trctl export --prefix ';wl' --output kits/wl-team.snippets.json
    """
}

func main() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.isEmpty || args.first == "--help" || args.first == "-h" || args.first == "help" {
        print(usage())
        return
    }
    guard let command = args.first else {
        throw CLIError.usage(usage())
    }
    let commandArgs = Array(args.dropFirst())

    switch command {
    case "list":
        let prefix = optionalValue(after: "--prefix", in: commandArgs)
        let rows = filterReplacements(try replacements(), prefix: prefix)
        try printJSON(KitFormat.snippetEntries(from: rows))
    case "get":
        let shortcut = try value(after: "--shortcut", in: commandArgs)
        guard let row = try replacements().first(where: { $0.shortcut == shortcut }) else {
            throw CLIError.runtime("No replacement found for shortcut \(shortcut)")
        }
        try printJSON(SnippetEntry(replacement: row))
    case "export":
        let prefix = optionalValue(after: "--prefix", in: commandArgs)
        let rows = try filterReplacements(replacements(), prefix: prefix)
        if let output = optionalValue(after: "--output", in: commandArgs) {
            try writeKitFile(rows, to: output)
            try printJSONObject(["exported": rows.count, "format": "snippet-kit", "output": output])
        } else {
            try printJSON(KitFormat.snippetEntries(from: rows))
        }
    case "create":
        let shortcut = try value(after: "--shortcut", in: commandArgs)
        let phrase = try value(after: "--phrase", in: commandArgs)
        if try replacements().contains(where: { $0.shortcut == shortcut }) {
            throw CLIError.runtime("Replacement already exists for shortcut \(shortcut)")
        }
        try createReplacement(shortcut: shortcut, phrase: phrase)
        syncExpanderIfEnabled(commandArgs: commandArgs)
        try printJSON(["created": shortcut])
    case "update":
        let shortcut = try value(after: "--shortcut", in: commandArgs)
        let phrase = try value(after: "--phrase", in: commandArgs)
        if try !replacements().contains(where: { $0.shortcut == shortcut }) {
            throw CLIError.runtime("No replacement found for shortcut \(shortcut)")
        }
        try updateReplacement(shortcut: shortcut, phrase: phrase)
        syncExpanderIfEnabled(commandArgs: commandArgs)
        try printJSON(["updated": shortcut])
    case "delete":
        let shortcut = try value(after: "--shortcut", in: commandArgs)
        if try !replacements().contains(where: { $0.shortcut == shortcut }) {
            throw CLIError.runtime("No replacement found for shortcut \(shortcut)")
        }
        try deleteReplacement(shortcut: shortcut)
        syncExpanderIfEnabled(commandArgs: commandArgs)
        try printJSON(["deleted": shortcut])
    case "import":
        guard let path = commandArgs.first, !path.hasPrefix("--") else {
            throw CLIError.usage("Missing import path")
        }
        let dryRun = commandArgs.contains("--dry-run")
        let apply = commandArgs.contains("--apply")
        guard dryRun != apply else {
            throw CLIError.usage("Import requires exactly one of --dry-run or --apply")
        }
        let conflictMode = ConflictMode(rawValue: optionalValue(after: "--on-conflict", in: commandArgs) ?? "fail")
        guard let conflictMode else {
            throw CLIError.usage("--on-conflict must be one of fail, skip, overwrite")
        }
        let prefix = optionalValue(after: "--prefix", in: commandArgs)

        let incoming = try readImportFile(path)
        try validateUniqueShortcuts(incoming)
        if let prefix {
            try validatePrefix(incoming, prefix: prefix)
        }
        let existing = try filterReplacements(replacements(), prefix: prefix)
        let plan = buildImportPlan(incoming: incoming, existing: existing, conflictMode: conflictMode)
        if !plan.conflicts.isEmpty {
            try printJSON(plan)
            throw CLIError.runtime("Import has conflicts; rerun with --on-conflict skip or --on-conflict overwrite")
        }
        if dryRun {
            try printJSON(plan)
            return
        }

        let backupURL = try writeBackup(existing)
        for row in plan.create {
            try createReplacement(shortcut: row.shortcut, phrase: row.phrase)
        }
        for row in plan.update {
            try updateReplacement(shortcut: row.shortcut, phrase: row.phrase)
        }
        syncExpanderIfEnabled(commandArgs: commandArgs)
        try printJSONObject([
            "created": plan.create.count,
            "updated": plan.update.count,
            "skipped": plan.skip.count,
            "backup": backupURL.path
        ])
    case "inspect":
        try printJSONObject(KSProbeInspect())
    case "read-sources":
        var nsError: NSError?
        let result = KSProbeReadSources(&nsError)
        if let nsError {
            throw bridgeError(nsError)
        }
        try printJSONObject(result)
    case "db-summary":
        try printJSONObject(databaseSummary())
    default:
        throw CLIError.usage(usage())
    }
}

do {
    try main()
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
