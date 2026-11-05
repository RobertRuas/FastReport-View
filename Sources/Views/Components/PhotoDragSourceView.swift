import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PhotoDragSourceView: NSViewRepresentable {
    let url: URL
    let isReportMode: Bool
    var onReorderPreview: (CGFloat) -> Void
    var onReorderCommit: (CGFloat) -> Void
    var onReorderCancel: () -> Void
    var onClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            url: url,
            isReportMode: isReportMode,
            onReorderPreview: onReorderPreview,
            onReorderCommit: onReorderCommit,
            onReorderCancel: onReorderCancel,
            onClick: onClick
        )
    }

    func makeNSView(context: Context) -> PhotoDragNSView {
        let view = PhotoDragNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: PhotoDragNSView, context: Context) {
        context.coordinator.url = url
        context.coordinator.isReportMode = isReportMode
        context.coordinator.onReorderPreview = onReorderPreview
        context.coordinator.onReorderCommit = onReorderCommit
        context.coordinator.onReorderCancel = onReorderCancel
        context.coordinator.onClick = onClick
    }

    final class Coordinator {
        var url: URL
        var isReportMode: Bool
        var onReorderPreview: (CGFloat) -> Void
        var onReorderCommit: (CGFloat) -> Void
        var onReorderCancel: () -> Void
        var onClick: () -> Void

        init(
            url: URL,
            isReportMode: Bool,
            onReorderPreview: @escaping (CGFloat) -> Void,
            onReorderCommit: @escaping (CGFloat) -> Void,
            onReorderCancel: @escaping () -> Void,
            onClick: @escaping () -> Void
        ) {
            self.url = url
            self.isReportMode = isReportMode
            self.onReorderPreview = onReorderPreview
            self.onReorderCommit = onReorderCommit
            self.onReorderCancel = onReorderCancel
            self.onClick = onClick
        }
    }
}

/// O modo determina o que um arrasto faz, sem ambiguidade: fora do modo de
/// relatório, o gesto só reordena a grade (nunca inicia uma sessão de arrasto
/// nativa, então nunca sai da janela/app). No modo de relatório, o gesto nunca
/// reordena — ao exceder o limiar de movimento já inicia uma `NSDraggingSession`
/// nativa que exporta o ficheiro para outra aplicação.
final class PhotoDragNSView: NSView, NSDraggingSource {
    weak var coordinator: PhotoDragSourceView.Coordinator?
    private var mouseDownEvent: NSEvent?
    private var mouseDownScreenPoint: NSPoint = .zero
    private var isDraggingOut = false
    private var didMove = false
    private var accessingFile = false

    override var isFlipped: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        mouseDownEvent = event
        mouseDownScreenPoint = NSEvent.mouseLocation
        isDraggingOut = false
        didMove = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isDraggingOut, let coordinator, let mouseDownEvent else { return }
        let current = NSEvent.mouseLocation
        let translationX = current.x - mouseDownScreenPoint.x
        let translationY = current.y - mouseDownScreenPoint.y
        guard hypot(translationX, translationY) >= 4 else { return }
        didMove = true

        guard coordinator.isReportMode else {
            coordinator.onReorderPreview(translationX)
            return
        }

        isDraggingOut = true
        accessingFile = coordinator.url.startAccessingSecurityScopedResource()
        let writer = PhotoPasteboardWriter(url: coordinator.url)
        let item = NSDraggingItem(pasteboardWriter: writer)
        item.setDraggingFrame(bounds, contents: ThumbnailCache.shared.image(for: coordinator.url, maxPixelSize: 240))
        beginDraggingSession(with: [item], event: mouseDownEvent, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            mouseDownEvent = nil
            isDraggingOut = false
        }
        guard let coordinator else { return }
        guard didMove else {
            coordinator.onClick()
            return
        }
        if !isDraggingOut {
            let translationX = NSEvent.mouseLocation.x - mouseDownScreenPoint.x
            coordinator.onReorderCommit(translationX)
        }
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        context == .outsideApplication ? .copy : []
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        if accessingFile {
            coordinator?.url.stopAccessingSecurityScopedResource()
            accessingFile = false
        }
        coordinator?.onReorderCancel()
    }
}

final class PhotoPasteboardWriter: NSObject, NSPasteboardWriting {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        var types: [NSPasteboard.PasteboardType] = [.fileURL, NSPasteboard.PasteboardType("NSFilenamesPboardType")]
        if let utType = UTType(filenameExtension: url.pathExtension) {
            types.append(NSPasteboard.PasteboardType(utType.identifier))
        }
        return types
    }

    func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .fileURL:
            return url.absoluteURL.absoluteString
        case NSPasteboard.PasteboardType("NSFilenamesPboardType"):
            return [url.path]
        default:
            return try? Data(contentsOf: url)
        }
    }
}
