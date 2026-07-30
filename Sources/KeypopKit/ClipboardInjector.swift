import AppKit
import ApplicationServices
import Foundation

public enum ClipboardInjectorError: Error, LocalizedError {
    case postEventDenied
    case pasteFailed

    public var errorDescription: String? {
        switch self {
        case .postEventDenied:
            return "Post-event access denied. Grant Accessibility in System Settings."
        case .pasteFailed:
            return "Failed to simulate Command+V paste."
        }
    }
}

public struct ClipboardInjector: Sendable {
    public static let defaultRestoreDelayMs: UInt32 = 500

    public let restoreDelayMs: UInt32
    private let scheduleRestore: @Sendable (UInt32, @escaping @Sendable () -> Void) -> Void
    private let restoreGate: RestoreGate

    private typealias SavedPasteboardItem = (NSPasteboard.PasteboardType, Data?)

    public init(
        restoreDelayMs: UInt32 = Self.defaultRestoreDelayMs,
        scheduleRestore: (@Sendable (UInt32, @escaping @Sendable () -> Void) -> Void)? = nil
    ) {
        self.restoreDelayMs = restoreDelayMs
        self.scheduleRestore = scheduleRestore ?? Self.defaultScheduleRestore
        self.restoreGate = RestoreGate()
    }

    /// Saves pasteboard, sets text, posts Cmd+V, then restores asynchronously after a delay.
    ///
    /// `paste_posted` means the paste keystroke was posted — not that the target app inserted text.
    /// A newer inject cancels any pending restore from an older inject.
    public func inject(_ text: String, onStage: ((String) -> Void)? = nil) throws {
        guard CGPreflightPostEventAccess() else {
            throw ClipboardInjectorError.postEventDenied
        }

        let pasteboard = NSPasteboard.general
        let savedItems = pasteboard.pasteboardItems?.map { item in
            item.types.compactMap { type in
                (type, item.data(forType: type))
            }
        } ?? []

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw ClipboardInjectorError.pasteFailed
        }
        onStage?("pasteboard_written")

        try postCommandV()
        onStage?("paste_posted")

        let generation = restoreGate.begin()
        let delay = restoreDelayMs
        let items = savedItems
        let gate = restoreGate
        scheduleRestore(delay) {
            guard gate.isCurrent(generation) else { return }
            Self.restorePasteboard(savedItems: items)
        }
        onStage?("restore_scheduled")
    }

    /// Deletes `count` characters to the left via backspace.
    public func deleteCharacters(count: Int, onStage: ((String) -> Void)? = nil) throws {
        guard count > 0 else { return }
        guard CGPreflightPostEventAccess() else {
            throw ClipboardInjectorError.postEventDenied
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        let backspace: CGKeyCode = 0x33

        for _ in 0 ..< count {
            guard let down = CGEvent(keyboardEventSource: source, virtualKey: backspace, keyDown: true),
                  let up = CGEvent(keyboardEventSource: source, virtualKey: backspace, keyDown: false)
            else {
                throw ClipboardInjectorError.pasteFailed
            }
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            usleep(2_000)
        }
        onStage?("delete_posted")
    }

    private static let defaultScheduleRestore: @Sendable (UInt32, @escaping @Sendable () -> Void) -> Void = { delayMs, work in
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(delayMs)), execute: work)
    }

    private func postCommandV() throws {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09

        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        else {
            throw ClipboardInjectorError.pasteFailed
        }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private static func restorePasteboard(savedItems: [[SavedPasteboardItem]]) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard !savedItems.isEmpty else { return }

        let newItems: [NSPasteboardItem] = savedItems.map { pairs in
            let item = NSPasteboardItem()
            for (type, data) in pairs {
                if let data {
                    item.setData(data, forType: type)
                }
            }
            return item
        }
        pasteboard.writeObjects(newItems)
    }
}

/// Cancels stale pasteboard restores when expansions overlap.
private final class RestoreGate: @unchecked Sendable {
    private let lock = NSLock()
    private var generation: UInt64 = 0

    func begin() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        generation += 1
        return generation
    }

    func isCurrent(_ candidate: UInt64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return candidate == generation
    }
}
