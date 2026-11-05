import Foundation

enum ProjectPhotosLoader {
    /// Walks the project's map in report order and returns one group per
    /// non-empty slot folder, so the project screen shows one row per
    /// directory (General, T1, T2, ...) exactly as the old app organized it.
    static func groups(for project: Project) -> [PhotoGroup] {
        guard let map = MapCatalog.map(id: project.mapId) else {
            let photos = PhotoFolderLoader.photos(in: project.folderURL)
            return photos.isEmpty ? [] : [PhotoGroup(id: "all", title: project.displayName, photos: photos)]
        }
        return map.displaySlots.compactMap { slot in
            let photos = PhotoFolderLoader.photos(in: slot.folderURL(in: project.folderURL))
            guard !photos.isEmpty else { return nil }
            let title = slot.group.map { "\($0) / \(slot.folder)" } ?? slot.folder
            return PhotoGroup(id: slot.pathComponents.joined(separator: "/"), title: title, photos: photos)
        }
    }
}
