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
        }.map { directory.appending(path: $0.lastPathComponent) }.map { url in
            (url: url, order: sortOrder(for: url))
        }.sorted { left, right in
            switch (left.order, right.order) {
            case let (.some(leftOrder), .some(rightOrder)) where leftOrder != rightOrder:
                return leftOrder < rightOrder
            case (.some, .none): return true
            case (.none, .some): return false
            default: break
            }
            if left.url.lastPathComponent == "config.yaml" { return right.url.lastPathComponent != "config.yaml" }
            if right.url.lastPathComponent == "config.yaml" { return false }
            return left.url.lastPathComponent < right.url.lastPathComponent
        }.map(\.url)
    }

    private static func sortOrder(for url: URL) -> Int? {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        // Invalid files remain selectable so their load error can be shown.
        return (try? YAMLDecoder().decode(ConfigurationSortMetadata.self, from: text))?.sortOrder
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


private struct ConfigurationSortMetadata: Decodable {
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey { case sortOrder = "sort_order" }
}
