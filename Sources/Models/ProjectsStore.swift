import SwiftUI

@Observable
final class ProjectsStore {
    var projects: [Project] = []

    private let fileURL: URL? = try? ProjectsStore.makeFileURL()

    init() {
        load()
    }

    func add(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        projects.insert(project, at: 0)
        persist()
    }

    func remove(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        persist()
        if let projectsRoot = try? ProjectsStore.projectsRootFolder() {
            try? FileManager.default.removeItem(at: projectsRoot.appendingPathComponent(project.id, isDirectory: true))
        }
    }

    func rename(_ project: Project, to newName: String) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].displayName = newName
        persist()
    }

    func setCompleted(_ project: Project, _ isCompleted: Bool) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isCompleted = isCompleted
        persist()
    }

    func contains(displayName: String, mapId: String) -> Bool {
        projects.contains { $0.displayName == displayName && $0.mapId == mapId }
    }

    private func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        projects = (try? decoder.decode([Project].self, from: data)) ?? []
    }

    private func persist() {
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(projects) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func projectsRootFolder() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appendingPathComponent("FastReport/Projects", isDirectory: true)
    }

    private static func makeFileURL() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = base.appendingPathComponent("FastReport", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("projects.json")
    }
}
