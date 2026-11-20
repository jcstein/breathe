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

    func testStopReportsSessionLengthOnce() {
        var time = 10.0
        let engine = BreathEngine(now: { time })
        var reported: [TimeInterval] = []
        engine.onSessionEnd = { reported.append($0) }
        engine.stop()
        XCTAssertEqual(reported, [])
        engine.start()
        time = 72.5
        engine.stop()
        engine.stop()
        XCTAssertEqual(reported, [62.5])
    }

    func testIdlePromptSaysClick() {
        XCTAssertEqual(BreathEngine.Phase.idle.label, "click to begin")
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

    func testRestartsKeepOneTimer() {
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
    }

    func testBoxPatternHoldsAfterEachBreath() {
        let suiteName = "BreathEngineTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        var time = 0.0
        let engine = BreathEngine(defaults: defaults, now: { time })
        engine.pattern = .box
        engine.start()
        defer { engine.stop() }

        let expected: [(time: Double, phase: BreathEngine.Phase, remaining: Double, expansion: Double, cycles: Int)] = [
            (1, .inhale, 3, 0.25, 0),
            (5, .holdFull, 3, 1, 0),
            (10, .exhale, 2, 0.5, 0),
            (13, .holdEmpty, 3, 0, 0),
            (16, .inhale, 4, 0, 1),
            (47.5, .holdEmpty, 0.5, 0, 2),
        ]
        for step in expected {
            time = step.time
            engine.update()
            XCTAssertEqual(engine.phase, step.phase, "at \(step.time) s")
            XCTAssertEqual(engine.remaining, step.remaining, accuracy: 0.000001, "at \(step.time) s")
            XCTAssertEqual(engine.expansion, step.expansion, accuracy: 0.000001, "at \(step.time) s")
            XCTAssertEqual(engine.cycleCount, step.cycles, "at \(step.time) s")
        }
        XCTAssertEqual(BreathEngine.Phase.holdFull.label, "hold")
        XCTAssertEqual(BreathEngine.Phase.holdEmpty.label, "hold")
    }

    func testPatternChoiceIsRememberedAndDefaultsToResonant() {
        let suiteName = "BreathEngineTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = BreathEngine(defaults: defaults)
        XCTAssertEqual(first.pattern, .resonant)
        first.pattern = .box
        XCTAssertEqual(BreathEngine(defaults: defaults).pattern, .box)

        defaults.set("unknown", forKey: "breathPattern")
        XCTAssertEqual(BreathEngine(defaults: defaults).pattern, .resonant)
    }

    func testPatternSummaries() {
        XCTAssertEqual(BreathEngine.Pattern.resonant.summary, "5.5s in \u{00B7} 5.5s out")
        XCTAssertEqual(BreathEngine.Pattern.box.summary, "4s in \u{00B7} 4s hold \u{00B7} 4s out \u{00B7} 4s hold")
        XCTAssertEqual(BreathEngine.Pattern.resonant.cycleDuration, 11)
        XCTAssertEqual(BreathEngine.Pattern.box.cycleDuration, 16)
    }
}
