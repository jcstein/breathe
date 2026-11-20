import SwiftUI
import AppKit
import Combine

@main
struct BreatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    let engine = BreathEngine()
    let stats = UsageStats()
    private var phaseSubscription: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        engine.onSessionEnd = { [stats] in stats.record(sessionDuration: $0) }
        endSessionOnLockOrSleep()

        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemPressed)
        statusItem.button?.setAccessibilityLabel("Breathe")
        phaseSubscription = engine.$phase
            .removeDuplicates()
            .sink { [weak self] phase in self?.updateStatusAccessibilityValue(for: phase) }

        let barView = StatusBarView(engine: engine)
        barView.setAccessibilityElement(false)
        barView.onClick = { [weak self] in self?.togglePopover() }
        barView.onRightClick = { [weak self] in self?.showMenu() }
        statusItem.button?.addSubview(barView)
        barView.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: 28, height: 22)
        barView.autoresizingMask = [.width, .height]

        popover = NSPopover()
        popover.delegate = self
        popover.behavior = .transient
    }

    /// VoiceOver presses arrive through `performClick`, which flashes the button in an
    /// event-tracking run loop and then clears its highlight, so toggle once that is over.
    @objc func statusItemPressed() {
        RunLoop.main.perform(inModes: [.default]) { [weak self] in self?.togglePopover() }
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            let hostingController = NSHostingController(rootView: BreathView(engine: engine, stats: stats))
            hostingController.sizingOptions = [.preferredContentSize]
            popover.contentViewController = hostingController
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            button.highlight(true)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    /// Locking, sleeping or switching away from the Mac ends the session, so time away is not counted.
    func endSessionOnLockOrSleep(
        workspaceCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        distributedCenter: NotificationCenter = DistributedNotificationCenter.default()
    ) {
        for name in [NSWorkspace.willSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            workspaceCenter.addObserver(self, selector: #selector(endSession), name: name, object: nil)
        }
        distributedCenter.addObserver(self, selector: #selector(endSession), name: .screenIsLocked, object: nil)
    }

    @objc private func endSession(_ notification: Notification) {
        engine.stop()
    }

    /// What VoiceOver reads after "Breathe" on the status item, so the session state is heard, not only seen.
    static func statusAccessibilityValue(for phase: BreathEngine.Phase) -> String {
        switch phase {
        case .idle: return "idle"
        case .inhale, .exhale: return phase.rawValue
        }
    }

    private func updateStatusAccessibilityValue(for phase: BreathEngine.Phase) {
        guard let button = statusItem.button else { return }
        button.setAccessibilityValue(Self.statusAccessibilityValue(for: phase))
        NSAccessibility.post(element: button, notification: .valueChanged)
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem.button?.highlight(false)
        // A hidden hosting view can still update its layout on every engine tick.
        popover.contentViewController = nil
    }

    func showMenu() {
        let menu = NSMenu()
        let toggleTitle = engine.isBreathing ? "End Session" : "Start"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleBreathing), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Breathe", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // Reset so left-click opens popover again
    }

    @objc func toggleBreathing() { engine.toggle() }
    @objc func quitApp() { NSApp.terminate(nil) }
}

private extension Notification.Name {
    static let screenIsLocked = Notification.Name("com.apple.screenIsLocked")
}
