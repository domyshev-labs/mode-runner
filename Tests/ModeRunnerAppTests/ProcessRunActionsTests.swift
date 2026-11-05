import Foundation
import Testing
import ModeRunnerCore
@testable import ModeRunnerApp

@MainActor
private func waitForRunAction(_ condition: () -> Bool) async throws {
    for _ in 0..<300 {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(20))
    }
    throw NSError(domain: "ProcessRunActionsTests", code: 1,
                  userInfo: [NSLocalizedDescriptionKey: "Timed out waiting for process action"])
}

@MainActor
@Test func hoveredProcessActionsLeaveTheSelectedProcessAndItsLogAlone() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = directory.appending(path: "config.yaml")
    try """
    tabs:
      - id: test
        title: Test
        buttons:
          - id: servers
            title: Servers
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts:
              - id: hovered
                title: Hovered
                executable: /bin/sh
                arguments: [-c, 'echo hovered-ready; exec /bin/sleep 60']
              - id: selected
                title: Selected
                executable: /bin/sh
                arguments: [-c, 'echo selected-ready; exec /bin/sleep 60']
    """.write(to: config, atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: config)
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    state.startMode(tab.buttons[0], in: tab)
    try await waitForRunAction {
        state.runs.count == 2 && state.busyTabs.isEmpty &&
            state.runs.allSatisfy { state.logs[$0.id]?.status?.isRunning == true }
    }
    let hoveredID = try #require(state.runs.first { $0.script.id == "hovered" }?.id)
    let selectedID = try #require(state.runs.first { $0.script.id == "selected" }?.id)
    state.selectedOutputID = selectedID
    try await waitForRunAction {
        state.logs[hoveredID]?.buffer.string.contains("hovered-ready") == true &&
            state.logs[selectedID]?.buffer.string.contains("selected-ready") == true
    }
    let selectedStatus = state.logs[selectedID]?.status
    let selectedLog = state.logs[selectedID]?.buffer.string
    state.clearLog(hoveredID)
    #expect(state.logs[hoveredID]?.buffer.count == 0)
    #expect(state.logs[selectedID]?.buffer.string == selectedLog)

    let previousStatus = state.logs[hoveredID]?.status
    state.reloadRun(hoveredID)
    #expect(state.restartingRuns.contains(hoveredID))
    try await waitForRunAction {
        state.busyTabs.isEmpty && state.logs[hoveredID]?.status?.isRunning == true &&
            state.logs[hoveredID]?.status != previousStatus
    }
    #expect(state.selectedOutputID == selectedID)
    #expect(state.logs[selectedID]?.status == selectedStatus)

    state.stopRun(hoveredID)
    try await waitForRunAction {
        state.busyTabs.isEmpty && state.logs[hoveredID]?.status?.isRunning == false
    }
    #expect(state.canStartRun(hoveredID))
    #expect(!state.canStartRun(selectedID))
    state.startRun(hoveredID)
    #expect(state.startingRuns.contains(hoveredID))
    try await waitForRunAction {
        state.busyTabs.isEmpty && state.logs[hoveredID]?.status?.isRunning == true
    }
    #expect(state.selectedOutputID == selectedID)
    #expect(state.logs[selectedID]?.status == selectedStatus)
    #expect(state.logs[selectedID]?.buffer.string == selectedLog)
    #expect(!state.canStartRun("missing"))
    state.startRun("missing")
    state.stopRun("missing")
    state.reloadRun("missing")
    state.clearLog("missing")
    #expect(state.logs["missing"] == nil)
    await state.shutdown()
}
