import SwiftUI

struct VideoThumbnailView: View {
    let video: PixabayVideo
    let isSelected: Bool
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(16.0 / 9.0, contentMode: .fill)
                default:
                    Rectangle().fill(Theme.surface)
                }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fill)

            LinearGradient(
                colors: [.black.opacity(0.65), .clear],
                startPoint: .bottom,
                endPoint: .center
            )

            if !video.caption.isEmpty {
                Text(video.caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(8)
            }
        }
        .frame(height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Theme.accent : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: (isSelected ? Theme.accent : .black).opacity(isHovering || isSelected ? 0.35 : 0.15),
                radius: isHovering ? 10 : 4, y: isHovering ? 4 : 2)
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 1.0), value: isHovering)
        .onHover { isHovering = $0 }
    }
}
