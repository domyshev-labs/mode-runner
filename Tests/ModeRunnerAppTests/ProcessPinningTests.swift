import Foundation
import Testing
import ModeRunnerCore
@testable import ModeRunnerApp

@MainActor
private func awaitPinState(_ condition: () -> Bool) async throws {
    for _ in 0..<200 {
        if condition() { return }
        try await Task.sleep(for: .milliseconds(20))
    }
    throw NSError(domain: "ProcessPinningTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Timed out waiting for process state"])
}

@MainActor
@Test func pinnedProcessTabsStayVisibleAcrossProjectsAndKeepTheirOwnControls() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    for name in ["alpha", "beta"] {
        try FileManager.default.createDirectory(at: directory.appending(path: name), withIntermediateDirectories: true)
    }
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = directory.appending(path: "config.yaml")
    try """
    tabs:
      - id: alpha
        title: Alpha
        buttons:
          - id: server
            title: Server
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts: [{id: server, title: Server, executable: /bin/sleep, arguments: [60], cwd: alpha}]
      - id: beta
        title: Beta
        buttons:
          - id: server
            title: Server
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts: [{id: server, title: Server, executable: /bin/sleep, arguments: [60], cwd: beta}]
    """.write(to: config, atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: config)
    defer { Task { await state.shutdown() } }
    let alpha = try #require(state.configuration?.tabs.first { $0.id == "alpha" })
    let beta = try #require(state.configuration?.tabs.first { $0.id == "beta" })
    state.startMode(alpha.buttons[0], in: alpha)
    try await awaitPinState { state.runningMode(in: alpha) != nil && state.busyTabs.isEmpty }
    let alphaID = try #require(state.selectedOutputID)
    state.togglePin(alphaID)
    state.selectedTabID = beta.id
    #expect(state.visibleScripts.map(\.id) == [alphaID])
    #expect(state.selectedOutputID == alphaID)
    #expect(state.processTabLabel(try #require(state.selectedRun)) == "Alpha · Server")
    #expect(state.processProjectTitle(try #require(state.selectedRun)) == "Alpha")
    #expect(state.processModeTitle(try #require(state.selectedRun)) == "Server")
    state.startMode(beta.buttons[0], in: beta)
    try await awaitPinState { state.runningMode(in: beta) != nil && state.busyTabs.isEmpty }
    let betaID = try #require(state.selectedOutputID)
    // Identical mode and script IDs in different projects must not collapse the tabs.
    #expect(state.visibleScripts.map(\.id) == [betaID, alphaID])
    state.selectedOutputID = alphaID
    state.stopSelected()
    try await awaitPinState { state.logs[alphaID]?.status?.isRunning == false && state.busyTabs.isEmpty }
    #expect(state.logs[betaID]?.status?.isRunning == true)
    #expect(state.isPinned(alphaID))
    #expect(state.visibleScripts.map(\.id) == [betaID, alphaID])

    state.startMode(alpha.buttons[0], in: alpha)
    try await awaitPinState { state.runningMode(in: alpha) != nil && state.busyTabs.isEmpty }
    let replacement = try #require(state.visibleScripts.first { $0.tabID == alpha.id })
    #expect(replacement.id != alphaID)
    #expect(state.isPinned(replacement.id))
    #expect(!state.isPinned(alphaID))
    #expect(state.visibleScripts.count == 2)
    state.togglePin(replacement.id)
    #expect(state.visibleScripts.map(\.id) == [betaID])
    #expect(state.selectedOutputID == betaID)
    await state.shutdown()
}

