// MARK: - KeyMonitorError
// Phase 1 基础骨架 — KeyMonitor 错误类型

import Foundation

/// KeyMonitor 可能产生的错误
enum KeyMonitorError: Error, Sendable {
    /// NSEvent 监听器创建失败（通常因缺少 Accessibility 权限）
    case monitorCreationFailed
    /// 监听已在运行中，重复调用 start
    case alreadyMonitoring
}
