import Foundation

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

enum KeypopCLI {
    static let crudCommands: Set<String> = [
        "list", "get", "export", "create", "update", "delete", "import",
        "inspect", "read-sources", "db-summary"
    ]

    static func usage() -> String {
        """
        keypop — Apple Text Replacements + Mac system-wide expansion

        Kit files use JSON snippet format (name, keyword, text).

        Usage:
          keypop list [--prefix <prefix>]
          keypop get --shortcut <shortcut>
          keypop export [--prefix <prefix>] [--output <path>]
          keypop create --shortcut <shortcut> --phrase <phrase>
          keypop update --shortcut <shortcut> --phrase <phrase>
          keypop delete --shortcut <shortcut>
          keypop import <path|-> [--prefix <prefix>] [--dry-run|--apply] [--on-conflict fail|skip|overwrite] [--no-sync]
          keypop stats [--prefix <prefix>]
          keypop stats reset [--shortcut <shortcut>|--all]

          keypop run [--snippets ~/.config/keypop/snippets.json]

          keypop probe permissions [--plain]
          keypop probe listen --seconds 5
          keypop probe inject --text 'hello'
          keypop probe bridge

        Diagnostics:
          keypop inspect
          keypop read-sources
          keypop db-summary

        Mutations auto-export to ~/.config/keypop/snippets.json (disable: --no-sync or KEYPOP_SYNC=0).

        Examples:
          keypop create --shortcut ';wle' --phrase 'you@example.com'
          keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
          ./scripts/launch-keypop.sh install
          tail -f ~/.local/log/keypop.log
        """
    }

    static func probeUsage() -> String {
        """
        keypop probe — diagnostics for macOS text expansion

        Usage:
          keypop probe permissions [--plain]
          keypop probe listen --seconds 5
          keypop probe inject --text 'hello'
          keypop probe bridge
        """
    }
}

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty || args.first == "--help" || args.first == "-h" || args.first == "help" {
    print(KeypopCLI.usage())
    exit(0)
}

guard let command = args.first else {
    fputs("error: missing command\n", stderr)
    print(KeypopCLI.usage())
    exit(1)
}

let commandArgs = Array(args.dropFirst())

do {
    switch command {
    case "run":
        exit(RunCommand.run(args: commandArgs))

    case "probe":
        guard let subcommand = commandArgs.first else {
            throw CLIError.usage(KeypopCLI.probeUsage())
        }
        try ProbeCommands.run(subcommand: subcommand, args: Array(commandArgs.dropFirst()))

    case "stats":
        try StatsCommands.run(args: commandArgs)

    default:
        guard KeypopCLI.crudCommands.contains(command) else {
            throw CLIError.usage(KeypopCLI.usage())
        }
        try CRUDCommands.run(command: command, commandArgs: commandArgs)
    }
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
