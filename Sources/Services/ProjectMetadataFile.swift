import Foundation

/// Reads the `fastreport.json` (or legacy `.fastreport.json`) that the old
/// FastReport app writes at the root of every project folder.
struct ProjectMetadataFile: Codable, Equatable {
    static let fileName = "fastreport.json"
    static let legacyFileName = ".fastreport.json"

    var mapId: String
    var displayName: String

    static func url(in projectFolder: URL) -> URL? {
        let current = projectFolder.appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: current.path) { return current }
        let legacy = projectFolder.appendingPathComponent(legacyFileName)
        if FileManager.default.fileExists(atPath: legacy.path) { return legacy }
        return nil
    }

    static func decode(from data: Data) throws -> ProjectMetadataFile {
        try JSONDecoder().decode(ProjectMetadataFile.self, from: data)
    }
}
