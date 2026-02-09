//
//  AudioCapturing.swift
//  Voxa
//
//  音频采集协议定义
//

import Foundation

/// 音频采集协议
/// 定义音频录制的核心接口
protocol AudioCapturing: Sendable {
    /// 是否正在录音
    var isRecording: Bool { get async }
    
    /// 开始录音
    /// - Throws: AudioError
    func startCapture() async throws
    
    /// 停止录音并返回音频数据
    /// - Returns: WAV 格式音频数据
    /// - Throws: AudioError
    func stopCapture() async throws -> Data
    
    /// 获取实时音量数据流 (用于波形动效)
    /// - Returns: 归一化音量值流 (0.0 ~ 1.0)
    func audioLevelStream() async -> AsyncStream<Float>
}
