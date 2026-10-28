import SwiftUI

/// Shared controls for the output toolbar and the hovered process tab.
struct ProcessRunActions: View {
    @ObservedObject var state: AppState
    let runID: String
    var showIcons = false

    var body: some View {
        if let log = state.logs[runID] {
            let busy = state.runs.first(where: { $0.id == runID })
                .map { state.busyTabs.contains($0.tabID) } ?? true
            let restarting = state.restartingRuns.contains(runID)
            let stopping = state.stoppingRuns.contains(runID)
            let starting = state.startingRuns.contains(runID)
            if starting || (log.status?.isRunning == false && !restarting && !stopping) {
                ProcessActionButton(title: "Start", loading: starting,
                                    systemImage: showIcons ? "play.fill" : nil) {
                    state.startRun(runID)
                }
                .help("Start this command")
                .disabled(!state.canStartRun(runID))
            } else if log.status?.isRunning == true || restarting || stopping {
                ProcessActionButton(title: "Reload", loading: restarting,
                                    systemImage: showIcons ? "arrow.clockwise" : nil) {
                    state.reloadRun(runID)
                }
                .help("Restart this command")
                .disabled(log.status == .starting || log.status == .stopping || restarting || stopping || busy)
                ProcessActionButton(title: "Stop", loading: stopping,
                                    systemImage: showIcons ? "stop.fill" : nil) {
                    state.stopRun(runID)
                }
                .disabled(log.status == .stopping || restarting || stopping || busy)
            }
            Button { state.clearLog(runID) } label: {
                if showIcons {
                    Label("Clear", systemImage: "trash")
                } else {
                    Text("Clear")
                }
            }
        }
    }
}
