import Foundation

/// Totals of finished breathing sessions, kept per day in UserDefaults on this Mac only.
final class UsageStats: ObservableObject {
    struct Day: Codable, Equatable {
        var seconds: TimeInterval = 0
        var sessions: Int = 0
    }

    /// One full breath; shorter sessions are accidental taps and are not counted.
    static let minimumSessionDuration: TimeInterval = 11

    @Published private(set) var days: [String: Day]

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    private static let storageKey = "usageDays"

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now
        days = defaults.data(forKey: Self.storageKey)
            .flatMap { try? JSONDecoder().decode([String: Day].self, from: $0) } ?? [:]
    }

    /// Credits a finished session to the day it ended.
    func record(sessionDuration duration: TimeInterval) {
        guard duration >= Self.minimumSessionDuration else { return }
        let today = key(for: now())
        days[today, default: Day()].seconds += duration
        days[today, default: Day()].sessions += 1
        if let data = try? JSONEncoder().encode(days) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    var minutesToday: Int {
        let seconds = days[key(for: now())]?.seconds ?? 0
        return seconds > 0 ? max(1, Int((seconds / 60).rounded())) : 0
    }

    var sessionsThisWeek: Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now()) else { return 0 }
        var total = 0
        var day = week.start
        while day < week.end {
            total += days[key(for: day)]?.sessions ?? 0
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return total
    }

    /// Consecutive days with a session, ending today, or yesterday if today has none yet.
    var streakDays: Int {
        var day = calendar.startOfDay(for: now())
        if days[key(for: day)] == nil {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var streak = 0
        while days[key(for: day)] != nil {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private func key(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
