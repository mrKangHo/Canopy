import SwiftUI

struct ShelfRow: View {
    let title: String
    let videos: [PixabayVideo]
    let currentVideoID: Int?
    var hasMore: Bool = false
    var isLoadingMore: Bool = false
    var onLoadMore: (() -> Void)?

    /// When set, shows an Edit/Done toggle that lets the user delete items
    /// and drag to reorder them — used for "My Collection", not the
    /// read-only Pixabay category shelves.
    var isEditable: Bool = false
    var onDelete: ((PixabayVideo) -> Void)?
    var onReorder: (([PixabayVideo]) -> Void)?

    let onSelect: (PixabayVideo) -> Void

    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 19, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)

                if isEditable {
                    Spacer()
                    Button(isEditing ? "Done" : "Edit") {
                        isEditing.toggle()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.trailing, 32)
                }
            }
            .padding(.leading, 32)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(videos) { video in
                        thumbnailItem(video)
                    }

                    if hasMore {
                        loadMoreButton
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 4)
            }
        }
    }

    @ViewBuilder
    private func thumbnailItem(_ video: PixabayVideo) -> some View {
        let thumbnail = ZStack(alignment: .topTrailing) {
            Button {
                guard !isEditing else { return }
                onSelect(video)
            } label: {
                VideoThumbnailView(video: video, isSelected: video.id == currentVideoID)
                    .frame(width: 190)
            }
            .buttonStyle(.plain)

            if isEditable && isEditing {
                Button {
                    onDelete?(video)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(video.caption.isEmpty ? String(localized: "Video") : video.caption) from Collection")
                .offset(x: 6, y: -6)
            }
        }

        let draggableThumbnail = Group {
            if isEditable && isEditing {
                thumbnail
                    .draggable(String(video.id))
                    .dropDestination(for: String.self) { items, _ in
                        guard let draggedID = items.first.flatMap(Int.init) else { return false }
                        reorder(draggedID: draggedID, targetID: video.id)
                        return true
                    }
            } else {
                thumbnail
            }
        }

        if isEditable && isEditing {
            VStack(spacing: 6) {
                draggableThumbnail
                // Non-drag alternative to the drag-to-reorder above (WCAG 2.2
                // "Dragging Movements" requires a single-pointer alternative).
                HStack(spacing: 0) {
                    Button {
                        move(video, by: -1)
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                    }
                    .accessibilityLabel("Move Earlier")
                    .disabled(isFirst(video))

                    Spacer()

                    Button {
                        move(video, by: 1)
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .accessibilityLabel("Move Later")
                    .disabled(isLast(video))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 190)
            }
        } else {
            draggableThumbnail
        }
    }

    private func isFirst(_ video: PixabayVideo) -> Bool { videos.first?.id == video.id }
    private func isLast(_ video: PixabayVideo) -> Bool { videos.last?.id == video.id }

    private func move(_ video: PixabayVideo, by delta: Int) {
        guard let index = videos.firstIndex(where: { $0.id == video.id }) else { return }
        let newIndex = index + delta
        guard videos.indices.contains(newIndex) else { return }
        var reordered = videos
        reordered.swapAt(index, newIndex)
        onReorder?(reordered)
    }

    private var loadMoreButton: some View {
        Button {
            onLoadMore?()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .frame(width: 100, height: 110)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
                if isLoadingMore {
                    ProgressView().tint(Theme.accent)
                } else {
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Load More")
        .disabled(isLoadingMore)
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
}
