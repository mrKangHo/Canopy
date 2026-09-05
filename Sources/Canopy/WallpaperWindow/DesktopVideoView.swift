import AppKit
import AVFoundation

/// An NSView whose backing layer is an AVPlayerLayer, filling its bounds with
/// `.resizeAspectFill` so the video covers the whole screen like a wallpaper.
///
/// Uses `makeBackingLayer()` (layer-*backed* mode) rather than assigning
/// `self.layer = playerLayer` directly (layer-*hosting* mode). Layer-hosting
/// opts the view out of AppKit's automatic `contentsScale` management, so on
/// Retina displays the layer silently rendered at 1x and got upscaled —
/// every video looked soft/blurry no matter how high its source resolution
/// was. Layer-backed mode keeps AppKit syncing `contentsScale` to the
/// screen's actual backing scale factor, including when the window moves
/// between displays with different scale factors.
final class DesktopVideoView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        playerLayer.videoGravity = .resizeAspectFill
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        playerLayer
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
