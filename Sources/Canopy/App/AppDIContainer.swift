import Foundation

@MainActor
final class AppDIContainer: ObservableObject {
    static let shared = AppDIContainer()

    let pixabayRepository: PixabayRepositoryProtocol
    let videoCacheRepository: VideoCacheRepositoryProtocol
    let wallpaperRepository: WallpaperRepositoryProtocol

    let fetchVideosUseCase: FetchVideosUseCaseProtocol
    let manageWallpaperUseCase: ManageWallpaperUseCaseProtocol
    let manageCollectionUseCase: ManageCollectionUseCaseProtocol

    private(set) lazy var wallpaperManager: WallpaperManager = {
        WallpaperManager(
            fetchVideosUseCase: fetchVideosUseCase,
            manageWallpaperUseCase: manageWallpaperUseCase,
            manageCollectionUseCase: manageCollectionUseCase
        )
    }()

    private init() {
        let pixabayRepo = PixabayRepositoryImpl()
        let cacheRepo = VideoCacheRepositoryImpl()
        let wallpaperRepo = WallpaperRepositoryImpl()

        self.pixabayRepository = pixabayRepo
        self.videoCacheRepository = cacheRepo
        self.wallpaperRepository = wallpaperRepo

        self.fetchVideosUseCase = FetchVideosUseCase(repository: pixabayRepo)
        self.manageWallpaperUseCase = ManageWallpaperUseCase(
            wallpaperRepository: wallpaperRepo,
            videoCacheRepository: cacheRepo
        )
        self.manageCollectionUseCase = ManageCollectionUseCase(
            wallpaperRepository: wallpaperRepo,
            videoCacheRepository: cacheRepo
        )
    }

    func makeWallpaperManager() -> WallpaperManager {
        wallpaperManager
    }
}
