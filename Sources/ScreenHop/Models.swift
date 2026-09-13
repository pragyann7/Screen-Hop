import Foundation

/// Carbon modifier bit masks expected by `RegisterEventHotKey`.
enum HotKeyModifiers {
    static let command: UInt32 = 1 << 8
    static let shift: UInt32 = 1 << 9
    static let option: UInt32 = 1 << 11
    static let control: UInt32 = 1 << 12
}

struct Shortcut: Codable, Hashable {
    let keyCode: UInt32
    let modifiers: UInt32

    var displayText: String {
        let symbols: [(UInt32, String)] = [
            (HotKeyModifiers.command, "⌘"), (HotKeyModifiers.option, "⌥"),
            (HotKeyModifiers.control, "⌃"), (HotKeyModifiers.shift, "⇧")
        ]
        let prefix = symbols.filter { modifiers & $0.0 != 0 }.map(\.1).joined()
        return prefix + KeyNames.name(for: keyCode)
    }
}

struct CursorPoint: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var displayUUID: String
    /// Fractions with a Quartz-style top-left origin.
    var normalizedX: Double
    var normalizedY: Double
    var shortcut: Shortcut
}

enum KeyNames {
    static func name(for keyCode: UInt32) -> String {
        let known: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M", 49: "Space", 36: "↩", 53: "⎋",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return known[keyCode] ?? "Key \(keyCode)"
    }
}
