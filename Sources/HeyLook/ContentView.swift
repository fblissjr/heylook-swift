import SwiftUI

struct ContentView: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 200)
        } detail: {
            ChatView(viewModel: viewModel)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadModel()
        }
    }
}