@MainActor
@Test func pinningPreservesLocalTabOrderAndAppendsForeignTabs() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = directory.appending(path: "config.yaml")
    try """
    tabs:
      - id: alpha
        title: Alpha
        buttons:
          - id: commands
            title: Commands
            scripts:
              - {id: first, title: First, executable: /bin/echo, arguments: [first]}
              - {id: second, title: Second, executable: /bin/echo, arguments: [second]}
              - {id: third, title: Third, executable: /bin/echo, arguments: [third]}
      - id: beta
        title: Beta
        buttons:
          - id: commands
            title: Commands
            scripts:
              - {id: first, title: First, executable: /bin/echo, arguments: [beta-first]}
              - {id: second, title: Second, executable: /bin/echo, arguments: [beta-second]}
    """.write(to: config, atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: config)
    defer { Task { await state.shutdown() } }
    let alpha = try #require(state.selectedTab)
    let beta = try #require(state.configuration?.tabs.first { $0.id == "beta" })
    state.startMode(alpha.buttons[0], in: alpha)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty && state.runs.allSatisfy { state.logs[$0.id]?.status == .exited(code: 0) } }
    let originalOrder = state.visibleScripts.map(\.id)
    #expect(state.visibleScripts.map(\.script.id) == ["first", "second", "third"])
    state.togglePin(originalOrder[2])
    state.togglePin(originalOrder[1])
    #expect(state.visibleScripts.map(\.id) == originalOrder)
    state.selectedTabID = beta.id
    state.startMode(beta.buttons[0], in: beta)
    try await awaitPinState { state.runs.count == 5 && state.busyTabs.isEmpty && state.runs.allSatisfy { state.logs[$0.id]?.status == .exited(code: 0) } }
    #expect(state.visibleScripts.map(\.tabID) == ["beta", "beta", "alpha", "alpha"])
    #expect(state.visibleScripts.map(\.script.id) == ["first", "second", "second", "third"])
    state.selectedTabID = alpha.id
    #expect(state.visibleScripts.map(\.id) == originalOrder)
    state.togglePin(originalOrder[1])
    state.togglePin(originalOrder[2])
    #expect(state.visibleScripts.map(\.id) == originalOrder)
    await state.shutdown()
}

@MainActor
@Test func pinsAreScopedToTheSelectedConfiguration() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let base = directory.appending(path: "config.yaml")
    let example = directory.appending(path: "config.example.yaml")
    try """
    tabs:
      - id: alpha
        title: Alpha
        buttons:
          - id: echo
            title: Echo
            scripts: [{id: echo, title: Echo, executable: /bin/echo, arguments: [hello]}]
    """.write(to: base, atomically: true, encoding: .utf8)
    try "tabs: [{id: demo, title: Demo, buttons: []}]".write(to: example, atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: base)
    defer { Task { await state.shutdown() } }
    let alpha = try #require(state.selectedTab)
    state.startMode(alpha.buttons[0], in: alpha)
    try await awaitPinState { state.runs.count == 1 && state.logs[state.runs[0].id]?.status == .exited(code: 0) && state.busyTabs.isEmpty }
    let id = try #require(state.selectedOutputID)
    state.togglePin(id)
    state.selectConfiguration(example)
    #expect(state.visibleScripts.isEmpty)
    #expect(!state.isPinned(id))
    state.selectConfiguration(base)
    #expect(state.isPinned(id))
    #expect(state.visibleScripts.map(\.id) == [id])
    let original = try String(contentsOf: base, encoding: .utf8)
    try "tabs: [{id: other, title: Other, buttons: []}]".write(to: base, atomically: true, encoding: .utf8)
    state.reload()
    #expect(state.visibleScripts.isEmpty)
    try original.write(to: base, atomically: true, encoding: .utf8)
    state.reload()
    #expect(state.visibleScripts.map(\.id) == [id])
    await state.shutdown()
}

