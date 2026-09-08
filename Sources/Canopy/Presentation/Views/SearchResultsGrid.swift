import SwiftUI

struct SearchResultsGrid: View {
    let results: [PixabayVideo]
    let currentVideoID: Int?
    var hasMore: Bool = false
    var isLoadingMore: Bool = false
    var onLoadMore: (() -> Void)?
    let onSelect: (PixabayVideo) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(results) { video in
                    Button {
                        onSelect(video)
                    } label: {
                        VideoThumbnailView(video: video, isSelected: video.id == currentVideoID)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            if hasMore {
                loadMoreControl
                    .padding(.bottom, 24)
            }
        }
    }

    @ViewBuilder
    private var loadMoreControl: some View {
        if isLoadingMore {
            ProgressView()
                .tint(Theme.accent)
                .controlSize(.small)
        } else {
            Button("Load More") { onLoadMore?() }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
        }
    }
}
