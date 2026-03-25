import AppKit
import Combine

class StatusBarView: NSView {
    private let engine: BreathEngine
    private var cancellables = Set<AnyCancellable>()
    private var displayLink: CVDisplayLink?
    private var currentExpansion: Double = 0

    var onClick: (() -> Void)?

    init(engine: BreathEngine) {
        self.engine = engine
        super.init(frame: NSRect(x: 0, y: 0, width: 28, height: 22))

        engine.$elapsed
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.needsDisplay = true
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        let centerX = bounds.midX
        let centerY = bounds.midY

        // Use white to match other menu bar icons
        let iconColor = NSColor.white

        if engine.isBreathing {
            let minRadius: CGFloat = 3.5
            let maxRadius: CGFloat = 9.0
            let exp = CGFloat(engine.expansion)
            let radius = minRadius + (maxRadius - minRadius) * exp
            let alpha = 0.5 + 0.5 * exp

            // Glow
            let glowRadius = radius * 1.6
            ctx.setFillColor(iconColor.withAlphaComponent(0.15).cgColor)
            ctx.fillEllipse(in: CGRect(
                x: centerX - glowRadius,
                y: centerY - glowRadius,
                width: glowRadius * 2,
                height: glowRadius * 2
            ))

            // Main dot
            ctx.setFillColor(iconColor.withAlphaComponent(alpha).cgColor)
            ctx.fillEllipse(in: CGRect(
                x: centerX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        } else {
            let radius: CGFloat = 4.0
            ctx.setFillColor(iconColor.withAlphaComponent(0.8).cgColor)
            ctx.fillEllipse(in: CGRect(
                x: centerX - radius,
                y: centerY - radius,
                width: radius * 2,
                height: radius * 2
            ))
        }
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}
