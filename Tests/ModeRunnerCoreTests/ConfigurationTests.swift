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


@Test func configurationFilesMatchExactNamesAndSortBaseFirst() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    for name in ["config.zebra.yaml", "config.example.yaml", "config.yaml", "config.overwrite.yaml",
                 "config..yaml", "config.yml", "other.yaml", "config.foo.yaml.bak"] {
        try "tabs: []".write(to: directory.appending(path: name), atomically: true, encoding: .utf8)
    }
    try FileManager.default.createDirectory(at: directory.appending(path: "config.folder.yaml"), withIntermediateDirectories: true)
    #expect(ConfigurationLoader.configurations(in: directory).map(\.lastPathComponent) ==
            ["config.yaml", "config.example.yaml", "config.overwrite.yaml", "config.zebra.yaml"])
    let base = directory.appending(path: "config.yaml")
    try "tabs: [{id: base, title: Base, buttons: []}]".write(to: base, atomically: true, encoding: .utf8)
    #expect(try ConfigurationLoader().load(from: base).tabs.first?.id == "base")
    #expect(try ConfigurationLoader().load(from: directory.appending(path: "config.overwrite.yaml")).tabs.isEmpty)
}

@Test func configurationDefaultUsesHomeFolderWithoutLegacyFallback() {
    let home = URL(fileURLWithPath: "/tmp/mode-runner-home")
    #expect(ConfigurationLoader.defaultURL(environment: [:], homeDirectory: home).path == "/tmp/mode-runner-home/.mode-runner/config.yaml")
    #expect(ConfigurationLoader.defaultURL(environment: ["SCRIPT_MODE_RUNNER_CONFIG": "/tmp/old.yaml"], homeDirectory: home).path == "/tmp/mode-runner-home/.mode-runner/config.yaml")
    #expect(ConfigurationLoader.defaultURL(environment: ["MODE_RUNNER_CONFIG": "/tmp/custom.yaml"], homeDirectory: home).path == "/tmp/custom.yaml")
}
