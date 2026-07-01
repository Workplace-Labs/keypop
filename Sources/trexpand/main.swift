import Darwin
import Dispatch
import Foundation
import TrexpandKit

enum TrexpandCommand: String {
    case run
    case help
}

struct TrexpandOptions {
    var command: TrexpandCommand = .help
    var snippetsPath: String = SnippetStore.defaultPath()
}

func parseArgs(_ args: [String]) -> TrexpandOptions {
    var options = TrexpandOptions()
    guard args.count > 1 else { return options }

    guard let command = TrexpandCommand(rawValue: args[1]) else {
        fputs("Unknown command: \(args[1])\n", stderr)
        return options
    }
    options.command = command

    var index = 2
    while index < args.count {
        switch args[index] {
        case "--snippets":
            index += 1
            if index < args.count {
                options.snippetsPath = args[index]
            }
        default:
            fputs("Unknown flag: \(args[index])\n", stderr)
        }
        index += 1
    }

    return options
}

func printHelp() {
    print(
        """
        trexpand — system-wide text expansion for Mac

        Usage:
          trexpand run [--snippets ~/.config/trexpand/snippets.json]

        Examples:
          trexpand run --snippets ~/.config/trexpand/snippets.json
          ./scripts/launch-trexpand.sh install
          ./scripts/launch-trexpand.sh status
          ./scripts/launch-trexpand.sh restart
          tail -f ~/.local/log/trexpand.log

        Snippets are auto-exported on trctl mutations, or manually:
          trctl export --output ~/.config/trexpand/snippets.json

        Background: ./scripts/launch-trexpand.sh install

        TCC: grant Input Monitoring + Accessibility to ~/.local/Trexpand.app
        Logs to stderr (or ~/.local/log/trexpand.log when launched via LaunchAgent).
        """
    )
}

let options = parseArgs(CommandLine.arguments)

switch options.command {
case .help:
    printHelp()
    exit(CommandLine.arguments.count > 1 ? 1 : 0)

case .run:
    let path = options.snippetsPath
    if !FileManager.default.fileExists(atPath: path) {
        fputs("Snippet file not found: \(path)\n", stderr)
        fputs("Run: ./scripts/sync-expander.sh\n", stderr)
        exit(1)
    }

    do {
        let store = try SnippetStore.load(from: path)
        let engine = ExpanderEngine(phrases: store.phrases)
        try engine.start()

        var watcher: SnippetFileWatcher?

        func shutdown() {
            fputs("shutting down\n", stderr)
            watcher?.stop()
            watcher = nil
            engine.stop()
            CFRunLoopStop(CFRunLoopGetCurrent())
        }

        var signalSources: [DispatchSourceSignal] = []
        for sig in [SIGINT, SIGTERM] {
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler { shutdown() }
            Darwin.signal(sig, SIG_IGN)
            source.resume()
            signalSources.append(source)
        }

        watcher = SnippetFileWatcher(snippetsPath: path) {
            do {
                let updated = try SnippetStore.load(from: path)
                engine.reload(phrases: updated.phrases)
            } catch {
                fputs("reload_error|\(error.localizedDescription)\n", stderr)
            }
        }
        watcher?.start()

        engine.run()
    } catch {
        fputs("Error: \(error.localizedDescription)\n", stderr)
        exit(1)
    }
}
