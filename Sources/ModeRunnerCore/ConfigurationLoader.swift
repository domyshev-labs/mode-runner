import Foundation
import Yams

public struct ConfigurationLoader: Sendable {
    public static var defaultDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser.appending(path: ".mode-runner")
    }

    public static var defaultURL: URL {
        defaultURL(environment: ProcessInfo.processInfo.environment,
                   homeDirectory: FileManager.default.homeDirectoryForCurrentUser)
    }

    public static func defaultURL(environment: [String: String], homeDirectory: URL) -> URL {
        if let configured = environment["MODE_RUNNER_CONFIG"], !configured.isEmpty {
            return URL(fileURLWithPath: (configured as NSString).expandingTildeInPath)
        }
        return homeDirectory.appending(path: ".mode-runner/config.yaml")
    }

    public static func configurations(in directory: URL, fileManager: FileManager = .default) -> [URL] {
        let files = (try? fileManager.contentsOfDirectory(at: directory,
                      includingPropertiesForKeys: [.isRegularFileKey])) ?? []
        return files.filter { url in
            let name = url.lastPathComponent
            let matches = name == "config.yaml" ||
                (name.hasPrefix("config.") && name.hasSuffix(".yaml") && name.count > "config..yaml".count)
            return matches && (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }.map { directory.appending(path: $0.lastPathComponent) }.sorted { left, right in
            if left.lastPathComponent == "config.yaml" { return right.lastPathComponent != "config.yaml" }
            if right.lastPathComponent == "config.yaml" { return false }
            return left.lastPathComponent < right.lastPathComponent
        }
    }

    public init() {}

    public func load(from url: URL = Self.defaultURL) throws -> RunnerConfiguration {
        let data = try Data(contentsOf: url)
        guard let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return try YAMLDecoder()
            .decode(RunnerConfiguration.self, from: text)
            .resolvingRelativePaths(relativeTo: url.deletingLastPathComponent())
            .validated()
    }
}
