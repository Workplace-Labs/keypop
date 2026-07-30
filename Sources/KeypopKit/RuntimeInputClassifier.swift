import ApplicationServices
import Foundation

enum RuntimeInput: Equatable {
    case text(Character)
    case reset
}

/// Converts a low-level key event into the only two states the matcher needs.
enum RuntimeInputClassifier {
    static func classify(keyCode: Int, flags: CGEventFlags, unicode: String) -> RuntimeInput {
        guard !resetsForKeyCode(keyCode), !hasDisallowedModifiers(flags),
              unicode.count == 1, let character = unicode.first,
              !character.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }),
              !character.unicodeScalars.allSatisfy({ CharacterSet.whitespacesAndNewlines.contains($0) })
        else {
            return .reset
        }

        return .text(character)
    }

    private static func resetsForKeyCode(_ keyCode: Int) -> Bool {
        switch keyCode {
        case 0x7B, 0x7C, 0x7D, 0x7E,
             0x75, 0x73, 0x77, 0x74, 0x79, 0x71,
             0x35, 0x33,
             0x30, 0x24:
            return true
        default:
            return false
        }
    }

    private static func hasDisallowedModifiers(_ flags: CGEventFlags) -> Bool {
        flags.contains(.maskControl) || flags.contains(.maskCommand) || flags.contains(.maskAlternate)
    }
}
