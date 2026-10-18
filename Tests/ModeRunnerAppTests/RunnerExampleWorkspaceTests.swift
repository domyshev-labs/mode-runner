import Foundation
import ModeRunnerCore
import Testing
@testable import ModeRunnerApp

@Test func downloadedAppInstallsUsableExamplesOnlyOnce() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: directory) }
    #expect(try RunnerExampleWorkspace.install(from: root, to: directory))
    let welcome = directory.appending(path: "config.welcome.yaml")
    let configuration = try ConfigurationLoader().load(from: welcome)
    #expect(configuration.tabs.count == 3)
    for tab in configuration.tabs {
        #expect(tab.buttons[0].scripts.count == 2)
        for script in tab.buttons[0].scripts {
            #expect(script.command?.hasPrefix("node server.mjs") == true)
            #expect(FileManager.default.fileExists(atPath: try #require(script.cwd) + "/server.mjs"))
        }
    }
    let science = try ConfigurationLoader().load(from: directory.appending(path: "config.example.yaml"))
    #expect(science.tabs.count == 3)
    #expect(science.tabs[0].buttons[0].scripts[0].cwd == directory.appending(path: "DemoApplications/cosmic-archive").path)
    try FileManager.default.removeItem(at: welcome)
    #expect(try !RunnerExampleWorkspace.install(from: root, to: directory))
    #expect(!FileManager.default.fileExists(atPath: welcome.path))
}

@Test func downloadedAppPreservesExistingWorkspacesAndUnrelatedFiles() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let configuration = directory.appending(path: "config.yaml")
    try "tabs: []".write(to: configuration, atomically: true, encoding: .utf8)
    #expect(try !RunnerExampleWorkspace.install(from: root, to: directory))
    #expect(try String(contentsOf: configuration, encoding: .utf8) == "tabs: []")
    try FileManager.default.removeItem(at: configuration)
    let existing = directory.appending(path: "DemoApplications")
    try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
    let marker = existing.appending(path: "user-file")
    try "preserve".write(to: marker, atomically: true, encoding: .utf8)
    #expect(throws: (any Error).self) { try RunnerExampleWorkspace.install(from: root, to: directory) }
    #expect(try String(contentsOf: marker, encoding: .utf8) == "preserve")
    #expect(!FileManager.default.fileExists(atPath: directory.appending(path: "TestApplications").path))
    #expect(!FileManager.default.fileExists(atPath: directory.appending(path: ".example-initialized").path))
}
