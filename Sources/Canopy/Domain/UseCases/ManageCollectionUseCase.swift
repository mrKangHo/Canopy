import Foundation

@MainActor
protocol ManageCollectionUseCaseProtocol: AnyObject {
    func deleteCachedVideo(_ video: PixabayVideo)
    func saveCollection(_ collection: [PixabayVideo])
}

@MainActor
final class ManageCollectionUseCase: ManageCollectionUseCaseProtocol {
    private let wallpaperRepository: WallpaperRepositoryProtocol
    private let videoCacheRepository: VideoCacheRepositoryProtocol

    init(
        wallpaperRepository: WallpaperRepositoryProtocol,
        videoCacheRepository: VideoCacheRepositoryProtocol
    ) {
        self.wallpaperRepository = wallpaperRepository
        self.videoCacheRepository = videoCacheRepository
    }

    func deleteCachedVideo(_ video: PixabayVideo) {
        videoCacheRepository.delete(video)
    }

    func saveCollection(_ collection: [PixabayVideo]) {
        wallpaperRepository.saveCollection(collection)
    }
}
