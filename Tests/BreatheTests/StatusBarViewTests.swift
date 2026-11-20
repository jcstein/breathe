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

    func testDotFollowsMenuBarAppearance() throws {
        for (name, expectsDarkDot): (NSAppearance.Name, Bool) in [(.aqua, true), (.darkAqua, false)] {
            let view = StatusBarView(engine: BreathEngine())
            view.appearance = NSAppearance(named: name)
            let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)

            let center = try XCTUnwrap(bitmap.colorAt(x: bitmap.pixelsWide / 2, y: bitmap.pixelsHigh / 2)?
                .usingColorSpace(.deviceRGB))
            XCTAssertGreaterThan(center.alphaComponent, 0.5, "\(name.rawValue)")
            XCTAssertEqual(center.brightnessComponent < 0.5, expectsDarkDot, "\(name.rawValue)")
        }
    }

    func testRedrawsOnlyWhenTheDotAlphaStepChanges() throws {
        _ = NSApplication.shared
        var time = 0.0
        let engine = BreathEngine(now: { time })
        let view = RedrawCountingView(engine: engine)
        let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))

        func redraws(after change: () -> Void) -> Bool {
            let requests = view.redrawRequests
            change()
            let deadline = Date(timeIntervalSinceNow: 0.002)
            while Date() < deadline {
                RunLoop.current.run(mode: .eventTracking, before: deadline)
            }
            guard view.redrawRequests > requests else { return false }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            return true
        }

        XCTAssertTrue(redraws(after: engine.start))
        defer { engine.stop() }

        var redrawCount = 0
        for tick in 1...660 where redraws(after: { time = Double(tick) / 60; engine.update() }) {
            redrawCount += 1
        }
        // One 11 s cycle moves the alpha from 128/255 up to 255 and back: 254 steps in 660 ticks.
        XCTAssertEqual(redrawCount, 254)

        XCTAssertTrue(redraws(after: engine.stop))
    }
}

private final class RedrawCountingView: StatusBarView {
    var redrawRequests = 0

    override var needsDisplay: Bool {
        get { super.needsDisplay }
        set {
            if newValue { redrawRequests += 1 }
            super.needsDisplay = newValue
        }
    }
}
