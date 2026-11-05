import Foundation

struct MapSlot: Equatable {
    let folder: String
    let group: String?
    let isTrash: Bool
    let isInbox: Bool

    init(folder: String, group: String? = nil, isTrash: Bool = false, isInbox: Bool = false) {
        self.folder = folder
        self.group = group
        self.isTrash = isTrash
        self.isInbox = isInbox
    }

    var pathComponents: [String] {
        group.map { [$0, folder] } ?? [folder]
    }

    func folderURL(in projectFolder: URL) -> URL {
        pathComponents.reduce(projectFolder) { $0.appendingPathComponent($1, isDirectory: true) }
    }
}
