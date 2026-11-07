import SwiftUI

@Observable
final class AppState {
    var openProject: Project?
    var isSettingsPresented = false
    var isReportMode = false
    var isAutomationMode = false
    var automationIndex = 0
    var windowOrigin: CGPoint = .zero
    var previewPhoto: Photo?
    var thumbnailSize: CGFloat = 104

    private let thumbnailSizeRange: ClosedRange<CGFloat> = 72...220
    private let thumbnailSizeStep: CGFloat = 24

    @ObservationIgnored
    let updater = UpdaterController()

    @ObservationIgnored
    let photoLibrary = PhotoLibrary()

    @ObservationIgnored
    let photoDragState = PhotoGridDragState()

    @ObservationIgnored
    let projectsStore = ProjectsStore()

    func open(_ project: Project) {
        openProject = project
        photoLibrary.load(ProjectPhotosLoader.groups(for: project), folderURL: project.folderURL)
        automationIndex = 0
    }

    func closeProject() {
        openProject = nil
        photoLibrary.load([])
        isReportMode = false
        isAutomationMode = false
        automationIndex = 0
    }

    func advanceAutomation() {
        let count = photoLibrary.groups.count
        guard count > 0 else { return }
        automationIndex = min(automationIndex + 1, count - 1)
    }

    func retreatAutomation() {
        automationIndex = max(automationIndex - 1, 0)
    }

    var canIncreaseThumbnailSize: Bool { thumbnailSize < thumbnailSizeRange.upperBound }
    var canDecreaseThumbnailSize: Bool { thumbnailSize > thumbnailSizeRange.lowerBound }

    func increaseThumbnailSize() {
        thumbnailSize = min(thumbnailSize + thumbnailSizeStep, thumbnailSizeRange.upperBound)
    }

    func decreaseThumbnailSize() {
        thumbnailSize = max(thumbnailSize - thumbnailSizeStep, thumbnailSizeRange.lowerBound)
    }
}
