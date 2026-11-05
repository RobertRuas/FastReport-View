import Foundation

/// The old FastReport app ships maps as editable JSON; this minimalist app
/// only needs to read an already-organized project back in the right order,
/// so the two known report maps are declared directly instead of loading and
/// validating JSON files.
enum MapCatalog {
    static func map(id: String) -> ProjectMap? {
        maps[id]
    }

    private static let maps: [String: ProjectMap] = {
        Dictionary(uniqueKeysWithValues: [inspectionT24, tendonsRetrofit].map { ($0.id, $0) })
    }()

    private static let inspectionT24 = ProjectMap(
        id: "inspection-t24",
        slots: [
            MapSlot(folder: "Inbox", isInbox: true),
            MapSlot(folder: "General"),
            MapSlot(folder: "Trash", isTrash: true)
        ] + (1...24).map { MapSlot(folder: "T\($0)") }
    )

    private static let tendonsRetrofit = ProjectMap(
        id: "tendons-retrofit",
        slots: [
            MapSlot(folder: "Inbox", isInbox: true),
            MapSlot(folder: "General"),
            MapSlot(folder: "Trash", isTrash: true),
            MapSlot(folder: "C12"),
            MapSlot(folder: "C25")
        ] + ["C12", "C25"].flatMap { group in
            (1...24).map { MapSlot(folder: String(format: "T%02d", $0), group: group) }
        }
    )
}
