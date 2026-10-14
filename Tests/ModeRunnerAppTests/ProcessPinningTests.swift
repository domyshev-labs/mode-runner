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
    let state = AppState(configURL: config)
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
    let state = AppState(configURL: config)
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
    let state = AppState(configURL: base)
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
    let state = AppState(configURL: config)
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
