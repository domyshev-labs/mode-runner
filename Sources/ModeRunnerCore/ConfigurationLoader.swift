import Foundation
import Yams

public struct ConfigurationLoader: Sendable {
    public static var defaultURL: URL {
        defaultURL(environment: ProcessInfo.processInfo.environment,
                   homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    }

    public static func defaultURL(environment: [String: String], homeDirectory: URL,
                                  fileManager: FileManager = .default) -> URL {
        for key in ["MODE_RUNNER_CONFIG", "SCRIPT_MODE_RUNNER_CONFIG"] {
            if let configured = environment[key], !configured.isEmpty {
                return URL(fileURLWithPath: (configured as NSString).expandingTildeInPath)
            }
        }
        let current = homeDirectory.appending(path: ".config/mode-runner/config.yaml")
        let legacy = homeDirectory.appending(path: ".config/script-mode-runner/config.yaml")
        // Keep existing relative paths anchored to the original configuration directory.
        if !fileManager.fileExists(atPath: effectiveURL(for: current, fileManager: fileManager).path),
           fileManager.fileExists(atPath: effectiveURL(for: legacy, fileManager: fileManager).path) {
            return legacy
        }
        return current
    }

    public static func overwriteURL(for url: URL) -> URL {
        let stem = url.deletingPathExtension()
        if stem.lastPathComponent.hasSuffix(".overwrite") { return url }
        var replacement = stem.appendingPathExtension("overwrite")
        if !url.pathExtension.isEmpty { replacement = replacement.appendingPathExtension(url.pathExtension) }
        return replacement
    }

    public static func availableOverwriteURL(for url: URL, fileManager: FileManager = .default) -> URL? {
        let replacement = overwriteURL(for: url)
        return fileManager.fileExists(atPath: replacement.path) ? replacement : nil
    }

    /// Select a complete local replacement on every load, without changing the base file.
    public static func effectiveURL(for url: URL, applyOverwrite: Bool = true,
                                    fileManager: FileManager = .default) -> URL {
        applyOverwrite ? (availableOverwriteURL(for: url, fileManager: fileManager) ?? url) : url
    }

    public init() {}

    public func load(from url: URL = Self.defaultURL, applyOverwrite: Bool = true) throws -> RunnerConfiguration {
        let selectedURL = Self.effectiveURL(for: url, applyOverwrite: applyOverwrite)
        let data = try Data(contentsOf: selectedURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return try YAMLDecoder()
            .decode(RunnerConfiguration.self, from: text)
            .resolvingRelativePaths(relativeTo: selectedURL.deletingLastPathComponent())
            .validated()
    }
}
