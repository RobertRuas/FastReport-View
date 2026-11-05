import SwiftUI

struct HomeView: View {
    let state: AppState

    var body: some View {
        ProjectListView(state: state)
    }
}
