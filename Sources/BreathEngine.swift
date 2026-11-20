import Foundation
import Combine

class BreathEngine: ObservableObject {
    enum Phase {
        case idle, inhale, holdFull, exhale, holdEmpty

        var label: String {
            switch self {
            case .idle: return "click to begin"
            case .inhale: return "breathe in"
            case .holdFull, .holdEmpty: return "hold"
            case .exhale: return "breathe out"
            }
        }

        fileprivate var shortLabel: String {
            switch self {
            case .idle: return ""
            case .inhale: return "in"
            case .holdFull, .holdEmpty: return "hold"
            case .exhale: return "out"
            }
        }
    }

    enum Pattern: String, CaseIterable, Identifiable {
        /// 5.5 s in, 5.5 s out: the resonant rate from James Nestor's *Breath*.
        case resonant
        /// 4 s in, hold, out, hold.
        case box

        var id: Self { self }

        var steps: [(phase: Phase, duration: Double)] {
            switch self {
            case .resonant: return [(.inhale, 5.5), (.exhale, 5.5)]
            case .box: return [(.inhale, 4), (.holdFull, 4), (.exhale, 4), (.holdEmpty, 4)]
            }
        }

        var cycleDuration: Double {
            steps.reduce(0) { $0 + $1.duration }
        }

        /// The timings shown under the circle, e.g. "5.5s in · 5.5s out".
        var summary: String {
            steps.map { "\($0.duration.formatted())s \($0.phase.shortLabel)" }.joined(separator: " \u{00B7} ")
        }
    }

    private let tick: Double = 1.0 / 60.0

    /// The pattern the next session follows, remembered across launches.
    @Published var pattern: Pattern {
        didSet { defaults.set(pattern.rawValue, forKey: Self.patternKey) }
    }
    @Published var phase: Phase = .idle
    @Published var elapsed: Double = 0
    @Published var cycleCount: Int = 0
    @Published var isBreathing: Bool = false

    /// Called with the session's length whenever a running session stops.
    var onSessionEnd: ((TimeInterval) -> Void)?

    private var timer: Timer?
    private let now: () -> TimeInterval
    private var sessionStart: TimeInterval?
    private let defaults: UserDefaults
    private static let patternKey = "breathPattern"

    init(defaults: UserDefaults = .standard, now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
        self.defaults = defaults
        self.now = now
        pattern = defaults.string(forKey: Self.patternKey).flatMap(Pattern.init) ?? .resonant
    }

    var phaseDuration: Double {
        pattern.steps.first { $0.phase == phase }?.duration ?? 0
    }

    var progress: Double {
        guard phaseDuration > 0 else { return 0 }
        return min(elapsed / phaseDuration, 1.0)
    }

    var remaining: Double {
        max(phaseDuration - elapsed, 0)
    }

    /// 0 = fully contracted, 1 = fully expanded
    var expansion: Double {
        switch phase {
        case .idle: return 0
        case .inhale: return progress
        case .holdFull: return 1
        case .exhale: return 1.0 - progress
        case .holdEmpty: return 0
        }
    }

    func toggle() {
        if isBreathing { stop() } else { start() }
    }

    func start() {
        sessionStart = now()
        isBreathing = true
        cycleCount = 0
        phase = pattern.steps[0].phase
        elapsed = 0
        startTimer()
    }

    func stop() {
        if let sessionStart { onSessionEnd?(max(now() - sessionStart, 0)) }
        sessionStart = nil
        isBreathing = false
        phase = .idle
        elapsed = 0
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            self?.update()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func update() {
        guard isBreathing, let sessionStart else { return }
        let sessionElapsed = max(now() - sessionStart, 0)
        let steps = pattern.steps
        let cycleElapsed = sessionElapsed.truncatingRemainder(dividingBy: pattern.cycleDuration)
        cycleCount = Int(sessionElapsed / pattern.cycleDuration)
        var index = 0
        var stepStart = 0.0
        while index < steps.count - 1, cycleElapsed >= stepStart + steps[index].duration {
            stepStart += steps[index].duration
            index += 1
        }
        if phase != steps[index].phase { phase = steps[index].phase }
        elapsed = cycleElapsed - stepStart
    }
}
