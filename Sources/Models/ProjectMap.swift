import Foundation

struct ProjectMap: Equatable, Identifiable {
    let id: String
    let slots: [MapSlot]

    /// Slots in report order, excluding Inbox (unclassified) and Trash — the
    /// folders a finished project actually shows.
    var displaySlots: [MapSlot] {
        slots.filter { !$0.isTrash && !$0.isInbox }
    }
}
