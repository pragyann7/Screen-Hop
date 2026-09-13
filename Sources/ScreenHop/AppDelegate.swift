import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = PointStore()
    private let hotKeys = HotKeyManager()
    private var points: [CursorPoint] = []
    private var statusItem: NSStatusItem!
    private var preferencesController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        points = store.load()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "scope", accessibilityDescription: "Screen Hop")
        hotKeys.onShortcut = { [weak self] shortcut in self?.jump(for: shortcut) }
        refresh()
        requestAccessibilityIfNeeded()
    }

    private func refresh() {
        let duplicateShortcuts = hotKeys.register(points.map(\.shortcut))
        let menu = NSMenu()
        menu.addItem(withTitle: "Add Point…", action: #selector(addPoint), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        for point in points {
            let item = NSMenuItem(title: "\(point.name)   \(point.shortcut.displayText)", action: #selector(jumpFromMenu(_:)), keyEquivalent: "")
            item.representedObject = point.id.uuidString
            item.target = self
            menu.addItem(item)
        }
        if !points.isEmpty {
            menu.addItem(NSMenuItem.separator())
            menu.addItem(withTitle: "Preferences…", action: #selector(openPreferences), keyEquivalent: "")
        }
        if !duplicateShortcuts.isEmpty {
            let warning = NSMenuItem(title: "Duplicate shortcuts are disabled", action: nil, keyEquivalent: "")
            warning.isEnabled = false; menu.addItem(warning)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Accessibility Settings…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        menu.addItem(withTitle: "Quit Screen Hop", action: #selector(quit), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func addPoint() {
        guard let location = CursorPointPicker.pickLocation(), let display = DisplayService.display(containing: location) else {
            return
        }
        let (x, y) = CursorService.normalizedLocation(location, in: display)
        guard let name = promptForName(), let shortcut = promptForShortcut() else { return }
        points.append(CursorPoint(name: name, displayUUID: display.uuid, normalizedX: x, normalizedY: y, shortcut: shortcut))
        store.save(points); refresh()
        preferencesController?.updatePoints(points)
    }

    private func promptForName() -> String? {
        let alert = NSAlert(); alert.messageText = "Name Cursor Point"; alert.informativeText = "Use a memorable name, such as ‘External monitor center’."
        let nameField = NSTextField(string: "New Point")
        alert.accessoryView = nameField; alert.addButton(withTitle: "Continue"); alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = nameField
        alert.window.makeFirstResponder(nameField)
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { showError("A point needs a name."); return nil }
        return name
    }

    private func promptForShortcut() -> Shortcut? {
        let recorder = ShortcutRecorderView(frame: NSRect(x: 0, y: 0, width: 270, height: 36))
        let alert = NSAlert(); alert.messageText = "Assign Shortcut"; alert.informativeText = "Press a shortcut with Command, Control, or Option."
        alert.accessoryView = recorder; alert.addButton(withTitle: "Save"); alert.addButton(withTitle: "Cancel")
        alert.window.initialFirstResponder = recorder
        alert.window.makeFirstResponder(recorder)
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        guard let shortcut = recorder.shortcut else { showError("Record a shortcut before saving."); return nil }
        return shortcut
    }

    @objc private func jumpFromMenu(_ sender: NSMenuItem) {
        guard let idText = sender.representedObject as? String, let id = UUID(uuidString: idText),
              let point = points.first(where: { $0.id == id }) else { return }
        jump(to: point)
    }

    private func jump(for shortcut: Shortcut) { if let point = points.first(where: { $0.shortcut == shortcut }) { jump(to: point) } }
    private func jump(to point: CursorPoint) { if !CursorService.move(to: point) { showError("The display for ‘\(point.name)’ is not currently connected.") } }

    @objc private func openPreferences() {
        if preferencesController == nil {
            preferencesController = PreferencesWindowController(points: points)
            preferencesController?.delegate = self
        }
        preferencesController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        // Equivalent to kAXTrustedCheckOptionPrompt, written as a literal to
        // avoid importing a mutable C global into Swift's concurrency model.
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    }
    @objc private func openAccessibilitySettings() { NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!) }
    @objc private func quit() { NSApp.terminate(nil) }
    private func showError(_ message: String) { let alert = NSAlert(); alert.messageText = "Screen Hop"; alert.informativeText = message; alert.runModal() }
}

extension AppDelegate: PreferencesWindowControllerDelegate {
    func preferencesWindowController(_ controller: PreferencesWindowController, didUpdatePoints points: [CursorPoint]) {
        self.points = points
        store.save(points)
        refresh()
    }
}

final class ShortcutRecorderView: NSView {
    private let label = NSTextField(labelWithString: "Press a shortcut (for example ⌃⌥1)")
    var shortcut: Shortcut? { didSet { label.stringValue = shortcut?.displayText ?? "Click here, then press a shortcut" } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true; layer?.cornerRadius = 6; layer?.borderWidth = 1; layer?.borderColor = NSColor.separatorColor.cgColor
        label.frame = bounds.insetBy(dx: 8, dy: 8); label.autoresizingMask = [.width, .height]; addSubview(label)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool {
        label.stringValue = shortcut?.displayText ?? "Press a shortcut (for example ⌃⌥1)"
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        return true
    }
    override func resignFirstResponder() -> Bool {
        layer?.borderColor = NSColor.separatorColor.cgColor
        return true
    }
    override func mouseDown(with event: NSEvent) { window?.makeFirstResponder(self) }
    override func keyDown(with event: NSEvent) {
        let modifiers = carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { NSSound.beep(); return }
        shortcut = Shortcut(keyCode: UInt32(event.keyCode), modifiers: modifiers)
    }
    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= HotKeyModifiers.command }
        if flags.contains(.option) { result |= HotKeyModifiers.option }
        if flags.contains(.control) { result |= HotKeyModifiers.control }
        if flags.contains(.shift) { result |= HotKeyModifiers.shift }
        return result
    }
}
