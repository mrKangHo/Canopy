import Foundation

/// One browsable row on the home screen — a Pixabay category and the videos
/// fetched for it, shown up front so the user can pick without typing.
struct CategorySection: Identifiable {
    let id: String
    let title: String
    var videos: [PixabayVideo] = []
    var page: Int = 1
    var totalHits: Int = 0
    var isLoadingMore: Bool = false

    var hasMore: Bool { videos.count < totalHits }

    /// The fixed set of Pixabay categories shown as home-screen shelves —
    /// declared as a static list (rather than derived from fetched data) so
    /// shelf titles are stable immediately, before the network fetch completes.
    static let browsable: [(id: String, title: String)] = [
        ("nature", String(localized: "Nature")),
        ("backgrounds", String(localized: "Backgrounds")),
        ("animals", String(localized: "Animals")),
        ("travel", String(localized: "Travel"))
    ]
}
