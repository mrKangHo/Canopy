import SwiftUI

/// The floating capsule at the bottom — mirrors Portal's "now playing" pill.
/// Folds in what used to be the separate transport bar: mute, step through
/// the currently loaded videos, play/pause, jump to the Collection, and
/// Settings. Always reflects the currently *selected display*'s wallpaper.
struct NowPlayingBar: View {
    @ObservedObject var manager: WallpaperManager
    let browsableVideos: [PixabayVideo]
    let onOpenSettings: () -> Void

    @State private var showingCollection = false

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 1) {
                if let item = manager.currentItem {
                    Text(item.tagList.dropFirst().first ?? "Canopy")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                    Text(item.caption.isEmpty ? String(localized: "Untitled") : item.caption)
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    Text("Nothing playing")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(minWidth: 90, maxWidth: 140, alignment: .leading)

            Spacer(minLength: 8)

            controls
        }
        .padding(.leading, 8)
        .padding(.trailing, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
    }

    private var thumbnail: some View {
        Group {
            if let url = manager.currentItem?.thumbnailURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Theme.surface
                    }
                }
            } else {
                Theme.surface
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                manager.toggleMute()
            } label: {
                Image(systemName: manager.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            .accessibilityLabel(manager.isMuted ? "Unmute" : "Mute")

            Button {
                showingCollection = true
            } label: {
                Image(systemName: "square.stack.fill")
            }
            .accessibilityLabel("Collection")
            .popover(isPresented: $showingCollection, arrowEdge: .top) {
                CollectionPopover(manager: manager)
            }

            Button {
                step(by: -1)
            } label: {
                Image(systemName: "backward.fill")
            }
            .accessibilityLabel("Previous Video")
            .disabled(browsableVideos.count < 2)

            Button {
                manager.togglePlayPause()
            } label: {
                Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.white.opacity(manager.currentItem == nil ? 0.3 : 1)))
                    .foregroundStyle(.black)
            }
            .accessibilityLabel(manager.isPlaying ? "Pause" : "Play")
            .disabled(manager.currentItem == nil)

            Button {
                step(by: 1)
            } label: {
                Image(systemName: "forward.fill")
            }
            .accessibilityLabel("Next Video")
            .disabled(browsableVideos.count < 2)

            if manager.isDownloadingCurrent {
                ProgressView().tint(Theme.accent).controlSize(.small)
            }

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
            }
            .accessibilityLabel("Settings")
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }

    private func step(by delta: Int) {
        guard let currentID = manager.currentItem?.id,
              let index = browsableVideos.firstIndex(where: { $0.id == currentID }),
              !browsableVideos.isEmpty else { return }
        let next = (index + delta + browsableVideos.count) % browsableVideos.count
        manager.select(browsableVideos[next], for: manager.selectedScope)
    }
}

private struct CollectionPopover: View {
    @ObservedObject var manager: WallpaperManager

    var body: some View {
        Group {
            if manager.collection.isEmpty {
                Text("Videos you download will show up here.")
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(width: 280, height: 140)
            } else {
                CollectionGrid(
                    videos: manager.collection,
                    currentVideoID: manager.currentItem?.id,
                    onSelect: { manager.select($0, for: manager.selectedScope) },
                    onRemove: { manager.removeFromCollection($0) },
                    onReorder: { manager.reorderCollection($0) }
                )
                .frame(width: 320, height: 360)
            }
        }
        .background(Theme.background)
        .preferredColorScheme(.dark)
    }
}
