import AppKit
import Foundation
import Testing
@testable import ModeRunnerApp

@MainActor
@Test func processTabPopoverFitsItsContentsAfterPresentation() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = directory.appending(path: "config.yaml")
    try """
    tabs:
      - id: test
        title: Test
        buttons:
          - id: mock
            title: Mock
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts:
              - id: server
                title: Server
                executable: /bin/sleep
                arguments: [60]
    """.write(to: config, atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: config)
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    state.startMode(tab.buttons[0], in: tab)
    for _ in 0..<200 {
        if state.selectedRun != nil && state.busyTabs.isEmpty { break }
        try await Task.sleep(for: .milliseconds(20))
    }
    let run = try #require(state.selectedRun)
    let popover = makeProcessTabPopover(content: ProcessTabTooltipTable(state: state, run: run))
    let view = try #require(popover.contentViewController?.view)
    #expect(popover.contentSize.width == 320)
    #expect(popover.contentSize.height > 80)
    #expect(popover.contentSize.height < 180)
    let expectedSize = popover.contentSize

    let window = NSWindow(contentRect: NSRect(x: 200, y: 400, width: 500, height: 300),
                          styleMask: [.borderless], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    let anchor = NSView(frame: NSRect(x: 100, y: 200, width: 180, height: 22))
    window.contentView?.addSubview(anchor)
    window.orderFront(nil)
    defer {
        popover.close()
        window.close()
    }
    popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
    view.layoutSubtreeIfNeeded()
    #expect(popover.isShown)
    #expect(popover.contentSize == expectedSize)
    #expect(view.frame.height < 180)
    #expect(view.window!.frame.height < 220)
    if let output = ProcessInfo.processInfo.environment["MODE_RUNNER_TOOLTIP_PREVIEW"],
       let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
        view.cacheDisplay(in: view.bounds, to: bitmap)
        let data = try #require(bitmap.representation(using: .png, properties: [:]))
        try data.write(to: URL(filePath: output))
    }
    await state.shutdown()
}
