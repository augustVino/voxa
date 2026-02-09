//
//  STTProvider.swift
//  Voxa
//
//  语音转文字服务提供商协议定义
//

import Foundation

/// STT 服务提供商协议
/// 定义统一的语音转文字接口,支持多种 STT 服务商实现
protocol STTProvider: Sendable {
    /// 非流式语音识别
    /// - Parameters:
    ///   - audioData: WAV 格式音频数据
    ///   - streaming: 是否使用流式模式 (默认 false)
    ///   - customWords: 自定义词典 (可选,Phase 3 实现)
    /// - Returns: 识别结果文本
    /// - Throws: STTError
    func transcribe(
        audioData: Data,
        streaming: Bool,
        customWords: [String]?
    ) async throws -> String
    
    /// 流式语音识别
    /// - Parameters:
    ///   - audioData: WAV 格式音频数据
    ///   - customWords: 自定义词典 (可选,Phase 3 实现)
    /// - Returns: 部分识别结果流
    /// - Throws: STTError
    func transcribeStreaming(
        audioData: Data,
        customWords: [String]?
    ) async throws -> AsyncStream<String>
}

// MARK: - Default Parameter Values

extension STTProvider {
    /// 非流式识别 (默认参数)
    func transcribe(audioData: Data) async throws -> String {
        try await transcribe(audioData: audioData, streaming: false, customWords: nil)
    }
    
    /// 流式识别 (默认参数)
    func transcribeStreaming(audioData: Data) async throws -> AsyncStream<String> {
        try await transcribeStreaming(audioData: audioData, customWords: nil)
    }
}
