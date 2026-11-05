import SwiftUI

@Observable
final class AppState {
    var selectedSection: AppSection? = .home
    var openProject: Project?
    var isReportMode = false
    var isAutomationMode = false
    var automationIndex = 0
    var windowOrigin: CGPoint = .zero

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
}
