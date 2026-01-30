import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let onEdit: (UUID, String) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editedContent = ""

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isUser {
                roleIcon
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                if isEditing {
                    editingView
                } else {
                    contentView
                }

                if let metrics = message.metrics, !message.isStreaming {
                    metricsView(metrics)
                }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if isUser {
                roleIcon
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private var roleIcon: some View {
        Image(systemName: isUser ? "person.circle.fill" : "cpu.fill")
            .font(.title2)
            .foregroundStyle(isUser ? .blue : .green)
    }

    private var contentView: some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            Text(message.content.isEmpty && message.isStreaming ? "..." : message.content)
                .textSelection(.enabled)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isUser ? Color.blue.opacity(0.15) : Color.secondary.opacity(0.1))
                )

            if isHovering && !message.isStreaming && message.role == .user {
                Button {
                    editedContent = message.content
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var editingView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            TextEditor(text: $editedContent)
                .font(.body)
                .frame(minHeight: 60, maxHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: 1)
                )

            HStack {
                Button("Cancel") {
                    isEditing = false
                    editedContent = ""
                }
                .buttonStyle(.bordered)

                Button("Save & Regenerate") {
                    onEdit(message.id, editedContent)
                    isEditing = false
                    editedContent = ""
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func metricsView(_ metrics: Message.Metrics) -> some View {
        HStack(spacing: 12) {
            Label(
                String(format: "%.1f tok/s", metrics.tokensPerSecond),
                systemImage: "speedometer"
            )

            Label(
                "\(metrics.generationTokenCount) tokens",
                systemImage: "number"
            )
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
}
