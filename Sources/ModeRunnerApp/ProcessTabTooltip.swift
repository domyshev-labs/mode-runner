import AppKit
import ModeRunnerCore
import SwiftUI

struct ProcessTabTooltipContent {
    let mode: String
    let command: String
    let port: String

    init(script: RunnerScript, mode: String) {
        self.mode = mode
        command = script.displayCommand
        port = configuredLocalURL(for: script)?.port.map(String.init) ?? "Not configured"
    }
}

// Tracking stays passive so selecting and pinning the underlying tab still work.
struct ProcessTabTooltip: NSViewRepresentable {
    @ObservedObject var state: AppState
    let run: ScriptRun

    func makeNSView(context: Context) -> ProcessTabTooltipTrackingView {
        ProcessTabTooltipTrackingView(frame: .zero)
    }

    func updateNSView(_ view: ProcessTabTooltipTrackingView, context: Context) {
        view.content = ProcessTabTooltipTable(state: state, run: run)
    }

    static func dismantleNSView(_ view: ProcessTabTooltipTrackingView, coordinator: ()) {
        view.hideTooltip()
    }
}

@MainActor
final class ProcessTabTooltipTrackingView: NSView {
    fileprivate var content: ProcessTabTooltipTable? {
        didSet {
            if let content, let host = popover?.contentViewController as? NSHostingController<ProcessTabTooltipTable> {
                host.rootView = content
                sizeProcessTabPopover(popover)
            }
        }
    }
    private var hoverArea: NSTrackingArea?
    private var showTimer: Timer?
    private var hoverTimer: Timer?
    private var popover: NSPopover?
    private var lastHover = Date()

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(rect: .zero,
            options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseEntered(with event: NSEvent) {
        showTimer?.invalidate()
        lastHover = Date()
        guard popover == nil else { return }
        let timer = Timer(timeInterval: 0.5, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.showTooltip() }
        }
        showTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    override func mouseExited(with event: NSEvent) {
        showTimer?.invalidate()
        showTimer = nil
        // The hover timer gives the pointer time to cross the gap to the controls.
        lastHover = Date()
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        hideTooltip()
        super.viewWillMove(toWindow: newWindow)
    }

    func hideTooltip() {
        showTimer?.invalidate()
        showTimer = nil
        hoverTimer?.invalidate()
        hoverTimer = nil
        popover?.close()
        popover = nil
    }

    private func showTooltip() {
        guard let content, let window, window.isVisible, NSApp.isActive,
              visibleRect.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil)) else { return }
        let popover = makeProcessTabPopover(content: content)
        self.popover = popover
        // AppKit anchors the arrow to the actual tab, including inside a scrolled row.
        popover.show(relativeTo: bounds, of: self, preferredEdge: .minY)
        lastHover = Date()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.checkHover() }
        }
        hoverTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func checkHover() {
        guard let window, window.isVisible, NSApp.isActive,
              let popover, popover.isShown else {
            hideTooltip()
            return
        }
        let pointer = NSEvent.mouseLocation
        let anchor = window.convertToScreen(convert(visibleRect, to: nil))
        let overPopover = popover.contentViewController?.view.window?.frame.contains(pointer) == true
        if anchor.contains(pointer) || overPopover {
            lastHover = Date()
        } else if Date().timeIntervalSince(lastHover) > 0.3 {
            hideTooltip()
        }
    }
}

@MainActor
func makeProcessTabPopover(content: ProcessTabTooltipTable) -> NSPopover {
    let popover = NSPopover()
    popover.behavior = .applicationDefined
    popover.animates = false
    let host = NSHostingController(rootView: content)
    host.sizingOptions = []
    popover.contentViewController = host
    sizeProcessTabPopover(popover)
    return popover
}

@MainActor
private func sizeProcessTabPopover(_ popover: NSPopover?) {
    guard let popover,
          let host = popover.contentViewController as? NSHostingController<ProcessTabTooltipTable> else { return }
    let size = host.sizeThatFits(in: NSSize(width: 320, height: CGFloat.greatestFiniteMagnitude))
    host.view.setFrameSize(size)
    popover.contentSize = size
}

struct ProcessTabTooltipTable: View {
    @ObservedObject var state: AppState
    let run: ScriptRun

    var body: some View {
        let content = ProcessTabTooltipContent(script: run.script, mode: state.processModeTitle(run))
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ProcessRunActions(state: state, runID: run.id, showIcons: true)
            }
            .controlSize(.small)
            .buttonStyle(LogActionButtonStyle())
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                GridRow {
                    Text("mode:").foregroundStyle(.secondary)
                    Text(verbatim: content.mode)
                }
                GridRow {
                    Text("command:").foregroundStyle(.secondary)
                    Text(verbatim: content.command)
                        .textSelection(.enabled)
                }
                GridRow {
                    Text("port:").foregroundStyle(.secondary)
                    Text(verbatim: content.port)
                }
            }
        }
        .font(.system(size: 11))
        .padding(10)
        .frame(width: 320, alignment: .leading)
        .fixedSize(horizontal: true, vertical: true)
    }
}
