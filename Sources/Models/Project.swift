import Foundation

struct Project: Identifiable, Equatable, Codable {
    let id: String
    var displayName: String
    var mapId: String
    var folderURL: URL
    var importedAt: Date
    var isCompleted: Bool = false

    private enum CodingKeys: String, CodingKey {
        case id, displayName, mapId, folderURL, importedAt, isCompleted
    }

    init(id: String, displayName: String, mapId: String, folderURL: URL, importedAt: Date, isCompleted: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.mapId = mapId
        self.folderURL = folderURL
        self.importedAt = importedAt
        self.isCompleted = isCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        mapId = try container.decode(String.self, forKey: .mapId)
        folderURL = try container.decode(URL.self, forKey: .folderURL)
        importedAt = try container.decode(Date.self, forKey: .importedAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
    }
}
