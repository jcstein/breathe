import Foundation
import Combine

class BreathEngine: ObservableObject {
    enum Phase: String {
        case idle = "tap to begin"
        case inhale = "breathe in"
        case exhale = "breathe out"
    }

    let inhaleDuration: Double = 5.5
    let exhaleDuration: Double = 5.5
    private let tick: Double = 1.0 / 60.0

    @Published var phase: Phase = .idle
    @Published var elapsed: Double = 0
    @Published var cycleCount: Int = 0
    @Published var isBreathing: Bool = false

    private var timer: Timer?

    var phaseDuration: Double {
        phase == .inhale ? inhaleDuration : exhaleDuration
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
        case .exhale: return 1.0 - progress
        }
    }

    func toggle() {
        if isBreathing { stop() } else { start() }
    }

    func start() {
        isBreathing = true
        cycleCount = 0
        phase = .inhale
        elapsed = 0
        startTimer()
    }

    func stop() {
        isBreathing = false
        phase = .idle
        elapsed = 0
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.elapsed += self.tick
                if self.elapsed >= self.phaseDuration {
                    if self.phase == .inhale {
                        self.phase = .exhale
                    } else {
                        self.cycleCount += 1
                        self.phase = .inhale
                    }
                    self.elapsed = 0
                }
            }
        }
    }
}