@MainActor
@Test func pinnedCompletedLogsSurviveHistoryCleanupAndCanBeClosedExplicitly() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = directory.appending(path: "config.yaml")
    try """
    tabs:
      - id: alpha
        title: Alpha
        buttons:
          - id: tools
            title: Tools
            environment: {ZDOTDIR: "\(directory.path)"}
            runner: [/bin/echo]
            source: {type: json_file, path: items.json}
      - {id: beta, title: Beta, buttons: []}
    """.write(to: config, atomically: true, encoding: .utf8)
    try "[]".write(to: directory.appending(path: "items.json"), atomically: true, encoding: .utf8)
    let state = AppState(requireStopConfirmation: false, configURL: config)
    defer { Task { await state.shutdown() } }
    let alpha = try #require(state.selectedTab)
    let button = alpha.buttons[0]
    state.launch(MenuItem(id: "first", title: "First", arguments: ["first"]), button: button, tab: alpha)
    let first = try #require(state.selectedOutputID)
    try await awaitPinState { state.logs[first]?.status == .exited(code: 0) }
    state.togglePin(first)
    for index in 0..<25 {
        state.launch(MenuItem(id: "item-\(index)", title: "Item", arguments: [String(index)]), button: button, tab: alpha)
        let id = try #require(state.selectedOutputID)
        try await awaitPinState { state.logs[id]?.status == .exited(code: 0) }
    }
    #expect(state.logs[first] != nil)
    #expect(state.isPinned(first))
    state.selectedTabID = "beta"
    #expect(state.visibleScripts.map(\.id) == [first])
    #expect(state.canClose(first))
    state.close(first)
    #expect(state.logs[first] == nil)
    #expect(!state.isPinned(first))
    #expect(state.visibleScripts.isEmpty)
    await state.shutdown()
}

@MainActor
private func modePinConfiguration(in directory: URL, conflicting: Bool, foreignProject: Bool = false) throws -> URL {
    let config = directory.appending(path: "config.yaml")
    let projectBoundary = foreignProject ? """
      - id: beta
        title: Beta
        buttons:
    """ : ""
    try """
    tabs:
      - id: alpha
        title: Alpha
        buttons:
          - id: primary
            title: Primary
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts:
              - {id: pinned, title: Pinned :48010, executable: /bin/sleep, arguments: [60]}
              - {id: ordinary, title: Ordinary :48011, executable: /bin/sleep, arguments: [60]}
    \(projectBoundary)
          - id: secondary
            title: Secondary
            on_deactivate: {sigint: true, sigkill: true, timeout: 0.2s}
            scripts:
              - {id: new, title: New :\(conflicting ? 48010 : 48012), executable: /bin/sleep, arguments: [60]}
    """.write(to: config, atomically: true, encoding: .utf8)
    return config
}

@MainActor
@Test func switchingModesKeepsPinsAndReusesThemOnReturn() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let state = AppState(requireStopConfirmation: false, configURL: try modePinConfiguration(in: directory, conflicting: false))
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    let primary = tab.buttons[0]
    let secondary = tab.buttons[1]
    state.startMode(primary, in: tab)
    try await awaitPinState { state.runs.count == 2 && state.busyTabs.isEmpty && state.runs.allSatisfy { state.logs[$0.id]?.status?.isRunning == true } }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    let ordinary = try #require(state.runs.first { $0.script.id == "ordinary" })
    state.togglePin(pinned.id)
    state.startMode(secondary, in: tab)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty }
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    #expect(state.logs[ordinary.id]?.status?.isRunning == false)
    #expect(state.runningMode(in: tab)?.id == secondary.id)
    #expect(state.errorMessage == nil)
    state.restartMode(secondary, in: tab)
    try await awaitPinState { state.runs.count == 4 && state.busyTabs.isEmpty }
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    state.startMode(primary, in: tab)
    try await awaitPinState { state.runs.count == 5 && state.busyTabs.isEmpty }
    #expect(state.runs.filter { $0.script.id == "pinned" }.count == 1)
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    #expect(state.runningMode(in: tab)?.id == primary.id)
    #expect(state.runs.filter { state.logs[$0.id]?.status?.isRunning == true }.count == 2)
    state.stopMode(primary, in: tab)
    try await awaitPinState { state.busyTabs.isEmpty && state.logs[pinned.id]?.status?.isRunning == false }
    await state.shutdown()
}

