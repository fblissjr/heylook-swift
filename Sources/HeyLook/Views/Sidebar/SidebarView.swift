import SwiftUI

struct SidebarView: View {
    @Bindable var viewModel: ChatViewModel

    var body: some View {
        List(selection: $viewModel.selectedConversationId) {
            ForEach(viewModel.conversations) { conversation in
                ConversationRowView(conversation: conversation)
                    .tag(conversation.id)
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteConversation(conversation.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.createNewConversation()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Conversation")
            }
        }
    }
}
