import Foundation

/// Downloads the selected video once to local disk and always plays from the
/// local file — this satisfies Pixabay's "no permanent hotlinking" API term
/// and means playback survives network hiccups and app relaunches.
final class VideoCacheManager {
    static let shared = VideoCacheManager()

    private let cacheDirectory: URL
    private let maxCacheBytes: Int64 = 800 * 1024 * 1024 // ~800MB LRU cap

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = base.appendingPathComponent("com.videowallpaper.app/Videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func fileName(for video: PixabayVideo, quality: PixabayVideo.Quality) -> String {
        "\(video.id)-\(quality.rawValue).mp4"
    }

    func localURL(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL {
        cacheDirectory.appendingPathComponent(fileName(for: video, quality: quality))
    }

    /// Returns the cached file's local URL if present, without downloading.
    func cachedFile(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL? {
        let url = localURL(for: video, quality: quality)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Downloads the rendition if not already cached, touches its access date, and returns the local file URL.
    func fetch(_ video: PixabayVideo, quality: PixabayVideo.Quality) async throws -> URL {
        let destination = localURL(for: video, quality: quality)

        if FileManager.default.fileExists(atPath: destination.path) {
            touch(destination)
            return destination
        }

        let rendition = video.rendition(for: quality)
        guard let remoteURL = URL(string: rendition.url) else {
            throw PixabayError.invalidResponse
        }

        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw PixabayError.invalidResponse
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try? FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)

        evictIfNeeded()
        return destination
    }

    /// Removes every cached quality variant for a video — used when the user
    /// removes it from their Collection.
    func delete(_ video: PixabayVideo) {
        for quality in PixabayVideo.Quality.allCases {
            try? FileManager.default.removeItem(at: localURL(for: video, quality: quality))
        }
    }

    private func touch(_ url: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
    }

    /// Simple LRU eviction by modification date, run after each download, capped by total size.
    private func evictIfNeeded() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
        ) else { return }

        var entries: [(url: URL, size: Int64, date: Date)] = files.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let size = values.fileSize,
                  let date = values.contentModificationDate else { return nil }
            return (url, Int64(size), date)
        }

        var totalSize = entries.reduce(0) { $0 + $1.size }
        guard totalSize > maxCacheBytes else { return }

        entries.sort { $0.date < $1.date } // oldest first
        for entry in entries {
            guard totalSize > maxCacheBytes else { break }
            try? FileManager.default.removeItem(at: entry.url)
            totalSize -= entry.size
        }
    }
}
