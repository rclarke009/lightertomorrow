import Foundation
import Security

/// Secure keychain manager for storing sensitive data like API keys
class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keychain Operations
    
    /// Store a value in the keychain
    func store(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a value from the keychain
    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete a value from the keychain
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    /// Check if a key exists in the keychain
    func exists(key: String) -> Bool {
        return retrieve(key: key) != nil
    }
}

// MARK: - OpenAI API Key Management

extension KeychainManager {
    /// Store OpenAI API key securely
    func storeOpenAIKey(_ key: String) -> Bool {
        return store(key: "openai_api_key", value: key)
    }
    
    /// Retrieve OpenAI API key
    func getOpenAIKey() -> String? {
        return retrieve(key: "openai_api_key")
    }
    
    /// Delete OpenAI API key
    func deleteOpenAIKey() -> Bool {
        return delete(key: "openai_api_key")
    }
    
    /// Check if OpenAI API key exists
    func hasOpenAIKey() -> Bool {
        return exists(key: "openai_api_key")
    }
}
