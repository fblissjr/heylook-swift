import Foundation
import MLXLMCommon

struct SamplerSettings: Codable, Equatable {
    var temperature: Float = 0.6
    var topP: Float = 1.0
    var maxTokens: Int? = 2048
    var repetitionPenalty: Float? = 1.1

    func toGenerateParameters() -> GenerateParameters {
        GenerateParameters(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: topP,
            repetitionPenalty: repetitionPenalty
        )
    }
}
