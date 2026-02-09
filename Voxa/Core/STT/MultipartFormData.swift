//
//  MultipartFormData.swift
//  Voxa
//
//  HTTP multipart/form-data 工具类
//

import Foundation

/// Multipart/form-data 构建器
struct MultipartFormData {
    /// 边界字符串
    private let boundary: String
    
    /// 表单数据
    private var body = Data()
    
    /// 初始化
    /// - Parameter boundary: 自定义边界字符串 (可选)
    init(boundary: String = UUID().uuidString) {
        self.boundary = boundary
    }
    
    /// 添加文本字段
    /// - Parameters:
    ///   - name: 字段名
    ///   - value: 字段值
    mutating func addTextField(name: String, value: String) {
        appendBoundary()
        appendContentDisposition(name: name)
        appendBlankLine()
        appendString(value)
        appendLineBreak()
    }
    
    /// 添加文件字段
    /// - Parameters:
    ///   - name: 字段名
    ///   - filename: 文件名
    ///   - mimeType: MIME 类型
    ///   - data: 文件数据
    mutating func addFileField(
        name: String,
        filename: String,
        mimeType: String,
        data: Data
    ) {
        appendBoundary()
        appendContentDisposition(name: name, filename: filename)
        appendContentType(mimeType)
        appendBlankLine()
        body.append(data)
        appendLineBreak()
    }
    
    /// 完成构建并返回数据
    /// - Returns: multipart/form-data 数据
    mutating func build() -> Data {
        appendString("--\(boundary)--")
        appendLineBreak()
        return body
    }
    
    /// 获取 Content-Type 头
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    
    // MARK: - Private Methods
    
    private mutating func appendBoundary() {
        appendString("--\(boundary)")
        appendLineBreak()
    }
    
    private mutating func appendContentDisposition(name: String, filename: String? = nil) {
        if let filename = filename {
            appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"")
        } else {
            appendString("Content-Disposition: form-data; name=\"\(name)\"")
        }
        appendLineBreak()
    }
    
    private mutating func appendContentType(_ mimeType: String) {
        appendString("Content-Type: \(mimeType)")
        appendLineBreak()
    }
    
    private mutating func appendBlankLine() {
        appendLineBreak()
    }
    
    private mutating func appendLineBreak() {
        appendString("\r\n")
    }
    
    private mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            body.append(data)
        }
    }
}
