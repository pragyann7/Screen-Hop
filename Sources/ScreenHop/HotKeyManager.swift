import Carbon
import Foundation

final class HotKeyManager {
    var onShortcut: ((Shortcut) -> Void)?
    private var registrations: [EventHotKeyRef] = []
    private var shortcutsByID: [UInt32: Shortcut] = [:]
    private var nextID: UInt32 = 1
    private var eventHandler: EventHandlerRef?

    init() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if let shortcut = manager.shortcutsByID[hotKeyID.id] { manager.onShortcut?(shortcut) }
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
    }

    deinit {
        registrations.forEach { _ = UnregisterEventHotKey($0) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    /// Returns duplicates that were intentionally skipped to avoid ambiguous jumps.
    func register(_ shortcuts: [Shortcut]) -> Set<Shortcut> {
        registrations.forEach { _ = UnregisterEventHotKey($0) }
        registrations.removeAll(); shortcutsByID.removeAll(); nextID = 1
        var seen = Set<Shortcut>(); var duplicates = Set<Shortcut>()
        for shortcut in shortcuts {
            guard seen.insert(shortcut).inserted else { duplicates.insert(shortcut); continue }
            var reference: EventHotKeyRef?
            let id = nextID; nextID += 1
            let hotKeyID = EventHotKeyID(signature: OSType(0x4350_4F52), id: id) // CPOR
            if RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, hotKeyID,
                                   GetEventDispatcherTarget(), 0, &reference) == noErr,
               let reference {
                registrations.append(reference)
                shortcutsByID[id] = shortcut
            }
        }
        return duplicates
    }
}
