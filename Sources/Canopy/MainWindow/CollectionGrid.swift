import SwiftUI

/// Grid for the "Collection" sidebar item — videos the user has actually
/// downloaded/played before. Each is removable (deletes the local cache file
/// too, via WallpaperManager.removeFromCollection) and draggable to reorder.
struct CollectionGrid: View {
    let videos: [PixabayVideo]
    let currentVideoID: Int?
    let onSelect: (PixabayVideo) -> Void
    let onRemove: (PixabayVideo) -> Void
    var onReorder: (([PixabayVideo]) -> Void)?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos) { video in
                    ZStack(alignment: .topTrailing) {
                        Button {
                            onSelect(video)
                        } label: {
                            VideoThumbnailView(video: video, isSelected: video.id == currentVideoID)
                        }
                        .buttonStyle(.plain)

                        Button {
                            onRemove(video)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                        .padding(5)
                        .help("Remove from Collection")
                        .accessibilityLabel("Remove \(video.caption.isEmpty ? String(localized: "Video") : video.caption) from Collection")
                    }
                    .draggable(String(video.id))
                    .dropDestination(for: String.self) { items, _ in
                        guard let draggedID = items.first.flatMap(Int.init) else { return false }
                        reorder(draggedID: draggedID, targetID: video.id)
                        return true
                    }
                    // Non-drag alternative to the drag-to-reorder above (WCAG
                    // 2.2 "Dragging Movements" needs a single-pointer path).
                    .contextMenu {
                        Button("Move Earlier") { move(video, by: -1) }
                            .disabled(videos.first?.id == video.id)
                        Button("Move Later") { move(video, by: 1) }
                            .disabled(videos.last?.id == video.id)
                    }
                }
            }
            .padding(16)
        }
    }

    private func reorder(draggedID: Int, targetID: Int) {
        guard draggedID != targetID,
              let fromIndex = videos.firstIndex(where: { $0.id == draggedID }),
              let toIndex = videos.firstIndex(where: { $0.id == targetID }) else { return }
        var reordered = videos
        let moved = reordered.remove(at: fromIndex)
        reordered.insert(moved, at: toIndex)
        onReorder?(reordered)
    }

    private func move(_ video: PixabayVideo, by delta: Int) {
        guard let index = videos.firstIndex(where: { $0.id == video.id }) else { return }
        let newIndex = index + delta
        guard videos.indices.contains(newIndex) else { return }
        var reordered = videos
        reordered.swapAt(index, newIndex)
        onReorder?(reordered)
    }
}
