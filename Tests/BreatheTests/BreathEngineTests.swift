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

    func testStopMidSessionReturnsToIdle() {
        var time = 0.0
        let engine = BreathEngine(now: { time })
        engine.start()
        time = 18
        engine.update()
        XCTAssertEqual(engine.phase, .exhale)
        XCTAssertEqual(engine.cycleCount, 1)

        engine.stop()
        XCTAssertFalse(engine.isBreathing)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.elapsed, 0)
        XCTAssertEqual(engine.expansion, 0)
    }

    func testRestartAfterStopTimesFromRestart() {
        var time = 0.0
        let engine = BreathEngine(now: { time })
        engine.start()
        time = 30
        engine.update()
        XCTAssertEqual(engine.cycleCount, 2)
        engine.stop()

        time = 100
        engine.start()
        defer { engine.stop() }
        XCTAssertTrue(engine.isBreathing)
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.elapsed, 0)
        XCTAssertEqual(engine.cycleCount, 0)
        time = 103
        engine.update()
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.elapsed, 3)
        XCTAssertEqual(engine.cycleCount, 0)
        time = 112
        engine.update()
        XCTAssertEqual(engine.phase, .inhale)
        XCTAssertEqual(engine.elapsed, 1)
        XCTAssertEqual(engine.cycleCount, 1)
    }

    func testRepeatedTogglesAlternateSessions() {
        var time = 0.0
        let engine = BreathEngine(now: { time })
        defer { engine.stop() }
        for toggle in 1...10 {
            time += 7
            engine.toggle()
            engine.update()
            let started = toggle % 2 == 1
            XCTAssertEqual(engine.isBreathing, started)
            XCTAssertEqual(engine.phase, started ? .inhale : .idle)
            XCTAssertEqual(engine.elapsed, 0)
        }
    }

    func testRestartsKeepOneTimerAndStopEndsTicks() {
        var clockReads = 0
        let engine = BreathEngine(now: {
            clockReads += 1
            return ProcessInfo.processInfo.systemUptime
        })
        defer { engine.stop() }
        for _ in 1...5 { engine.toggle() }
        engine.start()
        XCTAssertTrue(engine.isBreathing)

        clockReads = 0
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        XCTAssertGreaterThan(clockReads, 0)
        XCTAssertLessThanOrEqual(clockReads, 45, "more ticks than one 60 Hz timer delivers in 0.5 s")

        engine.stop()
        clockReads = 0
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        XCTAssertEqual(clockReads, 0)
        XCTAssertEqual(engine.phase, .idle)
    }
}
