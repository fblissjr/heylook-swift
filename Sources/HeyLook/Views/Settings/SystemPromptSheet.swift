import SwiftUI

struct SystemPromptSheet: View {
    @Binding var systemPrompt: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("System Prompt")
                    .font(.headline)

                Text("Set instructions that guide the assistant's behavior throughout the conversation.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $systemPrompt)
                    .font(.body)
                    .frame(minHeight: 200)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Text("\(systemPrompt.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !systemPrompt.isEmpty {
                        Button("Clear") {
                            systemPrompt = ""
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding()

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}
