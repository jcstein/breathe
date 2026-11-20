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
}
