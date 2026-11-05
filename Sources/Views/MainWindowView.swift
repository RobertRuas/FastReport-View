import SwiftUI

struct MainWindowView: View {
    let state: AppState

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                content
                StatusBarView {
                    if let project = state.openProject {
                        StatusBarItem(icon: "folder", project.displayName)
                        StatusBarItem(icon: "photo.on.rectangle", "\(photoCount) fotos")
                    } else {
                        StatusBarItem(
                            icon: "arrow.up.left.and.arrow.down.right",
                            "\(Int((proxy.size.width + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing).rounded())) × \(Int((proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom).rounded())) px"
                        )
                        StatusBarItem(
                            icon: "location",
                            "\(Int(state.windowOrigin.x.rounded())), \(Int(state.windowOrigin.y.rounded()))"
                        )
                    }
                }
            }
        }
    }

    private var photoCount: Int {
        state.photoLibrary.groups.reduce(0) { $0 + $1.photos.count }
    }

    /// A project screen replaces the whole window — sidebar included — rather
    /// than nesting inside the NavigationSplitView's detail pane.
    @ViewBuilder
    private var content: some View {
        if let project = state.openProject {
            ProjectView(state: state, project: project)
        } else {
            HomeView(state: state)
        }
    }
}
