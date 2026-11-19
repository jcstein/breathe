import XCTest
@testable import Breathe

final class BreathViewTests: XCTestCase {
    func testCycleCountLabelUsesSingularOnlyForOne() {
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(0)), "0 cycles")
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(1)), "1 cycle")
        XCTAssertEqual(String(localized: BreathView.cycleCountLabel(2)), "2 cycles")
    }
}
