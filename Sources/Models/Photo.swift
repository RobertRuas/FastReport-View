import Foundation

struct Photo: Identifiable, Equatable, Hashable {
    let id: String
    let url: URL

    init(url: URL) {
        self.url = url
        self.id = Photo.stableID(for: url)
    }

    static func stableID(for url: URL) -> String {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        if let fileNumber = attributes?[.systemFileNumber] as? UInt64, fileNumber > 0 {
            let volumeNumber = attributes?[.systemNumber] as? UInt ?? 0
            return "inode-\(volumeNumber)-\(fileNumber)"
        }
        return url.standardizedFileURL.path
    }
}
