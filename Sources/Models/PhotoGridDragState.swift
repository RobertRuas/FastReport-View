import SwiftUI

@Observable
final class PhotoGridDragState {
    var groupID: PhotoGroup.ID?
    var draggedPhotoID: Photo.ID?
    var startIndex: Int?
    var translationX: CGFloat = 0

    func begin(groupID: PhotoGroup.ID, photoID: Photo.ID, index: Int) {
        self.groupID = groupID
        draggedPhotoID = photoID
        startIndex = index
        translationX = 0
    }

    func update(translationX: CGFloat) {
        self.translationX = translationX
    }

    func reset() {
        groupID = nil
        draggedPhotoID = nil
        startIndex = nil
        translationX = 0
    }
}
