import XCTest
import AppKit
@testable import Breathe

final class BreathEngineTests: XCTestCase {
    func testTimerTicksDuringMenuTracking() {
        _ = NSApplication.shared
        let engine = BreathEngine()
        engine.start()
        defer { engine.stop() }

        let deadline = Date(timeIntervalSinceNow: 0.25)
        while Date() < deadline {
            RunLoop.current.run(mode: .eventTracking, before: deadline)
        }

        XCTAssertGreaterThan(engine.elapsed, 0)
    }

    func testIdleAndStoppedUpdatesDoNothing() {
        var time = 0.0
        let engine = BreathEngine(now: { time })
        engine.update()
        XCTAssertEqual(engine.phase, .idle)
        engine.start()
        engine.stop()
        time = 100
        engine.update()
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.elapsed, 0)
        XCTAssertEqual(engine.cycleCount, 0)
    }

    func testBoundariesAndMultipleMissedCycles() {
        var time = 10.0
        let engine = BreathEngine(now: { time })
        engine.start()
        defer { engine.stop() }
        time = 15.49
        engine.update()
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.remaining, 0.01, accuracy: 0.000001)
        time = 21
        engine.update()
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.cycleCount, 1)
        XCTAssertEqual(engine.elapsed, 0)
        time = 49
        engine.update()
        XCTAssertEqual(engine.phase, .exhale)
        XCTAssertEqual(engine.cycleCount, 3)
        XCTAssertEqual(engine.elapsed, 0.5)
        engine.start()
        time = 50
        engine.update()
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.cycleCount, 0)
        XCTAssertEqual(engine.elapsed, 1)
    }

    func testDelayedTickKeepsPhaseBoundary() {
        var time = 100.0
        let engine = BreathEngine(now: { time })
        engine.start()
        defer { engine.stop() }
        for frame in 1...270 {
            time = 100 + Double(frame) / 60
            engine.update()
        }
        time = 105.5 // One second without callbacks.
        engine.update()
        XCTAssertEqual(engine.phase, .exhale)
        XCTAssertEqual(engine.elapsed, 0, accuracy: 0.000001)
    }
}
