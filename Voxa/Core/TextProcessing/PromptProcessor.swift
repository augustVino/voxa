//
//  PromptProcessor.swift
//  Voxa
//
//  Phase 3: 调用智谱 GLM-4 对话 API 对人设润色文本，超时 30s
//

import Foundation

/// 润色请求/响应结构（智谱 v4/chat/completions 兼容）
private struct ChatRequest: Encodable {
    let model: String
    let messages: [[String: String]]
    let stream: Bool = false
}

private struct ChatResponse: Decodable {
    let choices: [Choice]?
    struct Choice: Decodable {
        let message: Message?
        struct Message: Decodable {
            let content: String?
        }
    }
}

/// 润色处理器协议（便于测试注入 Mock）
protocol PromptProcessing: Sendable {
    func process(text: String, systemPrompt: String) async throws -> String
}

/// LLM 润色处理器：依赖 apiKey/baseURL/model，调用智谱对话 API
final class PromptProcessor: PromptProcessing, Sendable {
    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let timeout: TimeInterval = 30.0

    init(apiKey: String, baseURL: String, model: String) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
    }

    /// 使用 systemPrompt（人设 prompt）对文本进行润色；超时 30s，空或异常视为失败
    func process(text: String, systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw TextProcessingError.llmUnavailable("未配置 API Key")
        }

        let userContent = "请对以下语音转写文本进行润色处理：\n\n\(text)"

        let body = ChatRequest(
            model: model,
            messages: [
                ["role": "system", "content": systemPrompt.isEmpty ? "你是一个文本润色助手。" : systemPrompt],
                ["role": "user", "content": userContent]
            ]
        )

        guard let url = URL(string: baseURL) else {
            throw TextProcessingError.llmUnavailable("无效的 Base URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .timedOut {
                throw TextProcessingError.llmUnavailable("请求超时")
            }
            throw TextProcessingError.llmUnavailable("网络错误: \(urlError.localizedDescription)")
        } catch {
            throw TextProcessingError.llmUnavailable("网络错误: \(error.localizedDescription)")
        }

        guard let http = response as? HTTPURLResponse else {
            throw TextProcessingError.llmUnavailable("无效响应")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw TextProcessingError.llmUnavailable("HTTP \(http.statusCode)")
        }

        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw TextProcessingError.llmUnavailable("响应解析失败")
        }

        guard let content = decoded.choices?.first?.message?.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw TextProcessingError.llmUnavailable("润色结果为空")
        }
        return content
    }
}
