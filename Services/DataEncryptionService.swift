import Foundation
import CryptoKit
import Security

/// Service for encrypting and decrypting user data to ensure privacy
class DataEncryptionService {
    
    // MARK: - Private Properties
    private let keychain = KeychainService()
    private let encryptionKey: SymmetricKey
    
    init() {
        // Get or create encryption key
        if let existingKey = keychain.getEncryptionKey() {
            self.encryptionKey = existingKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            keychain.saveEncryptionKey(newKey)
            self.encryptionKey = newKey
        }
    }
    
    // MARK: - Encryption Methods
    
    /// Encrypt data using AES-GCM
    func encrypt<T: Codable>(_ data: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(data)
        return try encrypt(jsonData)
    }
    
    /// Encrypt raw data
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return encryptedData
    }
    
    /// Decrypt data using AES-GCM
    func decrypt<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let decryptedData = try decrypt(encryptedData)
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    /// Decrypt raw data
    func decrypt(_ encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    // MARK: - Data Anonymization
    
    /// Anonymize drawing data by removing identifying information
    func anonymizeDrawingData(_ stroke: DrawingStroke) -> AnonymizedDrawingData {
        let anonymizedPoints = stroke.points.map { point in
            AnonymizedPoint(
                x: round(point.x * 100) / 100, // Round to 2 decimal places
                y: round(point.y * 100) / 100,
                timestamp: point.timestamp,
                pressure: round(point.pressure * 100) / 100
            )
        }
        
        let anonymizedStroke = AnonymizedStroke(
            points: anonymizedPoints,
            duration: stroke.duration,
            boundingBox: stroke.boundingBox,
            anonymizedUserId: generateAnonymousUserId(),
            context: "drawing",
            timestamp: Date()
        )
        
        return AnonymizedDrawingData(stroke: anonymizedStroke)
    }
    
    /// Generate a consistent anonymous user ID
    private func generateAnonymousUserId() -> String {
        let userDefaults = UserDefaults.standard
        if let existingId = userDefaults.string(forKey: "anonymous_user_id") {
            return existingId
        } else {
            let newId = UUID().uuidString.prefix(8)
            userDefaults.set(String(newId), forKey: "anonymous_user_id")
            return String(newId)
        }
    }
    
    // MARK: - Data Hashing
    
    /// Create a hash of data for integrity checking
    func createHash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify data integrity using hash
    func verifyIntegrity(_ data: Data, expectedHash: String) -> Bool {
        let actualHash = createHash(data)
        return actualHash == expectedHash
    }
}

// MARK: - Keychain Service

class KeychainService {
    
    private let service = "com.sketchai.encryption"
    private let keyTag = "encryption_key"
    
    /// Save encryption key to keychain
    func saveEncryptionKey(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Failed to save encryption key to keychain: \(status)")
            return
        }
    }
    
    /// Get encryption key from keychain
    func getEncryptionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            return nil
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Delete encryption key from keychain
    func deleteEncryptionKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: keyTag
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Error Types

enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case keychainError
}

// MARK: - Data Types

struct AnonymizedDrawingData: Codable {
    let stroke: AnonymizedStroke
}

struct AnonymizedStroke: Codable {
    let points: [AnonymizedPoint]
    let duration: TimeInterval
    let boundingBox: CGRect
    let anonymizedUserId: String
    let context: String
    let timestamp: Date
}

struct AnonymizedPoint: Codable {
    let x: Double
    let y: Double
    let timestamp: TimeInterval
    let pressure: Double
}
