import AppKit
import Foundation

@MainActor
final class WallpaperRepositoryImpl: WallpaperRepositoryProtocol {
    private let windowManager: WallpaperWindowManager
    private let defaults: UserDefaults

    private enum DefaultsKey {
        static let wallpaperByDisplay = "wallpaperByDisplay"
        static let quality = "wallpaperQuality"
        static let isMuted = "isMuted"
        static let pauseOnBattery = "pauseOnBattery"
        static let collection = "collection"
    }

    var onScreensChanged: (() -> Void)? {
        get { windowManager.onScreensChanged }
        set { windowManager.onScreensChanged = newValue }
    }

    init(
        windowManager: WallpaperWindowManager = WallpaperWindowManager(),
        defaults: UserDefaults = .standard
    ) {
        self.windowManager = windowManager
        self.defaults = defaults
    }

    func setWallpaper(fileURL: URL, for displayID: CGDirectDisplayID) {
        windowManager.setWallpaper(fileURL: fileURL, for: displayID)
    }

    func play() {
        windowManager.play()
    }

    func pause() {
        windowManager.pause()
    }

    func setMuted(_ muted: Bool) {
        windowManager.setMuted(muted)
    }

    func loadSavedState() -> (
        wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo],
        collection: [PixabayVideo],
        quality: PixabayVideo.Quality,
        isMuted: Bool,
        pauseOnBattery: Bool
    ) {
        let isMuted = defaults.bool(forKey: DefaultsKey.isMuted)
        let quality = PixabayVideo.Quality(rawValue: defaults.string(forKey: DefaultsKey.quality) ?? "") ?? .medium
        let pauseOnBattery = defaults.bool(forKey: DefaultsKey.pauseOnBattery)

        var collection: [PixabayVideo] = []
        if let data = defaults.data(forKey: DefaultsKey.collection),
           let saved = try? JSONDecoder().decode([PixabayVideo].self, from: data) {
            collection = saved
        }

        var wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo] = [:]
        if let data = defaults.data(forKey: DefaultsKey.wallpaperByDisplay),
           let stringKeyed = try? JSONDecoder().decode([String: PixabayVideo].self, from: data) {
            wallpaperByDisplay = Dictionary(uniqueKeysWithValues: stringKeyed.compactMap { key, value in
                CGDirectDisplayID(key).map { ($0, value) }
            })
        }

        windowManager.setMuted(isMuted)
        return (wallpaperByDisplay, collection, quality, isMuted, pauseOnBattery)
    }

    func saveWallpaperByDisplay(_ wallpapers: [CGDirectDisplayID: PixabayVideo]) {
        let stringKeyed = Dictionary(uniqueKeysWithValues: wallpapers.map { (String($0.key), $0.value) })
        guard let data = try? JSONEncoder().encode(stringKeyed) else { return }
        defaults.set(data, forKey: DefaultsKey.wallpaperByDisplay)
    }

    func saveCollection(_ collection: [PixabayVideo]) {
        guard let data = try? JSONEncoder().encode(collection) else { return }
        defaults.set(data, forKey: DefaultsKey.collection)
    }

    func saveQuality(_ quality: PixabayVideo.Quality) {
        defaults.set(quality.rawValue, forKey: DefaultsKey.quality)
    }

    func saveMuted(_ muted: Bool) {
        defaults.set(muted, forKey: DefaultsKey.isMuted)
    }

    func savePauseOnBattery(_ pauseOnBattery: Bool) {
        defaults.set(pauseOnBattery, forKey: DefaultsKey.pauseOnBattery)
    }
}
