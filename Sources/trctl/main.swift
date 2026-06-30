import Foundation
import KSPrivateBridge

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

func printJSON(_ value: Any) throws {
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

func requirePrivateAPIFlag(_ args: [String]) throws {
    guard args.contains("--i-understand-private-api") else {
        throw CLIError.usage("Mutation commands require --i-understand-private-api")
    }
}

func value(after flag: String, in args: [String]) throws -> String {
    guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else {
        throw CLIError.usage("Missing \(flag)")
    }
    return args[index + 1]
}

func usage() -> String {
    """
    Usage:
      trctl inspect
      trctl read-sources
      trctl db-summary
      trctl private-list
      trctl private-create --i-understand-private-api --shortcut <shortcut> --phrase <phrase>
      trctl private-update --i-understand-private-api --shortcut <shortcut> --phrase <phrase>
      trctl private-delete --i-understand-private-api --shortcut <shortcut>
    """
}

func main() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    guard let command = args.first else {
        throw CLIError.usage(usage())
    }

    switch command {
    case "inspect":
        try printJSON(KSProbeInspect())
    case "read-sources":
        var nsError: NSError?
        let result = KSProbeReadSources(&nsError)
        if let nsError {
            throw bridgeError(nsError)
        }
        try printJSON(result)
    case "db-summary":
        try printJSON(databaseSummary())
    case "private-list":
        var nsError: NSError?
        let rows = KSPrivateList(&nsError)
        if let nsError {
            throw bridgeError(nsError)
        }
        try printJSON(rows)
    case "private-create":
        try requirePrivateAPIFlag(args)
        let shortcut = try value(after: "--shortcut", in: args)
        let phrase = try value(after: "--phrase", in: args)
        var nsError: NSError?
        guard KSPrivateCreate(shortcut, phrase, &nsError) else {
            throw bridgeError(nsError)
        }
        try printJSON(["created": shortcut])
    case "private-update":
        try requirePrivateAPIFlag(args)
        let shortcut = try value(after: "--shortcut", in: args)
        let phrase = try value(after: "--phrase", in: args)
        var nsError: NSError?
        guard KSPrivateUpdate(shortcut, phrase, &nsError) else {
            throw bridgeError(nsError)
        }
        try printJSON(["updated": shortcut])
    case "private-delete":
        try requirePrivateAPIFlag(args)
        let shortcut = try value(after: "--shortcut", in: args)
        var nsError: NSError?
        guard KSPrivateDelete(shortcut, &nsError) else {
            throw bridgeError(nsError)
        }
        try printJSON(["deleted": shortcut])
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
