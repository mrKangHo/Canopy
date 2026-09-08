import AppKit
import Foundation

@MainActor
protocol ManageWallpaperUseCaseProtocol: AnyObject {
    var onScreensChanged: (() -> Void)? { get set }
    func setWallpaper(fileURL: URL, for displayID: CGDirectDisplayID)
    func play()
    func pause()
    func setMuted(_ muted: Bool)
    func getCachedFile(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL?
    func fetchVideoFile(_ video: PixabayVideo, quality: PixabayVideo.Quality) async throws -> URL
    func loadSavedState() -> (
        wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo],
        collection: [PixabayVideo],
        quality: PixabayVideo.Quality,
        isMuted: Bool,
        pauseOnBattery: Bool
    )
    func saveWallpaperByDisplay(_ wallpapers: [CGDirectDisplayID: PixabayVideo])
    func saveQuality(_ quality: PixabayVideo.Quality)
    func saveMuted(_ muted: Bool)
    func savePauseOnBattery(_ pauseOnBattery: Bool)
}

@MainActor
final class ManageWallpaperUseCase: ManageWallpaperUseCaseProtocol {
    private let wallpaperRepository: WallpaperRepositoryProtocol
    private let videoCacheRepository: VideoCacheRepositoryProtocol

    var onScreensChanged: (() -> Void)? {
        get { wallpaperRepository.onScreensChanged }
        set { wallpaperRepository.onScreensChanged = newValue }
    }

    init(
        wallpaperRepository: WallpaperRepositoryProtocol,
        videoCacheRepository: VideoCacheRepositoryProtocol
    ) {
        self.wallpaperRepository = wallpaperRepository
        self.videoCacheRepository = videoCacheRepository
    }

    func setWallpaper(fileURL: URL, for displayID: CGDirectDisplayID) {
        wallpaperRepository.setWallpaper(fileURL: fileURL, for: displayID)
    }

    func play() {
        wallpaperRepository.play()
    }

    func pause() {
        wallpaperRepository.pause()
    }

    func setMuted(_ muted: Bool) {
        wallpaperRepository.setMuted(muted)
    }

    func getCachedFile(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL? {
        videoCacheRepository.cachedFile(for: video, quality: quality)
    }

    func fetchVideoFile(_ video: PixabayVideo, quality: PixabayVideo.Quality) async throws -> URL {
        try await videoCacheRepository.fetch(video, quality: quality)
    }

    func loadSavedState() -> (
        wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo],
        collection: [PixabayVideo],
        quality: PixabayVideo.Quality,
        isMuted: Bool,
        pauseOnBattery: Bool
    ) {
        wallpaperRepository.loadSavedState()
    }

    func saveWallpaperByDisplay(_ wallpapers: [CGDirectDisplayID: PixabayVideo]) {
        wallpaperRepository.saveWallpaperByDisplay(wallpapers)
    }

    func saveQuality(_ quality: PixabayVideo.Quality) {
        wallpaperRepository.saveQuality(quality)
    }

    func saveMuted(_ muted: Bool) {
        wallpaperRepository.saveMuted(muted)
    }

    func savePauseOnBattery(_ pauseOnBattery: Bool) {
        wallpaperRepository.savePauseOnBattery(pauseOnBattery)
    }
}
