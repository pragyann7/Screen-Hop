import AppKit

// A Swift Package executable is not an app bundle, so create AppKit's process
// and event loop explicitly instead of relying on an inferred application entry point.
let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
