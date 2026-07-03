import Darwin
import Dispatch
import Foundation
import KeypopKit

enum RunCommand {
    struct Options {
        var snippetsPath: String = SnippetStore.defaultPath()
    }

    static func parseArgs(_ args: [String]) -> Options {
        var options = Options()
        var index = 0
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

    static func run(args: [String]) -> Int32 {
        let options = parseArgs(args)
        let path = options.snippetsPath
        if !FileManager.default.fileExists(atPath: path) {
            fputs("Snippet file not found: \(path)\n", stderr)
            fputs("Run: ./scripts/sync-keypop.sh\n", stderr)
            return 1
        }

        do {
            let store = try SnippetStore.load(from: path)
            let engine = ExpanderEngine(phrases: store.phrases, usageStore: UsageStore())
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
            return 0
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            return 1
        }
    }
}
