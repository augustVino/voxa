//
//  OpenAIWhisperProvider.swift
//  Voxa
//
//  OpenAI Whisper STT 服务提供商
//

import Foundation

/// OpenAI Whisper STT 服务提供商
/// 注意: OpenAI Whisper API 不支持流式识别
actor OpenAIWhisperProvider: STTProvider {

    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let timeout: TimeInterval

    init(
        apiKey: String,
        baseURL: String = "https://api.openai.com/v1/audio/transcriptions",
        model: String = "whisper-1",
        timeout: TimeInterval = 30.0
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.timeout = timeout
    }

    func transcribe(
        audioData: Data,
        streaming: Bool = false,
        customWords: [String]? = nil
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw STTError.missingAPIKey
        }

        // OpenAI Whisper 不支持流式，忽略 streaming 参数
        try validateAudioData(audioData)

        print("[OpenAIWhisper] 开始语音识别 (大小: \(audioData.count) 字节)")

        let request = try buildRequest(audioData: audioData)
        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        let result = try JSONDecoder().decode(WhisperResponse.self, from: data)

        guard !result.text.isEmpty else {
            throw STTError.invalidResponse("识别结果为空")
        }

        print("[OpenAIWhisper] ✅ 识别完成: \(result.text)")
        return result.text
    }

    func transcribeStreaming(
        audioData: Data,
        customWords: [String]? = nil
    ) async throws -> AsyncStream<String> {
        // OpenAI Whisper 不支持流式，返回非流式结果
        let text = try await transcribe(audioData: audioData, streaming: false)

        return AsyncStream { continuation in
            continuation.yield(text)
            continuation.finish()
        }
    }

    // MARK: - Private Methods

    private func validateAudioData(_ audioData: Data) throws {
        let maxSize = 25 * 1024 * 1024  // 25MB
        guard audioData.count <= maxSize else {
            throw STTError.invalidAudioFile("文件大小超过 25MB 限制")
        }
        guard audioData.count > 100 else {
            throw STTError.invalidAudioFile("音频文件过小")
        }
    }

    private func buildRequest(audioData: Data) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw STTError.invalidResponse("无效的 API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var formData = MultipartFormData()
        formData.addFileField(name: "file", filename: "audio.wav", mimeType: "audio/wav", data: audioData)
        formData.addTextField(name: "model", value: model)
        formData.addTextField(name: "response_format", value: "text")

        let bodyData = formData.build()
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        return request
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw STTError.invalidResponse("无效的 HTTP 响应")
        }

        switch httpResponse.statusCode {
        case 200...299: return
        case 401: throw STTError.unauthorized
        case 429: throw STTError.rateLimitExceeded
        case 500...599: throw STTError.serviceUnavailable(statusCode: httpResponse.statusCode)
        default: throw STTError.invalidResponse("HTTP \(httpResponse.statusCode)")
        }
    }
}

// MARK: - Response Models

private struct WhisperResponse: Codable {
    let text: String
}
