//
//  KeychainService.swift
//  Voxa
//
//  Phase 4 T019: API Key 存入 Keychain，支持从 UserDefaults 一次性迁移
//

import Foundation
import Security

/// Keychain 读写 API Key；首次启动将 UserDefaults 中密钥迁移至 Keychain 并清除
enum KeychainService {

    private static let serviceName = Bundle.main.bundleIdentifier ?? "com.voxa.app"

    enum Key: String, CaseIterable {
        case sttApiKey = "sttApiKey"
        case llmApiKey = "llmApiKey"
    }

    private static let migrationFlagKey = "voxa.apiKey.migratedToKeychain"

    /// 从 UserDefaults 迁移 sttApiKey/llmApiKey 到 Keychain 并清除 UserDefaults（仅执行一次）
    static func migrateFromUserDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrationFlagKey) else { return }

        for key in Key.allCases {
            let value = defaults.string(forKey: key.rawValue) ?? ""
            if !value.isEmpty {
                set(key: key, value: value)
            }
            defaults.removeObject(forKey: key.rawValue)
        }
        defaults.set(true, forKey: migrationFlagKey)
    }

    /// 读取 Keychain 中的值
    static func get(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    /// 写入 Keychain
    static func set(key: Key, value: String) {
        delete(key: key)
        guard !value.isEmpty else { return }
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    /// 删除 Keychain 中的项
    static func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }
}
