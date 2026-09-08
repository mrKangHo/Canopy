import AppKit
import Combine
import Foundation

/// Central coordinator — the single source of truth for what's assigned to
/// each display and the shared playback state. Ties search, caching/download,
/// and the desktop window layer together, and persists what's needed to
/// resume on relaunch.
@MainActor
final class WallpaperManager: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [PixabayVideo] = []
    @Published var isSearching = false
    @Published var isLoadingMoreSearch = false
    @Published var errorMessage: String?
    private var searchPage = 1
    private var searchTotalHits = 0
    var searchHasMore: Bool { searchResults.count < searchTotalHits }

    @Published var isPlaying = false
    @Published var isMuted: Bool
    @Published var quality: PixabayVideo.Quality

    /// Every connected display, and which scope the browsing UI is currently
    /// targeting — selecting a video applies to this scope (either one
    /// specific display, or every display via `.all`).
    @Published private(set) var displays: [DisplayInfo] = []
    @Published var selectedScope: DisplaySelection = .all
    @Published private(set) var wallpaperByDisplay: [CGDirectDisplayID: PixabayVideo] = [:]
    @Published private(set) var downloadingDisplayIDs: Set<CGDirectDisplayID> = []

    private func displayIDs(for scope: DisplaySelection) -> [CGDirectDisplayID] {
        switch scope {
        case .all: return displays.map(\.id)
        case .display(let id): return [id]
        }
    }

    /// A representative "what's showing" for the current scope — under
    /// `.all` this is just the first display's item (a preview, not a claim
    /// that every display matches; they might not if `.all` was picked after
    /// individual displays already had different selections).
    var currentItem: PixabayVideo? {
        switch selectedScope {
        case .all: return displays.first.flatMap { wallpaperByDisplay[$0.id] }
        case .display(let id): return wallpaperByDisplay[id]
        }
    }

    var isDownloadingCurrent: Bool {
        switch selectedScope {
        case .all: return !downloadingDisplayIDs.isEmpty
        case .display(let id): return downloadingDisplayIDs.contains(id)
        }
    }

    @Published var apiKey: String {
        didSet {
            APIKeyStore.save(apiKey)
            if !apiKey.isEmpty, oldValue.isEmpty {
                Task { await loadDefaultCategories() }
            }
        }
    }

    @Published private(set) var categorySections: [CategorySection] = []
    @Published private(set) var isLoadingCategories = false
    @Published private(set) var categoryErrorMessage: String?

    /// Pixabay videos the user has actually downloaded/played before, most
    /// recent first — shown under "My Collection".
    @Published private(set) var collection: [PixabayVideo] = []

    let powerMonitor = PowerStateMonitor()
    let launchAtLogin = LaunchAtLoginManager()

    private let fetchVideosUseCase: FetchVideosUseCaseProtocol
    private let manageWallpaperUseCase: ManageWallpaperUseCaseProtocol
    private let manageCollectionUseCase: ManageCollectionUseCaseProtocol
    private var cancellables: Set<AnyCancellable> = []
    private let perPage = 30

    init(
        fetchVideosUseCase: FetchVideosUseCaseProtocol? = nil,
        manageWallpaperUseCase: ManageWallpaperUseCaseProtocol? = nil,
        manageCollectionUseCase: ManageCollectionUseCaseProtocol? = nil
    ) {
        let fetchUseCase = fetchVideosUseCase ?? AppDIContainer.shared.fetchVideosUseCase
        let wallpaperUseCase = manageWallpaperUseCase ?? AppDIContainer.shared.manageWallpaperUseCase
        let collectionUseCase = manageCollectionUseCase ?? AppDIContainer.shared.manageCollectionUseCase

        self.fetchVideosUseCase = fetchUseCase
        self.manageWallpaperUseCase = wallpaperUseCase
        self.manageCollectionUseCase = collectionUseCase

        apiKey = APIKeyStore.load() ?? ""

        let state = wallpaperUseCase.loadSavedState()
        wallpaperByDisplay = state.wallpaperByDisplay
        collection = state.collection
        quality = state.quality
        isMuted = state.isMuted
        powerMonitor.pauseOnBattery = state.pauseOnBattery

        wallpaperUseCase.onScreensChanged = { [weak self] in self?.refreshDisplays() }
        refreshDisplays()

        powerMonitor.$shouldPause
            .removeDuplicates()
            .sink { [weak self] shouldPause in
                guard let self else { return }
                if shouldPause {
                    self.manageWallpaperUseCase.pause()
                } else if self.isPlaying {
                    self.manageWallpaperUseCase.play()
                }
            }
            .store(in: &cancellables)

        if !apiKey.isEmpty {
            Task { await loadDefaultCategories() }
        }
    }

    var pauseOnBattery: Bool {
        get { powerMonitor.pauseOnBattery }
        set {
            powerMonitor.pauseOnBattery = newValue
            manageWallpaperUseCase.savePauseOnBattery(newValue)
        }
    }

    // MARK: - Displays

    private func refreshDisplays() {
        let screens: [DisplayInfo] = NSScreen.screens.compactMap { screen in
            guard let id = screen.displayID else { return nil }
            return DisplayInfo(id: id, name: screen.localizedName)
        }
        displays = screens
        if case .display(let id) = selectedScope, !screens.contains(where: { $0.id == id }) {
            selectedScope = .all
        }

        // Re-apply whatever we remember for each (re)created window — covers
        // reconnecting a previously-known display.
        for display in screens {
            guard let video = wallpaperByDisplay[display.id],
                  let cached = manageWallpaperUseCase.getCachedFile(for: video, quality: quality) else { continue }
            manageWallpaperUseCase.setWallpaper(fileURL: cached, for: display.id)
        }
    }

    // MARK: - Category browsing

    /// Called from the view's `.onAppear` as a safety net (e.g. if the app
    /// launched with a key already saved but this somehow didn't fire yet).
    func loadDefaultCategoriesIfNeeded() {
        guard categorySections.isEmpty, !isLoadingCategories, !apiKey.isEmpty else { return }
        Task { await loadDefaultCategories() }
    }

    private func loadDefaultCategories() async {
        isLoadingCategories = true
        categoryErrorMessage = nil
        defer { isLoadingCategories = false }

        async let nature = fetchCategorySafely("nature")
        async let backgrounds = fetchCategorySafely("backgrounds")
        async let animals = fetchCategorySafely("animals")
        async let travel = fetchCategorySafely("travel")

        let results = await (nature, backgrounds, animals, travel)
        let byID: [String: (response: PixabaySearchResponse?, error: Error?)] = [
            "nature": results.0, "backgrounds": results.1, "animals": results.2, "travel": results.3
        ]

        categorySections = CategorySection.browsable.map { entry in
            let response = byID[entry.id]?.response
            return CategorySection(
                id: entry.id,
                title: entry.title,
                videos: response?.hits ?? [],
                page: 1,
                totalHits: response?.totalHits ?? 0
            )
        }

        let errors = byID.values.compactMap(\.error)
        if categorySections.allSatisfy(\.videos.isEmpty), let firstError = errors.first {
            categoryErrorMessage = firstError.localizedDescription
        }
    }

    /// Fetches the next page for one category row and appends it in place.
    func loadMoreCategory(_ id: String) {
        guard let index = categorySections.firstIndex(where: { $0.id == id }),
              !categorySections[index].isLoadingMore,
              categorySections[index].hasMore else { return }

        categorySections[index].isLoadingMore = true
        let nextPage = categorySections[index].page + 1

        Task {
            defer {
                if let idx = self.categorySections.firstIndex(where: { $0.id == id }) {
                    self.categorySections[idx].isLoadingMore = false
                }
            }
            do {
                let response = try await fetchVideosUseCase.fetchCategory(category: id, page: nextPage, perPage: perPage, apiKey: apiKey)
                guard let idx = self.categorySections.firstIndex(where: { $0.id == id }) else { return }
                self.categorySections[idx].videos.append(contentsOf: response.hits)
                self.categorySections[idx].page = nextPage
                self.categorySections[idx].totalHits = response.totalHits
            } catch {
                self.categoryErrorMessage = error.localizedDescription
            }
        }
    }

    private func fetchCategorySafely(_ category: String) async -> (response: PixabaySearchResponse?, error: Error?) {
        do {
            return (try await fetchVideosUseCase.fetchCategory(category: category, page: 1, perPage: perPage, apiKey: apiKey), nil)
        } catch {
            return (nil, error)
        }
    }

    // MARK: - Search

    func search() {
        let query = searchQuery
        searchPage = 1
        searchTotalHits = 0
        Task {
            isSearching = true
            errorMessage = nil
            defer { isSearching = false }
            do {
                let response = try await fetchVideosUseCase.search(query: query, page: 1, perPage: perPage, apiKey: apiKey)
                searchResults = response.hits
                searchTotalHits = response.totalHits
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func loadMoreSearchResults() {
        guard !isLoadingMoreSearch, searchHasMore else { return }
        isLoadingMoreSearch = true
        let nextPage = searchPage + 1
        let query = searchQuery
        Task {
            defer { isLoadingMoreSearch = false }
            do {
                let response = try await fetchVideosUseCase.search(query: query, page: nextPage, perPage: perPage, apiKey: apiKey)
                searchResults.append(contentsOf: response.hits)
                searchPage = nextPage
                searchTotalHits = response.totalHits
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Selection / playback

    func select(_ video: PixabayVideo, for scope: DisplaySelection? = nil) {
        let ids = displayIDs(for: scope ?? selectedScope)
        guard !ids.isEmpty else { return }
        for id in ids { wallpaperByDisplay[id] = video }
        manageWallpaperUseCase.saveWallpaperByDisplay(wallpaperByDisplay)
        Task { await loadAndPlay(video, quality: quality, for: ids) }
    }

    func setQuality(_ newQuality: PixabayVideo.Quality) {
        quality = newQuality
        manageWallpaperUseCase.saveQuality(newQuality)
        // Each targeted display keeps whatever video it already has — just
        // re-fetched/applied at the new quality (displays may differ under
        // `.all` if they were set individually before).
        for id in displayIDs(for: selectedScope) {
            guard let video = wallpaperByDisplay[id] else { continue }
            Task { await loadAndPlay(video, quality: newQuality, for: [id]) }
        }
    }

    private func loadAndPlay(_ video: PixabayVideo, quality: PixabayVideo.Quality, for displayIDs: [CGDirectDisplayID]) async {
        guard !displayIDs.isEmpty else { return }
        errorMessage = nil
        if let cached = manageWallpaperUseCase.getCachedFile(for: video, quality: quality) {
            for id in displayIDs { manageWallpaperUseCase.setWallpaper(fileURL: cached, for: id) }
            isPlaying = true
            addToCollection(video)
            return
        }
        for id in displayIDs { downloadingDisplayIDs.insert(id) }
        defer { for id in displayIDs { downloadingDisplayIDs.remove(id) } }
        do {
            let fileURL = try await manageWallpaperUseCase.fetchVideoFile(video, quality: quality)
            for id in displayIDs { manageWallpaperUseCase.setWallpaper(fileURL: fileURL, for: id) }
            isPlaying = true
            addToCollection(video)
        } catch {
            errorMessage = String(localized: "Download failed: \(error.localizedDescription)")
        }
    }

    func togglePlayPause() {
        isPlaying.toggle()
        if isPlaying {
            manageWallpaperUseCase.play()
        } else {
            manageWallpaperUseCase.pause()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        manageWallpaperUseCase.saveMuted(isMuted)
        manageWallpaperUseCase.setMuted(isMuted)
    }

    // MARK: - Collection

    private func addToCollection(_ video: PixabayVideo) {
        guard !collection.contains(where: { $0.id == video.id }) else { return }
        collection.insert(video, at: 0)
        manageCollectionUseCase.saveCollection(collection)
    }

    func isInCollection(_ video: PixabayVideo) -> Bool {
        collection.contains { $0.id == video.id }
    }

    func toggleCollection(_ video: PixabayVideo) {
        if isInCollection(video) {
            removeFromCollection(video)
        } else {
            addToCollection(video)
        }
    }

    func removeFromCollection(_ video: PixabayVideo) {
        collection.removeAll { $0.id == video.id }
        manageCollectionUseCase.saveCollection(collection)
        manageCollectionUseCase.deleteCachedVideo(video)
    }

    func reorderCollection(_ newOrder: [PixabayVideo]) {
        collection = newOrder
        manageCollectionUseCase.saveCollection(collection)
    }
}
