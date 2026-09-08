import AppKit

/// Owns the status item and the single WallpaperManager instance. No
/// Info.plist LSUIElement needed either way (see also project.yml) — the
/// accessory activation policy (no Dock icon, no app menu bar) is set here
/// programmatically. Clicking the status item shows a menu (Open /
/// Play-Pause / Quit) rather than a menu-bar popover.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let manager = AppDIContainer.shared.makeWallpaperManager()
    private let statusMenu = NSMenu()
    private var playPauseItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let statusImage: NSImage? = {
                if let image = NSImage(named: "StatusIcon") {
                    return image
                }
                // Fallback for development / direct command-line runs
                let localPath = "Resources/Assets.xcassets/StatusIcon.imageset/status_icon_18x18@2x.png"
                if FileManager.default.fileExists(atPath: localPath) {
                    return NSImage(contentsOfFile: localPath)
                }
                return nil
            }()

            if let image = statusImage {
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            } else {
                button.image = NSImage(
                    systemSymbolName: "sparkles.tv",
                    accessibilityDescription: "Canopy"
                )
            }
        }

        buildStatusMenu()
        statusItem.menu = statusMenu

        MainWindowController.shared.attach(manager: manager)
        MainWindowController.shared.show()
    }

    /// Setting `statusItem.menu` makes AppKit show this menu on every click
    /// of the status item automatically — no action/target wiring on the
    /// button itself is needed.
    private func buildStatusMenu() {
        statusMenu.delegate = self

        let openItem = NSMenuItem(title: String(localized: "Open"), action: #selector(openWindow), keyEquivalent: "")
        openItem.target = self
        statusMenu.addItem(openItem)

        playPauseItem = NSMenuItem(title: String(localized: "Pause"), action: #selector(togglePlayPause), keyEquivalent: "")
        playPauseItem.target = self
        statusMenu.addItem(playPauseItem)

        statusMenu.addItem(.separator())

        let quitTitle = String(localized: "Quit Canopy")
        let quitItem = NSMenuItem(title: quitTitle, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        statusMenu.addItem(quitItem)
    }

    @objc private func openWindow() {
        MainWindowController.shared.show()
    }

    @objc private func togglePlayPause() {
        manager.togglePlayPause()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        playPauseItem.title = manager.isPlaying ? String(localized: "Pause") : String(localized: "Play")
    }
}
