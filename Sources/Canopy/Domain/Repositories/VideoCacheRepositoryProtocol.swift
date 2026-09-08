import Foundation

protocol VideoCacheRepositoryProtocol: Sendable {
    func cachedFile(for video: PixabayVideo, quality: PixabayVideo.Quality) -> URL?
    func fetch(_ video: PixabayVideo, quality: PixabayVideo.Quality) async throws -> URL
    func delete(_ video: PixabayVideo)
}
