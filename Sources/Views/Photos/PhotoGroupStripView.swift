import SwiftUI

/// One directory's row: a horizontal strip of thumbnails that reorder among
/// themselves only (no cross-directory drag), mirroring the old app's
/// per-folder LiveReorderStrip.
struct PhotoGroupStripView: View {
    let group: PhotoGroup
    let library: PhotoLibrary
    let dragState: PhotoGridDragState
    let isReportMode: Bool
    let thumbnailSize: CGFloat
    let onOpenPhoto: (Photo) -> Void

    private let spacing: CGFloat = 10
    private var cellWidth: CGFloat { thumbnailSize + spacing }

    var body: some View {
        if group.photos.isEmpty {
            emptyPlaceholder
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(Array(group.photos.enumerated()), id: \.element.id) { index, photo in
                        cell(index: index, photo: photo)
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollDisabled(isActiveGroup && dragState.draggedPhotoID != nil)
        }
    }

    private var emptyPlaceholder: some View {
        HStack(spacing: 6) {
            Image(systemName: "tray")
            Text("Vazio")
        }
        .font(.callout)
        .foregroundStyle(.tertiary)
        .frame(height: thumbnailSize)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isActiveGroup: Bool {
        dragState.groupID == group.id
    }

    private var currentTargetIndex: Int {
        guard isActiveGroup, let start = dragState.startIndex else { return 0 }
        return ReorderLayout.targetIndex(
            from: start,
            translationX: dragState.translationX,
            cellWidth: cellWidth,
            count: group.photos.count
        )
    }

    private func cell(index: Int, photo: Photo) -> some View {
        let isDragged = isActiveGroup && dragState.draggedPhotoID == photo.id
        let shift: CGFloat = {
            guard isActiveGroup, let start = dragState.startIndex, !isDragged else { return 0 }
            return ReorderLayout.neighborOffset(
                index: index,
                dragIndex: start,
                targetIndex: currentTargetIndex,
                cellWidth: cellWidth
            )
        }()

        return PhotoThumbnailView(
            url: photo.url,
            size: thumbnailSize,
            isReportMode: isReportMode,
            onReorderPreview: { translationX in
                if dragState.draggedPhotoID == nil {
                    dragState.begin(groupID: group.id, photoID: photo.id, index: index)
                }
                dragState.update(translationX: translationX)
            },
            onReorderCommit: { translationX in
                let target = ReorderLayout.targetIndex(
                    from: index,
                    translationX: translationX,
                    cellWidth: cellWidth,
                    count: group.photos.count
                )
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if index != target {
                        library.move(groupID: group.id, from: index, to: target)
                    }
                    dragState.reset()
                }
            },
            onReorderCancel: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    dragState.reset()
                }
            },
            onClick: { onOpenPhoto(photo) }
        )
        .shadow(color: isDragged ? Color.black.opacity(0.22) : .clear, radius: isDragged ? 8 : 0, y: isDragged ? 3 : 0)
        .scaleEffect(isDragged ? 1.05 : 1)
        .zIndex(isDragged ? 10 : 0)
        .offset(x: isDragged ? dragState.translationX : shift)
        .animation(isDragged ? nil : .interactiveSpring(response: 0.32, dampingFraction: 0.9), value: currentTargetIndex)
        .animation(.spring(response: 0.24, dampingFraction: 0.75), value: isDragged)
    }
}
