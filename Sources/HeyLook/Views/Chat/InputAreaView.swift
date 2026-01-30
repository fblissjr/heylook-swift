import SwiftUI
import AppKit

struct InputAreaView: View {
    let isGenerating: Bool
    let isModelLoaded: Bool
    let onSend: (String) -> Void
    let onStop: () -> Void
    let onRegenerate: () -> Void

    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                // Use NSViewRepresentable for reliable text input
                MacTextView(text: $inputText, onSubmit: {
                    if canSend {
                        sendMessage()
                    }
                })
                .frame(minHeight: 36, maxHeight: 120)

                VStack(spacing: 8) {
                    if isGenerating {
                        Button {
                            onStop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .help("Stop Generation")
                    } else {
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(canSend ? .blue : .secondary)
                        .disabled(!canSend)
                        .help("Send Message")

                        Button {
                            onRegenerate()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .disabled(!isModelLoaded)
                        .help("Regenerate Last Response")
                    }
                }
            }

            if !isModelLoaded {
                HStack {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Loading model...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isModelLoaded
            && !isGenerating
    }

    private func sendMessage() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        inputText = ""
        onSend(content)
    }
}

// MARK: - macOS Native Text View

struct MacTextView: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 8)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        // Make it first responder on next run loop
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacTextView

        init(_ parent: MacTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Check for Shift+Enter to insert newline, otherwise submit
                if NSEvent.modifierFlags.contains(.shift) {
                    return false // Let the default behavior insert a newline
                } else {
                    parent.onSubmit()
                    return true // We handled it
                }
            }
            return false
        }
    }
}
