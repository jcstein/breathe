import AppKit
import XCTest
@testable import Breathe

final class StatusBarViewTests: XCTestCase {
    func testClickRouting() throws {
        let view = StatusBarView(engine: BreathEngine())
        var clicks = 0
        var menus = 0
        view.onClick = { clicks += 1 }
        view.onRightClick = { menus += 1 }

        for (type, modifiers, expectedClicks, expectedMenus): (NSEvent.EventType, NSEvent.ModifierFlags, Int, Int) in [
            (.leftMouseDown, [], 1, 0),
            (.leftMouseDown, .control, 1, 1),
            (.rightMouseDown, [], 1, 2)
        ] {
            let event = try XCTUnwrap(NSEvent.mouseEvent(
                with: type, location: .zero, modifierFlags: modifiers,
                timestamp: 0, windowNumber: 0, context: nil,
                eventNumber: 0, clickCount: 1, pressure: 1
            ))
            if type == .rightMouseDown {
                view.rightMouseDown(with: event)
            } else {
                view.mouseDown(with: event)
            }
            XCTAssertEqual(clicks, expectedClicks)
            XCTAssertEqual(menus, expectedMenus)
        }
    }
}
