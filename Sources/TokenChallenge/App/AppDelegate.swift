import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let store = TokenDataStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuBarIcon()

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
        }

        // Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverContentView(store: store)
        )

        // Update icon only when data changes
        store.onDataChanged = { [weak self] in
            self?.updateMenuBarIcon()
        }

        // Start data polling
        store.startPolling()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stopPolling()
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func updateMenuBarIcon() {
        let image = MenuBarIcon.createImage(
            progress: store.progress,
            goalMet: store.goalMet,
            percent: store.progressPercent
        )
        statusItem.button?.image = image

        let formatted = store.l10n.formatCompact(store.todayTokens)
        statusItem.button?.title = " \(formatted)"
        statusItem.button?.imagePosition = .imageLeading
    }
}
