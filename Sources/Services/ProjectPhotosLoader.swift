import Foundation

enum ProjectPhotosLoader {
    /// Walks the project's map in report order and returns one group per slot
    /// folder — every directory, including empty ones — so the project screen
    /// shows one row per directory (General, T1, T2, ...) exactly as the map
    /// defines them, regardless of whether photos have been placed there yet.
    static func groups(for project: Project) -> [PhotoGroup] {
        guard let map = MapCatalog.map(id: project.mapId) else {
            let photos = PhotoFolderLoader.photos(in: project.folderURL)
            return [PhotoGroup(id: "all", title: project.displayName, photos: photos)]
        }
        return map.displaySlots.map { slot in
            let photos = PhotoFolderLoader.photos(in: slot.folderURL(in: project.folderURL))
            let title = slot.group.map { "\($0) / \(slot.folder)" } ?? slot.folder
            return PhotoGroup(id: slot.pathComponents.joined(separator: "/"), title: title, photos: photos)
        }
    }
}
