import XCTest
@testable import Breathe

final class BreathViewTests: XCTestCase {
    func testCycleCountLabelUsesSingularOnlyForOne() {
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(0)), "0 cycles")
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(1)), "1 cycle")
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(2)), "2 cycles")
    }

    func testStatLabelsUseSingularOnlyForOne() {
        XCTAssertEqual(String(localized: BreathView.minutesLabel(1)), "1 min")
        XCTAssertEqual(String(localized: BreathView.sessionsLabel(1)), "1 session")
        XCTAssertEqual(String(localized: BreathView.sessionsLabel(0)), "0 sessions")
        XCTAssertEqual(String(localized: BreathView.streakLabel(1)), "1 day")
        XCTAssertEqual(String(localized: BreathView.streakLabel(3)), "3 days")
    }
}
