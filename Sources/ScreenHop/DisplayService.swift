import AppKit
import CoreGraphics

struct ActiveDisplay {
    let id: CGDirectDisplayID
    let uuid: String
    let bounds: CGRect
}

enum DisplayService {
    static func activeDisplays() -> [ActiveDisplay] {
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &count) == .success else { return [] }
        var ids = Array(repeating: CGDirectDisplayID(), count: Int(count))
        guard CGGetActiveDisplayList(count, &ids, &count) == .success else { return [] }
        return ids.prefix(Int(count)).compactMap { id -> ActiveDisplay? in
            guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return nil }
            let uuidText = CFUUIDCreateString(nil, uuid) as String
            return ActiveDisplay(id: id, uuid: uuidText, bounds: CGDisplayBounds(id))
        }
    }

    static func display(containing location: CGPoint) -> ActiveDisplay? {
        activeDisplays().first { $0.bounds.contains(location) }
    }

    static func resolve(uuid: String) -> ActiveDisplay? {
        activeDisplays().first { $0.uuid == uuid }
    }
}

enum CursorService {
    static func currentLocation() -> CGPoint? {
        CGEvent(source: nil)?.location
    }

    static func normalizedLocation(_ location: CGPoint, in display: ActiveDisplay) -> (Double, Double) {
        let x = min(1, max(0, (location.x - display.bounds.minX) / display.bounds.width))
        let y = min(1, max(0, (location.y - display.bounds.minY) / display.bounds.height))
        return (x, y)
    }

    static func move(to point: CursorPoint) -> Bool {
        guard let display = DisplayService.resolve(uuid: point.displayUUID) else { return false }
        let target = CGPoint(
            x: display.bounds.minX + CGFloat(point.normalizedX) * display.bounds.width,
            y: display.bounds.minY + CGFloat(point.normalizedY) * display.bounds.height
        )
        CGWarpMouseCursorPosition(target)
        return true
    }
}
