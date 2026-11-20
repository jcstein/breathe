import AppKit
import XCTest
@testable import Breathe

final class AppDelegateTests: XCTestCase {
    func testClosedPopoverDoesNotHoldContentController() async throws {
        try await MainActor.run {
            let app = NSApplication.shared
            let originalPolicy = app.activationPolicy()
            defer { app.setActivationPolicy(originalPolicy) }

            let delegate = AppDelegate()
            delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
            let statusItem = try XCTUnwrap(delegate.statusItem)
            defer { NSStatusBar.system.removeStatusItem(statusItem) }

            let popover = try XCTUnwrap(delegate.popover)
            XCTAssertNil(popover.contentViewController)

            popover.contentViewController = NSViewController()
            delegate.popoverDidClose(Notification(name: NSPopover.didCloseNotification, object: popover))
            XCTAssertNil(popover.contentViewController)
        }
    }

    @MainActor
    func testAccessibilityPressHighlightsStatusItemWhilePopoverIsShown() throws {
        let app = NSApplication.shared
        let originalPolicy = app.activationPolicy()
        defer { app.setActivationPolicy(originalPolicy) }

        let delegate = AppDelegate()
        delegate.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))
        let statusItem = try XCTUnwrap(delegate.statusItem)
        defer { NSStatusBar.system.removeStatusItem(statusItem) }
        let button = try XCTUnwrap(statusItem.button)
        let popover = try XCTUnwrap(delegate.popover)
        defer { popover.close() }
        runMainLoop(until: { button.window?.isVisible == true })

        _ = button.accessibilityPerformPress()
        runMainLoop(until: { popover.isShown })
        XCTAssertTrue(popover.isShown)
        XCTAssertTrue(button.isHighlighted)

        _ = button.accessibilityPerformPress()
        runMainLoop(until: { !popover.isShown })
        XCTAssertFalse(popover.isShown)
        XCTAssertFalse(button.isHighlighted)
    }

    private func runMainLoop(until condition: () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
}
