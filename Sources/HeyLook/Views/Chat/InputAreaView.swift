import SwiftUI
import AppKit

struct InputAreaView: View {
    let isGenerating: Bool
    let isModelLoaded: Bool
    let onSend: (String) -> Void
    let onStop: () -> Void
    let onRegenerate: () -> Void

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 12) {
                // Simple TextField approach with focus state
                TextField("Type a message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .focused($isInputFocused)
                    .onSubmit {
                        if canSend {
                            sendMessage()
                        }
                    }
                    .onAppear {
                        isInputFocused = true
                    }
                    .lineLimit(1...5)

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

/// Custom NSTextView subclass that properly handles key events
class InputTextView: NSTextView {
    var onSubmitHandler: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func keyDown(with event: NSEvent) {
        print("[InputTextView] keyDown: \(event.charactersIgnoringModifiers ?? "nil"), keyCode: \(event.keyCode)")
        // Handle Enter key (but not Shift+Enter)
        if event.keyCode == 36 && !event.modifierFlags.contains(.shift) {
            onSubmitHandler?()
            return
        }
        super.keyDown(with: event)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        print("[InputTextView] insertText: \(insertString)")
        super.insertText(insertString, replacementRange: replacementRange)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        print("[InputTextView] becomeFirstResponder: \(result)")
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        print("[InputTextView] resignFirstResponder: \(result)")
        return result
    }

    func forceFocus() {
        print("[InputTextView] forceFocus called, window: \(window != nil)")
        window?.makeFirstResponder(self)
    }
}

/// Wrapper view that handles click-to-focus
class FocusableScrollView: NSScrollView {
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if let textView = documentView as? InputTextView {
            window?.makeFirstResponder(textView)
        }
    }
}

struct MacTextView: NSViewRepresentable {
    @Binding var text: String
    var onSubmit: () -> Void

    func makeNSView(context: Context) -> FocusableScrollView {
        let scrollView = FocusableScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder

        let contentSize = scrollView.contentSize

        // Create text container first
        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        // Create text view with proper text system
        let textView = InputTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Configure text view
        textView.delegate = context.coordinator
        textView.onSubmitHandler = onSubmit
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .textColor
        textView.backgroundColor = .textBackgroundColor
        textView.insertionPointColor = .textColor

        // Input settings
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true

        // Disable auto-corrections
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false

        textView.textContainerInset = NSSize(width: 4, height: 8)

        scrollView.documentView = textView
        context.coordinator.textView = textView

        // Set initial text
        textView.string = text

        // Observe window becoming key to grab focus
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )

        return scrollView
    }

    func updateNSView(_ scrollView: FocusableScrollView, context: Context) {
        guard let textView = scrollView.documentView as? InputTextView else { return }

        textView.onSubmitHandler = onSubmit

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
        weak var textView: InputTextView?

        init(_ parent: MacTextView) {
            self.parent = parent
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc func windowDidBecomeKey(_ notification: Notification) {
            // When window becomes key, focus the text view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.textView?.forceFocus()
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
