import AppKit

/// A temporary desktop-wide overlay used to choose a destination precisely.
@MainActor
enum CursorPointPicker {
    static func pickLocation() -> CGPoint? {
        var selection: CGPoint?
        var cancelled = false
        let panels = NSScreen.screens.map { screen -> NSPanel in
            let panel = NSPanel(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            panel.isOpaque = false; panel.backgroundColor = .clear; panel.level = .popUpMenu
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]; panel.hasShadow = false
            let overlay = PickerOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size)) { selection = $0 }
            panel.contentView = overlay; panel.initialFirstResponder = overlay
            panel.orderFrontRegardless()
            return panel
        }
        guard !panels.isEmpty else { return nil }
        NSApp.activate(ignoringOtherApps: true)
        panels.first?.makeKey()

        // Keep all display panels interactive; an app-modal panel would disable
        // the overlay windows on the other displays.
        while selection == nil && !cancelled {
            if let event = NSApp.nextEvent(matching: .any, until: .distantFuture, inMode: .default, dequeue: true) {
                if event.type == .keyDown && event.keyCode == 53 { cancelled = true }
                else { NSApp.sendEvent(event) }
            }
        }
        panels.forEach { $0.orderOut(nil) }
        return selection
    }
}

@MainActor
private final class PickerOverlayView: NSView {
    private let onSelection: (CGPoint) -> Void

    private let instruction = NSTextField(labelWithString: "Click to place the cursor destination  •  Press Esc to cancel")

    init(frame frameRect: NSRect, onSelection: @escaping (CGPoint) -> Void) {
        self.onSelection = onSelection
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        instruction.textColor = .labelColor
        instruction.font = .systemFont(ofSize: 16, weight: .medium)
        instruction.alignment = .center
        instruction.drawsBackground = true
        instruction.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        instruction.wantsLayer = true
        instruction.layer?.cornerRadius = 8
        instruction.isBezeled = false
        instruction.isBordered = false
        instruction.isEditable = false
        instruction.isSelectable = false
        instruction.sizeToFit()

        let width = instruction.frame.width + 36
        let height = instruction.frame.height + 20
        instruction.frame = NSRect(x: max(20, (bounds.width - width) / 2), y: bounds.height - height - 40, width: width, height: height)
        instruction.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin]
        addSubview(instruction)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        // CGEvent locations use the same Quartz coordinate space used for warping.
        if let location = CGEvent(source: nil)?.location { onSelection(location) }
    }
}
