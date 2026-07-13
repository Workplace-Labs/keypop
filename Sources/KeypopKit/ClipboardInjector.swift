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
    public let restoreDelayMs: UInt32

    private typealias SavedPasteboardItem = (NSPasteboard.PasteboardType, Data?)

    public init(restoreDelayMs: UInt32 = 100) {
        self.restoreDelayMs = restoreDelayMs
    }

    /// Saves pasteboard, sets text, posts Cmd+V, restores after delay.
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

        usleep(restoreDelayMs * 1000)
        restorePasteboard(savedItems: savedItems)
    }

    /// Deletes `count` characters to the left via forward-delete (Fn+Delete) or backspace.
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

    private func restorePasteboard(savedItems: [[SavedPasteboardItem]]) {
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
