import SwiftUI

struct MainContentView: View {
    @ObservedObject var manager: WallpaperManager
    @State private var showingSettings = false
    @State private var detailVideo: PixabayVideo?

    private var heroItem: PixabayVideo? {
        manager.currentItem ?? manager.categorySections.first(where: { !$0.videos.isEmpty })?.videos.first
    }

    private var browsableVideos: [PixabayVideo] {
        manager.categorySections.flatMap(\.videos)
    }

    var body: some View {
        ZStack {
            HeroBackgroundView(item: heroItem)

            VStack(spacing: 0) {
                topBar
                if manager.displays.count > 1 {
                    controlsBar
                }
                Spacer(minLength: 12)
                bottomTextRow
                    .padding(.horizontal, 32)
                    .padding(.bottom, 22)
                shelvesSection
                    .padding(.bottom, 88)
            }

            if let detailVideo {
                VideoDetailView(manager: manager, video: detailVideo, onBack: { self.detailVideo = nil })
            }

            if !manager.searchQuery.isEmpty {
                searchOverlay
            }

            if manager.apiKey.isEmpty {
                missingAPIKeyOverlay
            }

            // Always on top, so it stays visible over the detail screen and
            // search overlay too — it's the one persistent piece of chrome.
            VStack {
                Spacer()
                NowPlayingBar(
                    manager: manager,
                    browsableVideos: browsableVideos,
                    onOpenSettings: { showingSettings = true }
                )
                .padding(.bottom, 20)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
        .preferredColorScheme(.dark)
        .onAppear { manager.loadDefaultCategoriesIfNeeded() }
        .sheet(isPresented: $showingSettings) {
            SettingsView(manager: manager)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            searchField
        }
        .padding(.top, 22)
        .padding(.trailing, 24)
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
                .onSubmit { manager.search() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.35), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    // MARK: - Display picker

    /// Sits below the traffic-light zone so it never collides with them.
    /// Only appears once a second display actually exists — no point
    /// showing a chooser with one option.
    private var controlsBar: some View {
        HStack(spacing: 10) {
            displayPill(label: String(localized: "All"), isSelected: manager.selectedScope == .all) {
                manager.selectedScope = .all
            }
            ForEach(manager.displays) { display in
                displayPill(label: display.name, isSelected: manager.selectedScope == .display(display.id)) {
                    manager.selectedScope = .display(display.id)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
    }

    private func displayPill(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? Theme.accent : .white.opacity(0.5))
        .controlSize(.small)
    }

    // MARK: - Current caption

    private var bottomTextRow: some View {
        HStack(alignment: .bottom) {
            Spacer()
            if let item = heroItem {
                currentItemCaption(item)
            }
        }
    }

    private func currentItemCaption(_ item: PixabayVideo) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundStyle(.white.opacity(0.75))
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.caption.isEmpty ? String(localized: "Untitled") : item.caption)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                if let second = item.tagList.dropFirst().first {
                    Text(second.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - Shelves

    private var shelvesSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if manager.isLoadingCategories && manager.categorySections.allSatisfy(\.videos.isEmpty) {
                    ProgressView()
                        .tint(Theme.accent)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else if let error = manager.categoryErrorMessage, manager.categorySections.allSatisfy(\.videos.isEmpty) {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 32)
                } else {
                    // Order unchanged (Collection still first) — it's just
                    // pushed down with extra top space so it renders lower,
                    // roughly where the second shelf used to sit.
                    if !manager.collection.isEmpty {
                        ShelfRow(
                            title: String(localized: "My Collection"),
                            videos: manager.collection,
                            currentVideoID: manager.currentItem?.id,
                            isEditable: true,
                            onDelete: { manager.removeFromCollection($0) },
                            onReorder: { manager.reorderCollection($0) },
                            onSelect: { detailVideo = $0 }
                        )
                        .padding(.top, 400)
                    }
                    ForEach(manager.categorySections) { section in
                        shelfRow(for: section)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func shelfRow(for section: CategorySection) -> some View {
        if !section.videos.isEmpty {
            ShelfRow(
                title: section.title,
                videos: section.videos,
                currentVideoID: manager.currentItem?.id,
                hasMore: section.hasMore,
                isLoadingMore: section.isLoadingMore,
                onLoadMore: { manager.loadMoreCategory(section.id) },
                onSelect: { detailVideo = $0 }
            )
        }
    }

    // MARK: - Search overlay

    private var searchOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Results for \u{201C}\(manager.searchQuery)\u{201D}")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    manager.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Search Results")
            }
            .padding(20)

            Divider().overlay(Color.white.opacity(0.1))

            searchResultsBody
        }
        .background(.black.opacity(0.75))
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var searchResultsBody: some View {
        if manager.isSearching {
            ProgressView().tint(Theme.accent).frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = manager.errorMessage {
            Text(error)
                .foregroundStyle(.red)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if manager.searchResults.isEmpty {
            Text("No results yet — press Return to search.")
                .foregroundStyle(.white.opacity(0.6))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            SearchResultsGrid(
                results: manager.searchResults,
                currentVideoID: manager.currentItem?.id,
                hasMore: manager.searchHasMore,
                isLoadingMore: manager.isLoadingMoreSearch,
                onLoadMore: { manager.loadMoreSearchResults() },
                onSelect: { detailVideo = $0 }
            )
        }
    }

    private var missingAPIKeyOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.8))
            Text("Add your Pixabay API key to get started.")
                .foregroundStyle(.white)
            Button("Open Settings") { showingSettings = true }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
