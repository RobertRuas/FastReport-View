import SwiftUI

struct PhotoThumbnailView: View {
    let url: URL
    let size: CGFloat
    let isReportMode: Bool
    var onReorderPreview: (CGFloat) -> Void
    var onReorderCommit: (CGFloat) -> Void
    var onReorderCancel: () -> Void
    var onClick: () -> Void

    var body: some View {
        Group {
            if let image = ThumbnailCache.shared.image(for: url, maxPixelSize: Int(size * 2)) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            PhotoDragSourceView(
                url: url,
                isReportMode: isReportMode,
                onReorderPreview: onReorderPreview,
                onReorderCommit: onReorderCommit,
                onReorderCancel: onReorderCancel,
                onClick: onClick
            )
        )
    }
}
