import Foundation

struct PixabayVideo: Codable, Identifiable, Hashable {
    let id: Int
    let tags: String
    let videos: VideoVariants

    struct VideoVariants: Codable, Hashable {
        let large: Rendition
        let medium: Rendition
        let small: Rendition
        let tiny: Rendition
    }

    struct Rendition: Codable, Hashable {
        let url: String
        let width: Int
        let height: Int
        let size: Int
        let thumbnail: String
    }

    enum Quality: String, CaseIterable, Identifiable {
        case tiny, small, medium, large
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .tiny: return String(localized: "Tiny (540p)")
            case .small: return String(localized: "Small (720p)")
            case .medium: return String(localized: "Medium (1080p)")
            case .large: return String(localized: "Large (4K)")
            }
        }
    }

    func rendition(for quality: Quality) -> Rendition {
        switch quality {
        case .tiny: return videos.tiny
        case .small: return videos.small
        case .medium: return videos.medium
        case .large: return videos.large
        }
    }

    var thumbnailURL: URL? {
        URL(string: videos.tiny.thumbnail)
    }

    /// Highest-res thumbnail available, for full-bleed hero backgrounds.
    var heroThumbnailURL: URL? {
        URL(string: videos.large.thumbnail)
    }

    /// Comma-separated Pixabay tags, title-cased — stands in for the
    /// "location" captions Portal shows on its cards, since Pixabay videos
    /// don't carry real place metadata.
    var tagList: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).capitalized }
    }

    var caption: String { tagList.first ?? "" }
}

struct PixabaySearchResponse: Codable {
    let total: Int
    let totalHits: Int
    let hits: [PixabayVideo]
}
