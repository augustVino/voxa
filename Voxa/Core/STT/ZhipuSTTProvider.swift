//
//  ZhipuSTTProvider.swift
//  Voxa
//
//  智谱 GLM-ASR-2512 语音识别服务提供商
//

import Foundation

/// 智谱 GLM-ASR-2512 STT 服务提供商
actor ZhipuSTTProvider: STTProvider {
    // MARK: - Configuration

    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let timeout: TimeInterval

    // MARK: - Initialization

    init(
        apiKey: String,
        baseURL: String = "https://open.bigmodel.cn/api/paas/v4/audio/transcriptions",
        model: String = "glm-asr-2512",
        timeout: TimeInterval = 30.0
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.timeout = timeout
    }

    // MARK: - STTProvider

    func transcribe(
        audioData: Data,
        streaming: Bool = false,
        customWords: [String]? = nil
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw STTError.missingAPIKey
        }

        // 验证音频数据
        try validateAudioData(audioData)

        print("[ZhipuSTT] 开始语音识别 (模式: \(streaming ? "流式" : "非流式"), 大小: \(audioData.count) 字节)")

        if streaming {
            // 流式模式:收集所有增量结果
            var fullText = ""
            let stream = try await transcribeStreaming(audioData: audioData, customWords: customWords)

            for await partialText in stream {
                fullText += partialText // 累加增量文本 (delta)
            }

            print("[ZhipuSTT] 流式识别最终结果: \(fullText)")
            return fullText
        } else {
            // 非流式模式:直接返回完整结果
            return try await performNonStreamingRequest(
                audioData: audioData,
                customWords: customWords
            )
        }
    }

    func transcribeStreaming(
        audioData: Data,
        customWords: [String]? = nil
    ) async throws -> AsyncStream<String> {
        guard !apiKey.isEmpty else {
            throw STTError.missingAPIKey
        }

        // 验证音频数据
        try validateAudioData(audioData)

        print("[ZhipuSTT] 开始流式语音识别 (大小: \(audioData.count) 字节)")

        return AsyncStream { continuation in
            Task {
                do {
                    try await self.performStreamingRequest(
                        audioData: audioData,
                        customWords: customWords,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    print("[ZhipuSTT] ❌ 流式识别失败: \(error)")
                    continuation.finish()
                    throw error
                }
            }
        }
    }

    // MARK: - Private Methods

    /// 验证音频数据
    private func validateAudioData(_ audioData: Data) throws {
        // 检查文件大小 (最大 25MB)
        let maxSize = 25 * 1024 * 1024
        guard audioData.count <= maxSize else {
            throw STTError.invalidAudioFile("文件大小超过 25MB 限制")
        }

        // 检查最小大小
        guard audioData.count > 100 else {
            throw STTError.invalidAudioFile("音频文件过小")
        }
    }

    /// 执行非流式请求
    private func performNonStreamingRequest(
        audioData: Data,
        customWords: [String]?
    ) async throws -> String {
        let request = try buildRequest(
            audioData: audioData,
            streaming: false,
            customWords: customWords
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        try validateHTTPResponse(response)

        // 打印原始响应体
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("[ZhipuSTT] 📦 非流式原始响应: \(rawJSON)")
        }

        // 解析响应
        let result = try JSONDecoder().decode(TranscriptionResponse.self, from: data)

        guard let text = result.text, !text.isEmpty else {
            throw STTError.invalidResponse("识别结果为空")
        }

        print("[ZhipuSTT] ✅ 识别完成: \(text)")
        return text
    }

    /// 执行流式请求
    private func performStreamingRequest(
        audioData: Data,
        customWords: [String]?,
        continuation: AsyncStream<String>.Continuation
    ) async throws {
        let request = try buildRequest(
            audioData: audioData,
            streaming: true,
            customWords: customWords
        )

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        try validateHTTPResponse(response)

        var buffer = Data()

        // 逐行读取 SSE 流
        for try await byte in asyncBytes {
            buffer.append(byte)

            // 检查是否有完整的行
            if let newlineIndex = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = buffer.prefix(upTo: newlineIndex)
                buffer.removeSubrange(...newlineIndex)

                if let line = String(data: lineData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if !line.isEmpty {
                        print("[ZhipuSTT] 📦 SSE 行: \(line)")
                    }
                    try processStreamLine(line, continuation: continuation)
                }
            }
        }
    }

    /// 处理流式响应行
    private func processStreamLine(
        _ line: String,
        continuation: AsyncStream<String>.Continuation
    ) throws {
        // SSE 格式: data: {...}
        guard line.hasPrefix("data: ") else {
            return
        }

        let jsonString = String(line.dropFirst(6))

        // 检查结束标记
        if jsonString == "[DONE]" {
            print("[ZhipuSTT] ✅ 流式识别完成")
            return
        }

        // 解析 JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            return
        }

        let chunk = try JSONDecoder().decode(StreamingChunk.self, from: jsonData)

        // 智谱 GLM-ASR 流式格式: 顶层 delta 为增量文本 (type == transcript.text.delta)
        if let delta = chunk.delta, !delta.isEmpty {
            print("[ZhipuSTT] 📝 收到文本片段: \(delta)")
            continuation.yield(delta)
        }
    }

    /// 构建 HTTP 请求
    private func buildRequest(
        audioData: Data,
        streaming: Bool,
        customWords: [String]?
    ) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw STTError.invalidResponse("无效的 API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // 构建 multipart/form-data
        var formData = MultipartFormData()

        // 添加音频文件
        formData.addFileField(
            name: "file",
            filename: "audio.wav",
            mimeType: "audio/wav",
            data: audioData
        )

        // 添加模型参数
        formData.addTextField(name: "model", value: model)

        // 添加流式参数
        if streaming {
            formData.addTextField(name: "stream", value: "true")
        }

        // 添加自定义词典 (Phase 3 功能)
        if let customWords = customWords, !customWords.isEmpty {
            let wordsJSON = try JSONEncoder().encode(customWords)
            if let wordsString = String(data: wordsJSON, encoding: .utf8) {
                formData.addTextField(name: "custom_words", value: wordsString)
            }
        }

        let bodyData = formData.build()
        request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("\(bodyData.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = bodyData

        return request
    }

    /// 验证 HTTP 响应
    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw STTError.invalidResponse("无效的 HTTP 响应")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw STTError.unauthorized
        case 429:
            throw STTError.rateLimitExceeded
        case 500...599:
            throw STTError.serviceUnavailable(statusCode: httpResponse.statusCode)
        default:
            throw STTError.invalidResponse("HTTP \(httpResponse.statusCode)")
        }
    }
}

// MARK: - Response Models

/// 非流式识别响应
private struct TranscriptionResponse: Codable {
    let text: String?
    let duration: Double?
}

/// 流式识别数据块 (智谱 GLM-ASR 实际格式)
/// 增量: {"delta":"大","type":"transcript.text.delta"} 完成: {"text":"大黄你好","type":"transcript.text.done"}
private struct StreamingChunk: Codable {
    let id: String?
    let created: Int?
    let model: String?
    /// 增量文本 (type == transcript.text.delta)
    let delta: String?
    /// 事件类型
    let type: String?
    /// 最终完整文本 (type == transcript.text.done)
    let text: String?
    let usage: StreamUsage?
}

private struct StreamUsage: Codable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}
