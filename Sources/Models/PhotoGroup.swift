import Foundation

struct PhotoGroup: Identifiable, Equatable {
    let id: String
    let title: String
    var photos: [Photo]
}
