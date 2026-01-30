import SwiftUI

struct SamplerSettingsSheet: View {
    @Binding var settings: SamplerSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Sampling Parameters") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", settings.temperature))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.temperature, in: 0...2, step: 0.05)
                        Text("Lower values make output more focused and deterministic")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Top P")
                            Spacer()
                            Text(String(format: "%.2f", settings.topP))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $settings.topP, in: 0...1, step: 0.05)
                        Text("Nucleus sampling: only consider tokens with cumulative probability up to this value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Max Tokens")
                            Spacer()
                            Text(settings.maxTokens.map { "\($0)" } ?? "Unlimited")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: Binding(
                                get: { Double(settings.maxTokens ?? 4096) },
                                set: { settings.maxTokens = Int($0) }
                            ),
                            in: 64...8192,
                            step: 64
                        )
                        Text("Maximum number of tokens to generate")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Repetition Penalty")
                            Spacer()
                            Text(settings.repetitionPenalty.map { String(format: "%.2f", $0) } ?? "Off")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { settings.repetitionPenalty != nil },
                                set: { settings.repetitionPenalty = $0 ? 1.1 : nil }
                            ))
                            .labelsHidden()

                            if settings.repetitionPenalty != nil {
                                Slider(
                                    value: Binding(
                                        get: { Double(settings.repetitionPenalty ?? 1.1) },
                                        set: { settings.repetitionPenalty = Float($0) }
                                    ),
                                    in: 1.0...2.0,
                                    step: 0.05
                                )
                            }
                        }
                        Text("Penalize repeated tokens to reduce repetition")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button("Reset to Defaults") {
                        settings = SamplerSettings()
                    }
                }
            }
            .formStyle(.grouped)

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
        .frame(width: 450, height: 500)
    }
}
