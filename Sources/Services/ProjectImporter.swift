import Foundation

enum ProjectImportError: Error {
    case invalidZip
    case extractionFailed(String)
    case missingMetadata
    case duplicateProject(displayName: String)
}

enum ProjectImporter {
    @discardableResult
    static func importZip(at zipURL: URL, into store: ProjectsStore) throws -> Project {
        guard zipURL.pathExtension.lowercased() == "zip" else {
            throw ProjectImportError.invalidZip
        }

        let destinationRoot = try ProjectsStore.projectsRootFolder()
        try FileManager.default.createDirectory(at: destinationRoot, withIntermediateDirectories: true)
        let destination = uniqueDestination(named: zipURL.deletingPathExtension().lastPathComponent, in: destinationRoot)
        try extract(zipURL, to: destination)

        let projectFolder = resolveProjectFolder(in: destination)
        guard let metadataURL = ProjectMetadataFile.url(in: projectFolder),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? ProjectMetadataFile.decode(from: data)
        else {
            try? FileManager.default.removeItem(at: destination)
            throw ProjectImportError.missingMetadata
        }

        if store.contains(displayName: metadata.displayName, mapId: metadata.mapId) {
            try? FileManager.default.removeItem(at: destination)
            throw ProjectImportError.duplicateProject(displayName: metadata.displayName)
        }

        let project = Project(
            id: destination.lastPathComponent,
            displayName: metadata.displayName,
            mapId: metadata.mapId,
            folderURL: projectFolder,
            importedAt: Date()
        )
        store.add(project)
        return project
    }

    private static func uniqueDestination(named name: String, in root: URL) -> URL {
        var candidate = root.appendingPathComponent(name, isDirectory: true)
        var attempt = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = root.appendingPathComponent("\(name)-\(attempt)", isDirectory: true)
            attempt += 1
        }
        return candidate
    }

    private static func extract(_ zipURL: URL, to destination: URL) throws {
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, destination.path]
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            throw ProjectImportError.extractionFailed(error.localizedDescription)
        }
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            try? FileManager.default.removeItem(at: destination)
            throw ProjectImportError.extractionFailed(message)
        }
    }

    /// Finder's "Compress" wraps the project folder in one extra top-level
    /// directory; unwrap it so the result always points straight at the
    /// folder that holds `fastreport.json`.
    private static func resolveProjectFolder(in extractedFolder: URL) -> URL {
        if ProjectMetadataFile.url(in: extractedFolder) != nil {
            return extractedFolder
        }
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: extractedFolder,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return extractedFolder
        }
        if children.count == 1,
           let only = children.first,
           (try? only.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            return only
        }
        return extractedFolder
    }
}
