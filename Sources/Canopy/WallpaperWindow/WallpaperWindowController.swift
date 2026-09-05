import AppKit
import AVFoundation
import CoreGraphics

/// Owns a single borderless NSWindow pinned to the desktop-icon layer on one
/// screen, with a looping AVQueuePlayer rendering into it. This is the
/// highest-risk piece of the app (see plan §1) — validate this file alone,
/// with a local test video, before building anything on top of it.
///
/// Window level: one below `.desktopIconWindow`, i.e. directly on top of the
/// real Finder desktop picture but underneath desktop icons — the exact slot
/// a "video wallpaper" needs to occupy. This deliberately never touches
/// `NSWorkspace.setDesktopImageURL` or any real desktop-picture API, which is
/// why it keeps working across macOS versions that tighten that API.
final class WallpaperWindowController {
    private let window: NSWindow
    private let videoView = DesktopVideoView(frame: .zero)

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    private(set) var isMuted: Bool = false

    init(screen: NSScreen) {
        window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        let desktopIconLevel = CGWindowLevelForKey(.desktopIconWindow)
        window.level = NSWindow.Level(rawValue: Int(desktopIconLevel) - 1)
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.setFrame(screen.frame, display: true)

        videoView.frame = window.contentView?.bounds ?? screen.frame
        videoView.autoresizingMask = [.width, .height]
        window.contentView = videoView

        window.orderFront(nil)
    }

    /// Repositions the window to match its screen's current frame — call after
    /// display arrangement/resolution changes (see WallpaperWindowManager).
    func updateFrame(for screen: NSScreen) {
        window.setFrame(screen.frame, display: true)
    }

    func load(fileURL: URL) {
        let item = AVPlayerItem(url: fileURL)
        let queuePlayer = AVQueuePlayer()
        let newLooper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        queuePlayer.isMuted = isMuted
        videoView.playerLayer.player = queuePlayer
        queuePlayer.play()

        player = queuePlayer
        looper = newLooper
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        player?.isMuted = muted
    }

    func close() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player = nil
        window.orderOut(nil)
        window.close()
    }

    deinit {
        close()
    }
}
