import AppKit
import SwiftUI

struct ConfigurationSelector: NSViewRepresentable {
    let files: [URL]
    let selectedURL: URL
    let select: (URL) -> Void
    var menuVisibilityChanged: (Bool) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: true)
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = .systemFont(ofSize: 11, weight: .medium)
        button.setAccessibilityLabel("Configuration")
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.parent = self
        let menu = context.coordinator.makeMenu()
        let title = files.isEmpty ? "No configurations" : selectedURL.lastPathComponent
        let heading = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        heading.isHidden = true
        menu.insertItem(heading, at: 0)
        button.menu = menu
        button.toolTip = files.isEmpty ? "Add config.yaml or config.{name}.yaml in \(selectedURL.deletingLastPathComponent().path)" : selectedURL.path
        button.setAccessibilityValue(title)
        button.isEnabled = !files.isEmpty
    }

    @MainActor
    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: ConfigurationSelector?

        func makeMenu() -> NSMenu {
            let menu = NSMenu()
            menu.autoenablesItems = false
            menu.delegate = self
            guard let parent else { return menu }
            for url in parent.files {
                let item = NSMenuItem(title: url.lastPathComponent, action: #selector(selectItem(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = url
                item.toolTip = url.path
                item.state = url == parent.selectedURL ? .on : .off
                let row = ConfigurationMenuRow(url: url, selected: url == parent.selectedURL)
                row.select = { [weak self, weak menu] in
                    menu?.cancelTracking()
                    self?.parent?.select(url)
                }
                item.view = row
                menu.addItem(item)
            }
            return menu
        }

        func menuWillOpen(_ menu: NSMenu) { parent?.menuVisibilityChanged(true) }
        func menuDidClose(_ menu: NSMenu) { parent?.menuVisibilityChanged(false) }

        @objc func selectItem(_ sender: NSMenuItem) {
            if let url = sender.representedObject as? URL { parent?.select(url) }
        }


    }
}

@MainActor
final class ConfigurationMenuRow: NSView {
    let url: URL
    var select: (() -> Void)?

    init(url: URL, selected: Bool) {
        self.url = url
        super.init(frame: NSRect(x: 0, y: 0, width: 340, height: 32))
        toolTip = url.path
        let title = NSButton(title: (selected ? "✓  " : "    ") + url.lastPathComponent,
                             target: self, action: #selector(selectConfiguration))
        title.frame = NSRect(x: 8, y: 3, width: 280, height: 26)
        title.isBordered = false
        title.alignment = .left
        title.font = .menuFont(ofSize: 13)
        title.toolTip = url.path
        title.setAccessibilityLabel(url.lastPathComponent)
        addSubview(title)
        let copy = NSButton(image: NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "Copy configuration path")!,
                            target: self, action: #selector(copyPath))
        copy.frame = NSRect(x: 301, y: 3, width: 28, height: 26)
        copy.isBordered = false
        copy.toolTip = "Copy path: \(url.path)"
        copy.setAccessibilityLabel("Copy path for \(url.lastPathComponent)")
        addSubview(copy)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func selectConfiguration() { select?() }

    @objc func copyPath() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.path, forType: .string)
    }
}
