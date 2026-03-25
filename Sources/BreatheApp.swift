import SwiftUI
import AppKit

@main
struct BreatheApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    let engine = BreathEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: 28)

        let barView = StatusBarView(engine: engine)
        barView.onClick = { [weak self] in self?.togglePopover() }
        barView.onRightClick = { [weak self] in self?.showMenu() }
        statusItem.button?.addSubview(barView)
        barView.frame = statusItem.button?.bounds ?? NSRect(x: 0, y: 0, width: 28, height: 22)
        barView.autoresizingMask = [.width, .height]

        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 340)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: BreathView(engine: engine))
    }

    func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showMenu() {
        let menu = NSMenu()
        let toggleTitle = engine.isBreathing ? "Pause" : "Start"
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
