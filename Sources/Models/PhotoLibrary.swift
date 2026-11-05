import SwiftUI

@Observable
final class PhotoLibrary {
    var folderURL: URL?
    var groups: [PhotoGroup] = []

    func load(_ groups: [PhotoGroup], folderURL: URL? = nil) {
        self.groups = groups
        self.folderURL = folderURL
    }

    func move(groupID: PhotoGroup.ID, from: Int, to: Int) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }) else { return }
        let photos = groups[groupIndex].photos
        guard photos.indices.contains(from), photos.indices.contains(to), from != to else { return }
        groups[groupIndex].photos = ReorderLayout.movingItem(in: photos, from: from, to: to)
    }
}
