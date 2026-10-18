import Foundation
import ModeRunnerCore

/// Installs optional starter sources on first launch of a downloaded application.
/// Files remain outside the signed bundle, and existing workspaces are never replaced.
struct RunnerExampleWorkspace {
    @discardableResult
    static func install(from source: URL, to directory: URL,
                        fileManager: FileManager = .default) throws -> Bool {
        let marker = directory.appending(path: ".example-initialized")
        guard !fileManager.fileExists(atPath: marker.path),
              ConfigurationLoader.configurations(in: directory).isEmpty else { return false }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let staging = directory.appending(path: ".example-\(UUID().uuidString)")
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }
        for name in ["TestApplications", "DemoApplications"] {
            try fileManager.copyItem(at: source.appending(path: name), to: staging.appending(path: name))
        }
        try fileManager.copyItem(at: source.appending(path: "Examples/config.welcome.yaml"),
                                 to: staging.appending(path: "config.welcome.yaml"))
        let science = try String(contentsOf: source.appending(path: "Examples/config.example.yaml"), encoding: .utf8)
            .replacingOccurrences(of: "../DemoApplications/", with: "./DemoApplications/")
        try science.write(to: staging.appending(path: "config.example.yaml"), atomically: true, encoding: .utf8)
        let names = ["TestApplications", "DemoApplications", "config.welcome.yaml", "config.example.yaml"]
        var installed: [URL] = []
        do {
            for name in names {
                let destination = directory.appending(path: name)
                try fileManager.moveItem(at: staging.appending(path: name), to: destination)
                installed.append(destination)
            }
            try Data().write(to: marker, options: .atomic)
        } catch {
            // Roll back only files created by this installation attempt.
            for url in installed.reversed() { try? fileManager.removeItem(at: url) }
            throw error
        }
        return true
    }
}
