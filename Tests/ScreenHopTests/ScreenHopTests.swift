import CoreGraphics
import XCTest
@testable import ScreenHop

final class ScreenHopTests: XCTestCase {
    func testNormalizedLocationUsesTheDisplayBoundsNotDesktopArrangement() {
        // A display placed above and left of the primary display has negative origins.
        let display = ActiveDisplay(id: 1, uuid: "test-display", bounds: CGRect(x: -1440, y: -900, width: 1440, height: 900))
        let location = CGPoint(x: -720, y: -450)

        let result = CursorService.normalizedLocation(location, in: display)

        XCTAssertEqual(result.0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(result.1, 0.5, accuracy: 0.0001)
    }

    func testPointAndShortcutRoundTripThroughJSON() throws {
        let original = CursorPoint(
            name: "Writing screen center",
            displayUUID: "display-uuid",
            normalizedX: 0.25,
            normalizedY: 0.75,
            shortcut: Shortcut(keyCode: 18, modifiers: HotKeyModifiers.command | HotKeyModifiers.option)
        )

        let decoded = try JSONDecoder().decode(CursorPoint.self, from: JSONEncoder().encode(original))

        XCTAssertEqual(decoded, original)
    }
}
