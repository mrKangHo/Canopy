import AppKit
import Foundation

@MainActor
protocol WallpaperRepositoryProtocol: AnyObject {
    var onScreensChanged: (() -> Void)? { get set }
    func setWallpaper(fileURL: URL, for displayID: CGDirectDisplayID)
    func play()
    func pause()
    func setMuted(_ muted: Bool)

    func loadSavedState() -> (
        wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo],
        collection: [PixabayVideo],
        quality: PixabayVideo.Quality,
        isMuted: Bool,
        pauseOnBattery: Bool
    )
    func saveWallpaperByDisplay(_ wallpapers: [CGDirectDisplayID: PixabayVideo])
    func saveCollection(_ collection: [PixabayVideo])
    func saveQuality(_ quality: PixabayVideo.Quality)
    func saveMuted(_ muted: Bool)
    func savePauseOnBattery(_ pauseOnBattery: Bool)
}
