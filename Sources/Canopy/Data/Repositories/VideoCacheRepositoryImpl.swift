import Foundation

final class VideoCacheRepositoryImpl: VideoCacheRepositoryProtocol {
    private let manager: VideoCacheManager

    init(manager: VideoCacheManager = .shared) {
        self.manager = manager
    }

    func cachedFile(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL? {
        manager.cachedFile(for: video, quality: quality)
    }

    func fetch(_ video: PixabayVideo, quality: PixabayVideo.Quality) async throws -> URL {
        try await manager.fetch(video, quality: quality)
    }

    func delete(_ video: PixabayVideo) {
        manager.delete(video)
    }
}