@MainActor
@Test(arguments: [false, true])
func pinnedPortConflictCancelsStartBeforeStoppingAnything(foreignProject: Bool) async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let state = AppState(requireStopConfirmation: false, configURL: try modePinConfiguration(in: directory, conflicting: true, foreignProject: foreignProject))
    defer { Task { await state.shutdown() } }
    let source = try #require(state.configuration?.tabs.first)
    let target = foreignProject ? try #require(state.configuration?.tabs.last) : source
    state.startMode(source.buttons[0], in: source)
    try await awaitPinState { state.runs.count == 2 && state.busyTabs.isEmpty && state.runs.allSatisfy { state.logs[$0.id]?.status?.isRunning == true } }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    state.togglePin(pinned.id)
    state.selectedTabID = target.id
    state.startMode(try #require(target.buttons.first { $0.id == "secondary" }), in: target)
    try await awaitPinState { state.busyTabs.isEmpty }
    #expect(state.runs.count == 2)
    #expect(state.runs.allSatisfy { state.logs[$0.id]?.status?.isRunning == true && !$0.requestedStop })
    #expect(state.errorMessage == "Start cancelled: port 48010 is used by pinned process “'/bin/sleep' '60'” in project “Alpha”. Stop it to free the port.")
    state.selectedTabID = source.id
    state.togglePin(pinned.id)
    state.selectedTabID = target.id
    state.startMode(try #require(target.buttons.first { $0.id == "secondary" }), in: target)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty }
    #expect(state.errorMessage == nil)
    await state.shutdown()
}

@MainActor
@Test func startingSelectedLogChecksPinnedPortsWithoutClearingOutput() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let state = AppState(requireStopConfirmation: false, configURL: try modePinConfiguration(in: directory, conflicting: true))
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    state.startMode(tab.buttons[1], in: tab)
    try await awaitPinState { state.runs.count == 1 && state.busyTabs.isEmpty }
    let stopped = try #require(state.runs.first)
    state.startMode(tab.buttons[0], in: tab)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    state.togglePin(pinned.id)
    let ordinary = try #require(state.runs.first { $0.script.id == "ordinary" })
    state.selectMode(tab.buttons[1], in: tab)
    state.selectedOutputID = stopped.id
    let status = state.logs[stopped.id]?.status
    let output = state.logs[stopped.id]?.buffer.string
    #expect(state.canStartSelected)
    state.startSelected()
    #expect(state.errorMessage?.contains("port 48010") == true)
    #expect(state.logs[stopped.id]?.status == status)
    #expect(state.logs[stopped.id]?.buffer.string == output)
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    #expect(state.logs[ordinary.id]?.status?.isRunning == true)
    #expect(state.busyTabs.isEmpty)
    await state.shutdown()
}

@MainActor
@Test func individualStartKeepsOtherPortsAndPinnedSibling() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let state = AppState(requireStopConfirmation: false, configURL: try modePinConfiguration(in: directory, conflicting: false))
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    let targetMode = tab.buttons[1]
    state.startMode(targetMode, in: tab)
    try await awaitPinState { state.runs.count == 1 && state.busyTabs.isEmpty }
    let target = try #require(state.runs.first)
    state.startMode(tab.buttons[0], in: tab)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    let ordinary = try #require(state.runs.first { $0.script.id == "ordinary" })
    state.togglePin(pinned.id)
    let pinnedStatus = state.logs[pinned.id]?.status
    #expect(state.processModeTitle(pinned) == "Primary")
    state.selectMode(targetMode, in: tab)
    state.selectedOutputID = target.id
    #expect(!state.visibleScripts.contains { $0.id == ordinary.id })
    #expect(state.canStartSelected)
    state.startSelected()
    state.startSelected()
    try await awaitPinState { state.busyTabs.isEmpty && state.logs[target.id]?.status?.isRunning == true }
    #expect(state.runs.count == 3)
    #expect(state.logs[ordinary.id]?.status?.isRunning == true)
    #expect(state.logs[pinned.id]?.status == pinnedStatus)
    #expect(state.selectedOutputID == target.id)
    #expect(state.processModeTitle(pinned) == "Primary")
    #expect(state.processModeTitle(target) == "Secondary")
    #expect(state.runningMode(in: tab)?.id == targetMode.id)
    #expect(state.errorMessage == nil)
    await state.shutdown()
}

