import AppKit

/// Pure AppKit orchestration layer: "play this local file on display X" /
/// pause / mute. Knows nothing about Pixabay, local-file imports, or
/// business state — WallpaperManager is the only thing that talks to this,
/// and it's the one that remembers which file belongs on which display.
final class WallpaperWindowManager {
    private var controllers: [CGDirectDisplayID: WallpaperWindowController] = [:]
    private var muted = false

    /// Fired after controllers are rebuilt for a screen-configuration change
    /// (display connected/disconnected/rearranged) — WallpaperManager uses
    /// this to re-push whatever it remembers was assigned to each display.
    var onScreensChanged: (() -> Void)?

    init() {
        rebuildControllers()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged() {
        rebuildControllers()
        onScreensChanged?()
    }

    /// One window per connected display, keyed by its stable CGDirectDisplayID
    /// (unlike ObjectIdentifier(NSScreen), which changes every time AppKit
    /// recreates NSScreen objects on a configuration change).
    private func rebuildControllers() {
        let liveScreens: [(id: CGDirectDisplayID, screen: NSScreen)] = NSScreen.screens.compactMap { screen in
            guard let id = screen.displayID else { return nil }
            return (id, screen)
        }
        let liveIDs = Set(liveScreens.map(\.id))

        for (id, controller) in controllers where !liveIDs.contains(id) {
            controller.close()
            controllers[id] = nil
        }

        for (id, screen) in liveScreens {
            if let existing = controllers[id] {
                existing.updateFrame(for: screen)
            } else {
                let controller = WallpaperWindowController(screen: screen)
                controller.setMuted(muted)
                controllers[id] = controller
            }
        }
    }

    func setWallpaper(fileURL: URL, for displayID: CGDirectDisplayID) {
        guard let controller = controllers[displayID] else { return }
        controller.load(fileURL: fileURL)
        controller.setMuted(muted)
    }

    func play() {
        controllers.values.forEach { $0.play() }
    }

    func pause() {
        controllers.values.forEach { $0.pause() }
    }

    func setMuted(_ muted: Bool) {
        self.muted = muted
        controllers.values.forEach { $0.setMuted(muted) }
    }
}
