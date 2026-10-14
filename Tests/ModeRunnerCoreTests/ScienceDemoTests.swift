import Foundation
import Testing
@testable import ModeRunnerCore

@Test func scienceDemoConfigurationLoadsModesAndExecutableSeedMenus() async throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let configuration = try ConfigurationLoader().load(from: root.appending(path: "Examples/science-demos.yaml"))
    #expect(configuration.tabs.count == 3)
    for tab in configuration.tabs {
        #expect(tab.buttons.map(\.id) == ["mock", "live", "seeds"])
        #expect(tab.buttons[0].scripts.map(\.command) == ["yarn dev:mock", "yarn mock"])
        #expect(tab.buttons[1].scripts.map(\.command) == ["yarn dev:live"])
        let menu = tab.buttons[2]
        #expect(menu.runner == ["yarn", "seed"])
        let items = try await MenuLoader().load(menu, relativeTo: root.appending(path: "Examples"))
        #expect(items.count == 3)
        #expect(items.allSatisfy { !$0.arguments.isEmpty })
    }
}
