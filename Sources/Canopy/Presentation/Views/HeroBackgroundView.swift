import SwiftUI

/// Full-bleed backdrop behind the whole window — the selected display's
/// current wallpaper frame, dimmed toward the bottom so the text overlaid on
/// it (caption, shelves) stays legible. This is what makes the app itself
/// feel like "a window into the wallpaper" rather than a utility panel
/// bolted on top of one.
struct HeroBackgroundView: View {
    let item: PixabayVideo?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.background

                if let url = item?.heroThumbnailURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let image) = phase {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .transition(.opacity)
                        }
                    }
                    .id(url)
                }

                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.15), location: 0),
                        .init(color: .clear, location: 0.35),
                        .init(color: .black.opacity(0.55), location: 0.72),
                        .init(color: .black.opacity(0.92), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .animation(.easeInOut(duration: 0.4), value: item?.heroThumbnailURL)
        .ignoresSafeArea()
    }
}
