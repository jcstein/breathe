import XCTest
@testable import Breathe

final class UsageStatsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date()

    override func setUp() {
        suiteName = "UsageStatsTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 2  // Monday
        now = date("2026-11-19 10:00")  // a Thursday
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: string)!
    }

    private func makeStats() -> UsageStats {
        UsageStats(defaults: defaults, calendar: calendar, now: { [unowned self] in now })
    }

    func testEmptyStatsAreZero() {
        let stats = makeStats()
        XCTAssertEqual(stats.minutesToday, 0)
        XCTAssertEqual(stats.sessionsThisWeek, 0)
        XCTAssertEqual(stats.streakDays, 0)
    }

    func testSessionsShorterThanOneBreathAreIgnored() {
        let stats = makeStats()
        stats.record(sessionDuration: 10.9)
        XCTAssertEqual(stats.sessionsThisWeek, 0)
        stats.record(sessionDuration: 11)
        XCTAssertEqual(stats.sessionsThisWeek, 1)
        XCTAssertEqual(stats.minutesToday, 1)
    }

    func testMinutesTodayAddsSessionsAndResetsAtMidnight() {
        let stats = makeStats()
        stats.record(sessionDuration: 150)
        stats.record(sessionDuration: 200)
        XCTAssertEqual(stats.minutesToday, 6)
        now = date("2026-11-20 00:01")
        XCTAssertEqual(stats.minutesToday, 0)
    }

    func testSessionsThisWeekCountsFromWeekStart() {
        let stats = makeStats()
        now = date("2026-11-15 20:00")  // previous Sunday
        stats.record(sessionDuration: 60)
        now = date("2026-11-16 08:00")  // Monday
        stats.record(sessionDuration: 60)
        now = date("2026-11-19 10:00")
        stats.record(sessionDuration: 60)
        stats.record(sessionDuration: 60)
        XCTAssertEqual(stats.sessionsThisWeek, 3)
        now = date("2026-11-23 09:00")  // next Monday
        XCTAssertEqual(stats.sessionsThisWeek, 0)
    }

    func testStreakCountsConsecutiveDaysAndSurvivesUntilEndOfToday() {
        let stats = makeStats()
        for day in ["2026-11-14", "2026-11-16", "2026-11-17", "2026-11-18"] {
            now = date("\(day) 21:00")
            stats.record(sessionDuration: 60)
        }
        now = date("2026-11-19 10:00")
        XCTAssertEqual(stats.streakDays, 3, "yesterday's streak holds until today ends")
        stats.record(sessionDuration: 60)
        XCTAssertEqual(stats.streakDays, 4)
        now = date("2026-11-21 10:00")
        XCTAssertEqual(stats.streakDays, 0, "a missed day breaks the streak")
    }

    func testStatsPersistAcrossLaunches() {
        makeStats().record(sessionDuration: 120)
        let relaunched = makeStats()
        XCTAssertEqual(relaunched.minutesToday, 2)
        XCTAssertEqual(relaunched.sessionsThisWeek, 1)
        XCTAssertEqual(relaunched.streakDays, 1)
    }
}
