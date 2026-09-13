# Screen Hop

Screen Hop is a tiny macOS menu-bar utility for saving named cursor destinations
on any connected display and jumping to them with global keyboard shortcuts.

## MVP architecture

```
AppDelegate
 ├─ StatusItemController     AppKit menu and point management UI
 ├─ PointStore               JSON persistence in Application Support
 ├─ DisplayService           display UUID lookup and normalized coordinate mapping
 ├─ CursorService            reads and warps the system pointer
 ├─ HotKeyManager            Carbon global shortcut registration
 └─ AccessibilityService     checks and opens macOS accessibility permission
```

Each point stores a display UUID plus `x`/`y` fractions within that display. The
fractions use a top-left origin, matching Quartz display coordinates, so display
orientation and relative placement do not affect cursor jumps.

## Run

Open the folder in Xcode and run the `Screen Hop` executable scheme, or run:

```sh
swift run
```

The first launch requests Accessibility permission. Enable Screen Hop in
**System Settings → Privacy & Security → Accessibility**, then quit and reopen it
if macOS does not activate the permission immediately.

## MVP interaction

1. Click the menu-bar crosshair and choose **Add Point…**.
2. Click the exact destination on the temporary desktop-wide placement overlay.
3. Give it a name and press the desired modifier shortcut in the recorder.
4. Select its menu item or press that shortcut from any app.

The app deliberately uses Carbon's `RegisterEventHotKey`, which stays idle when
no shortcut is pressed; it does not install a continuously running event tap.

## Next iterations

- A full settings window with drag-to-place overlay markers.
- Multiple shortcuts per point and a conflict-resolution flow.
- Remember-the-last-position-per-display commands.
- Code signing, hardened runtime, notarization, and a conventional Xcode project
  for distribution.
