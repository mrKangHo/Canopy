import AppKit
import SwiftUI

/// Owns the single main app window and toggles it from the status item —
/// a normal titled, resizable window instead of a MenuBarExtra popover.
/// Popovers auto-size to content and clip anything presented inside them
/// (e.g. a Settings sheet); a real window has room to breathe and is the
/// familiar shape for a "browse and pick" search UI.
@MainActor
final class MainWindowController: NSWindowController {
    static let shared = MainWindowController()

    private convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Canopy"
        // Traffic lights float directly over the hero image, no title bar
        // strip — the content view extends full-height under them.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 760, height: 520)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("MainWindow")
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(Theme.background)
        window.center()
        self.init(window: window)
    }

    func attach(manager: WallpaperManager) {
        window?.contentView = NSHostingView(rootView: MainContentView(manager: manager))
    }

    /// Show-or-hide, matching the "click the status item to open/close" model.
    func toggle() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
