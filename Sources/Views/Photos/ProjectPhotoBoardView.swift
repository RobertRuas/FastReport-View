import SwiftUI

/// The project screen's body: one card per directory, stacked vertically.
struct ProjectPhotoBoardView: View {
    let library: PhotoLibrary
    let dragState: PhotoGridDragState
    let isReportMode: Bool
    let isAutomationMode: Bool
    let automationIndex: Int
    let thumbnailSize: CGFloat
    let onAdvanceAutomation: () -> Void
    let onRetreatAutomation: () -> Void
    let onOpenPhoto: (Photo) -> Void

    var body: some View {
        if isAutomationMode {
            automationBody
        } else {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(library.groups) { group in
                        PhotoGroupCard(group: group, library: library, dragState: dragState, isReportMode: isReportMode, thumbnailSize: thumbnailSize, onOpenPhoto: onOpenPhoto)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Mostra um único diretório por vez com botões "Anterior"/"Próximo" — pensado para
    /// ser disparado por um app de macro externo que automatiza cliques (⌘←/⌘→ também navegam).
    private var automationBody: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let group = currentGroup {
                PhotoGroupCard(group: group, library: library, dragState: dragState, isReportMode: isReportMode, thumbnailSize: thumbnailSize, onOpenPhoto: onOpenPhoto)
                    .padding(20)
                    .id(group.id)
            } else {
                Text("Nenhuma pasta para exibir")
                    .foregroundStyle(.secondary)
                    .padding(20)
            }
            Spacer(minLength: 0)
            HStack {
                automationNavButton(
                    title: "Anterior",
                    systemImage: "arrow.left",
                    leadingIcon: true,
                    action: onRetreatAutomation,
                    shortcutKey: .leftArrow,
                    disabled: automationIndex <= 0
                )
                Spacer()
                Text("\(min(automationIndex + 1, library.groups.count)) / \(library.groups.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                automationNavButton(
                    title: "Próximo",
                    systemImage: "arrow.right",
                    leadingIcon: false,
                    action: onAdvanceAutomation,
                    shortcutKey: .rightArrow,
                    disabled: automationIndex >= library.groups.count - 1
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func automationNavButton(
        title: String,
        systemImage: String,
        leadingIcon: Bool,
        action: @escaping () -> Void,
        shortcutKey: KeyEquivalent,
        disabled: Bool
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if leadingIcon { Image(systemName: systemImage) }
                Text(title)
                if !leadingIcon { Image(systemName: systemImage) }
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.accentColor.opacity(0.18)))
            .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcutKey, modifiers: .command)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private var currentGroup: PhotoGroup? {
        guard library.groups.indices.contains(automationIndex) else { return nil }
        return library.groups[automationIndex]
    }
}

private struct PhotoGroupCard: View {
    let group: PhotoGroup
    let library: PhotoLibrary
    let dragState: PhotoGridDragState
    let isReportMode: Bool
    let thumbnailSize: CGFloat
    let onOpenPhoto: (Photo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(group.title)
                    .font(.headline)
                Text("\(group.photos.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            PhotoGroupStripView(group: group, library: library, dragState: dragState, isReportMode: isReportMode, thumbnailSize: thumbnailSize, onOpenPhoto: onOpenPhoto)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(nsColor: .controlBackgroundColor).opacity(0.5),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.6))
        )
    }
}
