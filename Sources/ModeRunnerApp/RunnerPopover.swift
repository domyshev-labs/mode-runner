import AppKit
import SwiftUI

@MainActor
final class RunnerPopover: NSObject, NSPopoverDelegate {
    static let contentSize = NSSize(width: 710, height: 510)
    static let rightEdgeInset: CGFloat = 20
    private(set) var popover = NSPopover()
    private var needsRebuild = true
    private var outsideClickMonitor: Any?

    override init() {
        super.init()
        popover.behavior = .transient
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification, object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersChanged(_ notification: Notification) {
        // A hidden popover can retain geometry from a disconnected display.
        // Rebuild on the next presentation, once the status button is on its new screen.
        needsRebuild = true
    }

    func prepare<Content: View>(content: () -> Content) -> NSPopover {
        guard needsRebuild else { return popover }
        let behavior = popover.behavior
        popover.close()
        let replacement = NSPopover()
        replacement.behavior = behavior
        replacement.delegate = self
        let controller = NSHostingController(rootView: content())
        controller.sizingOptions = []
        controller.view.setFrameSize(Self.contentSize)
        replacement.contentViewController = controller
        replacement.contentSize = Self.contentSize
        popover = replacement
        needsRebuild = false
        return replacement
    }

    func insetFromRightEdge(of screen: NSScreen? = nil) {
        guard let window = popover.contentViewController?.view.window,
              let screen = screen ?? window.screen else { return }
        let origin = Self.insetOrigin(for: window.frame, visibleFrame: screen.visibleFrame)
        if origin != window.frame.origin { window.setFrameOrigin(origin) }
    }

    func popoverDidShow(_ notification: Notification) {
        // Apply the inset again after AppKit finishes its presentation animation.
        insetFromRightEdge()
        stopMonitoringOutsideClicks()
        // Transient dismissal can stop working after native menus change focus.
        // Global mouse events exclude this app, so its menus remain interactive.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.popover.performClose(nil)
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        stopMonitoringOutsideClicks()
    }

    private func stopMonitoringOutsideClicks() {
        if let outsideClickMonitor {
            NSEvent.removeMonitor(outsideClickMonitor)
            self.outsideClickMonitor = nil
        }
    }

    static func insetOrigin(for frame: NSRect, visibleFrame: NSRect) -> NSPoint {
        NSPoint(x: max(visibleFrame.minX,
                       min(frame.minX, visibleFrame.maxX - rightEdgeInset - frame.width)),
                y: frame.minY)
    }
}
