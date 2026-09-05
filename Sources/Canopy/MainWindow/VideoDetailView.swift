import SwiftUI

/// Shown after tapping a thumbnail, instead of applying it immediately —
/// gives the user a chance to look before committing. "Play" is the only
/// thing that actually downloads/sets the wallpaper (WallpaperManager.select);
/// the heart just favorites it into the Collection without downloading yet.
struct VideoDetailView: View {
    @ObservedObject var manager: WallpaperManager
    let video: PixabayVideo
    let onBack: () -> Void

    private var isCurrent: Bool { manager.currentItem?.id == video.id }
    private var isFavorited: Bool { manager.isInCollection(video) }

    private var resolutionBadge: String {
        let large = video.videos.large
        if large.width >= 3800 { return "4K" }
        if large.width >= 1900 { return "HD" }
        return "\(large.width)×\(large.height)"
    }

    var body: some View {
        ZStack {
            HeroBackgroundView(item: video)

            VStack(spacing: 0) {
                HStack {
                    backButton
                    Spacer()
                    searchField
                }
                .padding(.top, 22)
                .padding(.horizontal, 24)

                Spacer()

                detailBlock
                    .padding(.bottom, 130)
            }
        }
        .transition(.opacity)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.9), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.65))
                .font(.system(size: 12))
            TextField("Search", text: $manager.searchQuery)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .font(.system(size: 13))
                .frame(width: 130)
                .onSubmit {
                    manager.search()
                    onBack()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.35), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    private var detailBlock: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text(video.caption.isEmpty ? String(localized: "Untitled") : video.caption)
                    .font(.system(size: 38, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                if let subtitle = video.tagList.dropFirst().first {
                    Text(subtitle.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Text(resolutionBadge)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(Capsule().stroke(Color.white.opacity(0.4)))
                .foregroundStyle(.white.opacity(0.85))

            if !video.tagList.isEmpty {
                Text(video.tagList.joined(separator: "  ·  "))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
            }

            HStack(spacing: 18) {
                Button {
                    manager.toggleCollection(video)
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundStyle(isFavorited ? Theme.accent : .white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFavorited ? "Remove from Collection" : "Add to Collection")

                Button {
                    manager.select(video, for: manager.selectedScope)
                } label: {
                    Label(playLabel, systemImage: isCurrent && manager.isPlaying ? "checkmark" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundStyle(.black)
                .disabled(isCurrent && manager.isDownloadingCurrent)
            }
        }
    }

    private var playLabel: String {
        if isCurrent && manager.isDownloadingCurrent { return "Downloading…" }
        if isCurrent && manager.isPlaying { return "Playing" }
        return "Play"
    }
}
