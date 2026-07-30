import Darwin
import Dispatch
import Foundation

/// Watches the control directory for out-of-band commands (heal).
public final class ControlFileWatcher {
    private let directoryPath: String
    private let debounceSeconds: TimeInterval
    private let onHeal: (String) -> Void

    private var watchFD: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWork: DispatchWorkItem?

    public init(
        directoryPath: String = ControlPlane.directoryPath,
        debounceSeconds: TimeInterval = 0.05,
        onHeal: @escaping (String) -> Void
    ) {
        self.directoryPath = directoryPath
        self.debounceSeconds = debounceSeconds
        self.onHeal = onHeal
    }

    public func start() {
        stop()

        try? FileManager.default.createDirectory(
            atPath: directoryPath,
            withIntermediateDirectories: true
        )

        watchFD = open(directoryPath, O_EVTONLY)
        guard watchFD >= 0 else {
            fputs("control_watch_disabled|could not watch control directory\n", stderr)
            KeypopDiagnostics.event("control_watcher_disabled", fields: ["reason": "directory_open_failed"])
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: watchFD,
            eventMask: [.write, .delete, .rename, .attrib, .link],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            self?.schedulePoll()
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
        fputs("control_watch|directory|\(directoryPath)\n", stderr)
        KeypopDiagnostics.event("control_watcher_started")
        poll()
    }

    public func stop() {
        debounceWork?.cancel()
        debounceWork = nil
        source?.cancel()
        source = nil
    }

    private func schedulePoll() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.poll()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceSeconds, execute: work)
    }

    private func poll() {
        if let reason = ControlPlane.consumeHealRequest() {
            onHeal(reason)
        }
    }
}
