import Darwin
import Dispatch
import Foundation

/// Watches the snippet file's parent directory so atomic rewrites trigger reload.
///
/// `Data.write(options: .atomic)` replaces the file inode; a vnode watch on the file
/// itself stops receiving events after the first export. Directory events are filtered
/// so sibling writes (for example usage stats) do not reload snippets.
public final class SnippetFileWatcher {
    private let snippetsPath: String
    private let debounceSeconds: TimeInterval
    private let onReload: () -> Void

    private var watchFD: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWork: DispatchWorkItem?
    private var lastFingerprint: String?

    public init(
        snippetsPath: String,
        debounceSeconds: TimeInterval = 0.2,
        onReload: @escaping () -> Void
    ) {
        self.snippetsPath = snippetsPath
        self.debounceSeconds = debounceSeconds
        self.onReload = onReload
    }

    public func start() {
        stop()

        let directory = URL(fileURLWithPath: snippetsPath).deletingLastPathComponent().path
        watchFD = open(directory, O_EVTONLY)
        guard watchFD >= 0 else {
            fputs("reload_watch_disabled|could not watch snippet directory\n", stderr)
            KeypopDiagnostics.event("watcher_disabled", fields: ["reason": "directory_open_failed"])
            return
        }

        lastFingerprint = fingerprint()

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watchFD,
            eventMask: [.write, .delete, .rename, .attrib, .link],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.scheduleReloadIfSnippetsChanged()
        }
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if watchFD >= 0 {
                close(watchFD)
                watchFD = -1
            }
        }
        source.resume()
        self.source = source
        fputs("reload_watch|directory|\(directory)\n", stderr)
        KeypopDiagnostics.event("watcher_started")
    }

    public func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        source?.cancel()
        source = nil
        lastFingerprint = nil
    }

    private func scheduleReloadIfSnippetsChanged() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let current = fingerprint()
            guard current != lastFingerprint else { return }
            lastFingerprint = current
            onReload()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceSeconds, execute: work)
    }

    private func fingerprint() -> String? {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: snippetsPath),
            let modified = attrs[.modificationDate] as? Date,
            let size = attrs[.size] as? NSNumber
        else {
            return nil
        }
        return "\(size.intValue)-\(modified.timeIntervalSince1970)"
    }
}
