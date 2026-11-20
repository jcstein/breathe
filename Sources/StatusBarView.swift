import AppKit
import Combine

class StatusBarView: NSView {
    private let engine: BreathEngine
    private var cancellables = Set<AnyCancellable>()
    private var drawnAlphaStep: Int?

    var onClick: (() -> Void)?
    var onRightClick: (() -> Void)?

    init(engine: BreathEngine) {
        self.engine = engine
        super.init(frame: NSRect(x: 0, y: 0, width: 28, height: 22))

        // @Published emits before storing the new value, so read the engine once the tick is done.
        engine.$elapsed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.alphaStep != self.drawnAlphaStep else { return }
                self.needsDisplay = true
            }
            .store(in: &cancellables)
    }

    required init?(coder: NSCoder) { fatalError() }

    private var breathingAlpha: CGFloat { 0.5 + 0.5 * CGFloat(engine.expansion) }

    /// The breathing dot's alpha in 8-bit steps, the finest change the menu bar shows; nil when idle.
    /// Its radius moves less than a pixel per step, so ticks that keep the step skip the redraw.
    private var alphaStep: Int? {
        engine.isBreathing ? Int((breathingAlpha * 255).rounded()) : nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawnAlphaStep = alphaStep

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let bounds = self.bounds

        let centerX = bounds.midX
        let centerY = bounds.midY

        // Resolves against the menu bar appearance, like template icons
        let iconColor = NSColor.labelColor

        if engine.isBreathing {
            let minRadius: CGFloat = 3.5
            let maxRadius: CGFloat = 9.0
            let exp = CGFloat(engine.expansion)
            let radius = minRadius + (maxRadius - minRadius) * exp
            let alpha = breathingAlpha

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
        if event.modifierFlags.contains(.control) {
            onRightClick?()
        } else {
            onClick?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?()
    }
}