@MainActor
@Test func modeSwitchConfirmationListsOnlyUnpinnedProcessesAndSupportsCancel() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let state = AppState(configURL: try modePinConfiguration(in: directory, conflicting: false))
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    state.startMode(tab.buttons[0], in: tab)
    try await awaitPinState { state.runs.count == 2 && state.busyTabs.isEmpty }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    let ordinary = try #require(state.runs.first { $0.script.id == "ordinary" })
    state.togglePin(pinned.id)
    state.startMode(tab.buttons[1], in: tab)
    try await awaitPinState { state.pendingStopConfirmation != nil }
    let confirmation = try #require(state.pendingStopConfirmation)
    #expect(confirmation.message.contains("mode “Primary”"))
    #expect(confirmation.processes == ["Ordinary • 48011"])
    #expect(state.runs.allSatisfy { state.logs[$0.id]?.status?.isRunning == true && !$0.requestedStop })
    state.resolveStopConfirmation(false)
    try await awaitPinState { state.busyTabs.isEmpty }
    #expect(state.runs.count == 2)
    #expect(state.logs[ordinary.id]?.status?.isRunning == true)
    state.startMode(tab.buttons[1], in: tab)
    try await awaitPinState { state.pendingStopConfirmation != nil }
    state.resolveStopConfirmation(true)
    try await awaitPinState { state.busyTabs.isEmpty && state.runs.count == 3 }
    #expect(state.logs[ordinary.id]?.status?.isRunning == false)
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    #expect(state.runningMode(in: tab)?.id == "secondary")
    await state.shutdown()
}

@MainActor
@Test func individualPortConfirmationStopsOnlyTheConflictingProcess() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let config = try modePinConfiguration(in: directory, conflicting: false)
    let text = try String(contentsOf: config, encoding: .utf8)
    try text.replacingOccurrences(of: "New :48012", with: "New :48011").write(to: config, atomically: true, encoding: .utf8)
    let state = AppState(configURL: config)
    defer { Task { await state.shutdown() } }
    let tab = try #require(state.selectedTab)
    state.startMode(tab.buttons[1], in: tab)
    try await awaitPinState { state.runs.count == 1 && state.busyTabs.isEmpty }
    let target = try #require(state.runs.first)
    state.stopMode(tab.buttons[1], in: tab)
    try await awaitPinState { state.busyTabs.isEmpty && state.logs[target.id]?.status?.isRunning == false }
    state.startMode(tab.buttons[0], in: tab)
    try await awaitPinState { state.runs.count == 3 && state.busyTabs.isEmpty }
    let pinned = try #require(state.runs.first { $0.script.id == "pinned" })
    let conflicting = try #require(state.runs.first { $0.script.id == "ordinary" })
    state.togglePin(pinned.id)
    state.selectMode(tab.buttons[1], in: tab)
    state.selectedOutputID = target.id
    let originalLog = state.logs[target.id]
    state.startSelected()
    try await awaitPinState { state.pendingStopConfirmation != nil }
    #expect(state.pendingStopConfirmation?.message.contains("Port 48011") == true)
    #expect(state.pendingStopConfirmation?.message.contains("mode “Primary”") == true)
    #expect(state.pendingStopConfirmation?.processes == ["Ordinary • 48011"])
    #expect(state.logs[conflicting.id]?.status?.isRunning == true)
    state.resolveStopConfirmation(false)
    try await awaitPinState { state.busyTabs.isEmpty }
    #expect(state.logs[target.id]?.status == originalLog?.status)
    #expect(state.logs[target.id]?.buffer.string == originalLog?.buffer.string)
    #expect(state.logs[conflicting.id]?.status?.isRunning == true)
    state.startSelected()
    try await awaitPinState { state.pendingStopConfirmation != nil }
    state.resolveStopConfirmation(true)
    try await awaitPinState { state.busyTabs.isEmpty && state.logs[target.id]?.status?.isRunning == true }
    #expect(state.logs[conflicting.id]?.status?.isRunning == false)
    #expect(state.logs[pinned.id]?.status?.isRunning == true)
    #expect(state.runs.count == 3)
    await state.shutdown()
}
