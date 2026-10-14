import Foundation
import Testing
@testable import ModeRunnerCore

@Test func decodesBothCommandFormsAndDefaults() throws {
    let yaml = """
    tabs:
      - id: dev
        title: Development
        buttons:
          - id: all
            title: All
            on_deactivate:
              sigint: true
              timeout: 250ms
            scripts:
              - id: shell
                title: Shell
                command: yarn dev
              - id: direct
                title: Direct
                executable: /bin/echo
                arguments: [hello]
    """
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try yaml.write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }

    let config = try ConfigurationLoader().load(from: url)
    #expect(config.tabs[0].buttons[0].scripts.count == 2)
    #expect(config.tabs[0].buttons[0].onDeactivate.timeout.seconds == 0.25)
    #expect(config.tabs[0].buttons[0].onDeactivate.sigkill == false)
    #expect(config.tabs[0].buttons[0].scripts[0].launchSpec().executable == "/bin/zsh")
}

@Test func rejectsDuplicateIDs() throws {
    let script = RunnerScript(id: "echo", title: "Echo", executable: "/bin/echo")
    let config = RunnerConfiguration(tabs: [
        RunnerTab(id: "same", title: "One", buttons: [RunnerMode(id: "mode", title: "Mode", scripts: [script])]),
        RunnerTab(id: "same", title: "Two", buttons: []),
    ])
    #expect(throws: ConfigurationError.duplicateID(kind: "tab", id: "same")) {
        try config.validated()
    }
}

@Test func shellCommandFindsToolsInitializedInZshrc() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let bin = directory.appending(path: "bin")
    try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    try "export PATH=\"$ZDOTDIR/bin:$PATH\"\n".write(
        to: directory.appending(path: ".zshrc"), atomically: true, encoding: .utf8
    )
    let tool = bin.appending(path: "runner-test-tool")
    try "#!/bin/sh\nprintf tool-found\n".write(to: tool, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tool.path)

    let spec = RunnerScript(id: "tool", title: "Tool", command: "runner-test-tool").launchSpec()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: spec.executable)
    process.arguments = spec.arguments
    process.environment = ["HOME": directory.path, "ZDOTDIR": directory.path, "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    #expect(process.terminationStatus == 0)
    #expect(String(decoding: data, as: UTF8.self) == "tool-found")
}

@Test func customNonZshShellKeepsLoginCommandMode() {
    let spec = RunnerScript(id: "bash", title: "Bash", command: "echo hello", shell: "/bin/bash").launchSpec()
    #expect(spec.executable == "/bin/bash")
    #expect(spec.arguments == ["-lc", "echo hello"])
}

@Test func buttonAlignmentDefaultsLeftAndSurvivesPathResolution() throws {
    let yaml = """
    tabs:
      - id: dev
        title: Dev
        buttons:
          - id: lab
            title: Lab
            scripts: [{id: lab, title: Lab, command: echo lab}]
          - id: seeds
            title: Seeds
            align: right
            source: {type: json_file, path: seeds.json}
    """
    let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try yaml.write(to: url, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(at: url) }
    let config = try ConfigurationLoader().load(from: url)
    #expect(config.tabs[0].buttons[0].align == .left)
    #expect(config.tabs[0].buttons[1].align == .right)
}

@Test func renamedConfigurationPathPreservesExistingInstallations() throws {
    let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: home) }
    let current = home.appending(path: ".config/mode-runner/config.yaml")
    let legacy = home.appending(path: ".config/script-mode-runner/config.yaml")
    #expect(ConfigurationLoader.defaultURL(environment: [:], homeDirectory: home) == current)
    try FileManager.default.createDirectory(at: legacy.deletingLastPathComponent(), withIntermediateDirectories: true)
    try "tabs: []".write(to: legacy, atomically: true, encoding: .utf8)
    #expect(ConfigurationLoader.defaultURL(environment: [:], homeDirectory: home) == legacy)
    try FileManager.default.createDirectory(at: current.deletingLastPathComponent(), withIntermediateDirectories: true)
    try "tabs: []".write(to: current, atomically: true, encoding: .utf8)
    #expect(ConfigurationLoader.defaultURL(environment: [:], homeDirectory: home) == current)
    let custom = home.appending(path: "custom.yaml")
    #expect(ConfigurationLoader.defaultURL(environment: ["MODE_RUNNER_CONFIG": custom.path,
                                                        "SCRIPT_MODE_RUNNER_CONFIG": legacy.path], homeDirectory: home) == custom)
    #expect(ConfigurationLoader.defaultURL(environment: ["SCRIPT_MODE_RUNNER_CONFIG": legacy.path], homeDirectory: home) == legacy)
    #expect(ConfigurationLoader.defaultURL(environment: ["MODE_RUNNER_CONFIG": "",
                                                        "SCRIPT_MODE_RUNNER_CONFIG": legacy.path], homeDirectory: home) == legacy)
}

@Test func overwriteConfigurationReplacesBaseAndIsCheckedOnEveryLoad() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let base = directory.appending(path: "custom.config.yml")
    let replacement = directory.appending(path: "custom.config.overwrite.yml")
    let baseText = "tabs: [{id: base, title: Base, buttons: []}]"
    try baseText.write(to: base, atomically: true, encoding: .utf8)
    let loader = ConfigurationLoader()
    #expect(try loader.load(from: base).tabs.first?.id == "base")
    try """
    tabs:
      - id: replacement
        title: Replacement
        buttons:
          - id: echo
            title: Echo
            scripts: [{id: echo, title: Echo, command: echo hello, cwd: .}]
    """.write(to: replacement, atomically: true, encoding: .utf8)
    #expect(ConfigurationLoader.effectiveURL(for: base) == replacement)
    #expect(ConfigurationLoader.effectiveURL(for: replacement) == replacement)
    let loaded = try loader.load(from: base)
    #expect(loaded.tabs.map(\.id) == ["replacement"])
    #expect(loaded.tabs[0].buttons[0].scripts[0].cwd == directory.path)
    #expect(try String(contentsOf: base, encoding: .utf8) == baseText)
    try "tabs: [invalid".write(to: replacement, atomically: true, encoding: .utf8)
    #expect(throws: (any Error).self) { try loader.load(from: base) }
    try FileManager.default.removeItem(at: base)
    try "tabs: []".write(to: replacement, atomically: true, encoding: .utf8)
    #expect(try loader.load(from: base).tabs.isEmpty)
    try baseText.write(to: base, atomically: true, encoding: .utf8)
    try FileManager.default.removeItem(at: replacement)
    #expect(try loader.load(from: base).tabs.first?.id == "base")
}

@Test func defaultConfigurationRecognizesOverwriteOnlyInstallations() throws {
    let home = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: home) }
    let current = home.appending(path: ".config/mode-runner/config.yaml")
    let legacy = home.appending(path: ".config/script-mode-runner/config.yaml")
    for base in [legacy, current] {
        try FileManager.default.createDirectory(at: base.deletingLastPathComponent(), withIntermediateDirectories: true)
        let replacement = base.deletingPathExtension().appendingPathExtension("overwrite.yaml")
        try "tabs: []".write(to: replacement, atomically: true, encoding: .utf8)
        #expect(ConfigurationLoader.defaultURL(environment: [:], homeDirectory: home) == base)
    }
    #expect(ConfigurationLoader.defaultURL(environment: ["MODE_RUNNER_CONFIG": legacy.path], homeDirectory: home) == legacy)
    #expect(try ConfigurationLoader().load(from: legacy).tabs.isEmpty)
}
