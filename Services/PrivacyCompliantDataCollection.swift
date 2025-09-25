import Foundation
import SwiftUI
import CoreData

/// Privacy-compliant data collection service for gathering real human drawing data
class PrivacyCompliantDataCollection: ObservableObject {
    
    // MARK: - Published Properties
    @Published var hasUserConsent: Bool = false
    @Published var dataCollectionEnabled: Bool = false
    @Published var anonymizationLevel: AnonymizationLevel = .full
    @Published var dataRetentionPeriod: TimeInterval = 365 * 24 * 60 * 60 // 1 year
    
    // MARK: - Private Properties
    private let persistenceService: PersistenceService
    private let encryptionService: DataEncryptionService
    private let consentManager: ConsentManager
    
    // MARK: - Data Collection Settings
    private let maxDataPointsPerUser: Int = 1000
    private let dataQualityThreshold: Double = 0.8
    private let anonymizationRequired: Bool = true
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        self.encryptionService = DataEncryptionService()
        self.consentManager = ConsentManager()
        
        loadUserConsentStatus()
    }
    
    // MARK: - Consent Management
    
    /// Request explicit consent for data collection
    func requestDataCollectionConsent() async -> Bool {
        do {
            let consent = try await consentManager.requestConsent(
                purpose: "Improving AI drawing guidance through anonymous stroke analysis",
                dataTypes: ["stroke patterns", "drawing techniques", "performance metrics"],
                retentionPeriod: dataRetentionPeriod,
                anonymization: anonymizationRequired
            )
            
            hasUserConsent = consent.granted
            dataCollectionEnabled = consent.granted && consent.dataSharingEnabled
            
            if consent.granted {
                try await saveConsentRecord(consent)
            }
            
            return consent.granted
        } catch {
            print("Error requesting consent: \(error)")
            return false
        }
    }
    
    /// Withdraw consent and delete user data
    func withdrawConsent() async {
        hasUserConsent = false
        dataCollectionEnabled = false
        
        // Delete all user data
        await deleteUserData()
        
        // Update consent record
        try? await consentManager.updateConsentStatus(granted: false)
    }
    
    // MARK: - Data Collection
    
    /// Collect anonymized drawing data for training
    func collectDrawingData(_ stroke: DrawingStroke, context: DrawingContext) async throws {
        guard hasUserConsent && dataCollectionEnabled else {
            throw DataCollectionError.consentNotGranted
        }
        
        // Validate data quality
        guard try validateDataQuality(stroke) else {
            throw DataCollectionError.insufficientQuality
        }
        
        // Anonymize data
        let anonymizedData = try await anonymizeDrawingData(stroke, context: context)
        
        // Encrypt data
        let encryptedData = try encryptionService.encrypt(anonymizedData)
        
        // Store encrypted data
        try await storeEncryptedData(encryptedData, metadata: createMetadata(context))
        
        // Update collection metrics
        await updateCollectionMetrics()
    }
    
    /// Collect performance metrics for model improvement
    func collectPerformanceMetrics(_ feedback: StrokeFeedback, userProgress: UserProgress) async throws {
        guard hasUserConsent && dataCollectionEnabled else {
            throw DataCollectionError.consentNotGranted
        }
        
        let metrics = PerformanceMetrics(
            accuracy: feedback.accuracy,
            smoothness: feedback.smoothness,
            confidence: feedback.confidence,
            userLevel: userProgress.skillLevel,
            timestamp: Date(),
            anonymizedUserId: generateAnonymizedUserId()
        )
        
        let encryptedMetrics = try encryptionService.encrypt(metrics)
        try await storeEncryptedData(encryptedMetrics, metadata: createMetadata(.performance))
    }
    
    // MARK: - Data Anonymization
    
    private func anonymizeDrawingData(_ stroke: DrawingStroke, context: DrawingContext) async throws -> AnonymizedDrawingData {
        let anonymizedStroke = AnonymizedStroke(
            points: stroke.points.map { point in
                AnonymizedPoint(
                    x: round(point.x * 100) / 100, // Round to 2 decimal places
                    y: round(point.y * 100) / 100,
                    timestamp: point.timestamp,
                    pressure: round(point.pressure * 100) / 100
                )
            },
            duration: stroke.duration,
            boundingBox: stroke.boundingBox,
            anonymizedUserId: generateAnonymizedUserId(),
            context: context.rawValue,
            timestamp: Date()
        )
        
        return AnonymizedDrawingData(stroke: anonymizedStroke)
    }
    
    private func generateAnonymizedUserId() -> String {
        // Generate a consistent but anonymous user ID
        let userDefaults = UserDefaults.standard
        if let existingId = userDefaults.string(forKey: "anonymized_user_id") {
            return existingId
        } else {
            let newId = UUID().uuidString.prefix(8)
            userDefaults.set(String(newId), forKey: "anonymized_user_id")
            return String(newId)
        }
    }
    
    // MARK: - Data Quality Validation
    
    private func validateDataQuality(_ stroke: DrawingStroke) throws -> Bool {
        // Check minimum stroke length
        guard stroke.points.count >= 10 else { return false }
        
        // Check stroke duration
        guard stroke.duration >= 0.5 else { return false }
        
        // Check for meaningful variation in pressure
        let pressureVariance = calculatePressureVariance(stroke.points)
        guard pressureVariance > 0.1 else { return false }
        
        // Check for reasonable stroke complexity
        let complexity = calculateStrokeComplexity(stroke.points)
        guard complexity > 0.3 else { return false }
        
        return true
    }
    
    private func calculatePressureVariance(_ points: [DrawingPoint]) -> Double {
        let pressures = points.map { $0.pressure }
        let mean = pressures.reduce(0, +) / Double(pressures.count)
        let variance = pressures.map { pow($0 - mean, 2) }.reduce(0, +) / Double(pressures.count)
        return sqrt(variance)
    }
    
    private func calculateStrokeComplexity(_ points: [DrawingPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        
        var totalAngleChange: Double = 0
        for i in 1..<points.count - 1 {
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = points[i + 1]
            
            let angle1 = atan2(p2.y - p1.y, p2.x - p1.x)
            let angle2 = atan2(p3.y - p2.y, p3.x - p2.x)
            
            let angleChange = abs(angle2 - angle1)
            totalAngleChange += min(angleChange, 2 * .pi - angleChange)
        }
        
        return totalAngleChange / Double(points.count - 2)
    }
    
    // MARK: - Data Storage
    
    private func storeEncryptedData(_ data: Data, metadata: DataMetadata) async throws {
        let dataRecord = DataCollectionRecord(
            id: UUID(),
            encryptedData: data,
            metadata: metadata,
            timestamp: Date(),
            version: "1.0"
        )
        
        try await persistenceService.saveDataRecord(dataRecord)
    }
    
    private func createMetadata(_ context: DrawingContext) -> DataMetadata {
        return DataMetadata(
            context: context,
            deviceType: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            anonymizedUserId: generateAnonymizedUserId(),
            timestamp: Date()
        )
    }
    
    private func updateCollectionMetrics() async {
        // Update collection statistics
        let count = await persistenceService.getDataRecordCount()
        print("Total anonymized data records: \(count)")
    }
    
    private func deleteUserData() async {
        await persistenceService.deleteAllUserData()
    }
    
    private func loadUserConsentStatus() {
        hasUserConsent = UserDefaults.standard.bool(forKey: "has_user_consent")
        dataCollectionEnabled = UserDefaults.standard.bool(forKey: "data_collection_enabled")
    }
    
    private func saveConsentRecord(_ consent: ConsentRecord) async throws {
        UserDefaults.standard.set(consent.granted, forKey: "has_user_consent")
        UserDefaults.standard.set(consent.dataSharingEnabled, forKey: "data_collection_enabled")
        
        try await persistenceService.saveConsentRecord(consent)
    }
}

// MARK: - Supporting Types

enum DataCollectionError: Error {
    case consentNotGranted
    case insufficientQuality
    case encryptionFailed
    case storageFailed
}

enum AnonymizationLevel {
    case full
    case partial
    case minimal
}

enum DrawingContext: String, CaseIterable {
    case practice = "practice"
    case lesson = "lesson"
    case freeform = "freeform"
    case performance = "performance"
}

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

struct DataMetadata: Codable {
    let context: DrawingContext
    let deviceType: String
    let osVersion: String
    let appVersion: String
    let anonymizedUserId: String
    let timestamp: Date
}

struct DataCollectionRecord: Codable {
    let id: UUID
    let encryptedData: Data
    let metadata: DataMetadata
    let timestamp: Date
    let version: String
}

struct PerformanceMetrics: Codable {
    let accuracy: Double
    let smoothness: Double
    let confidence: Double
    let userLevel: String
    let timestamp: Date
    let anonymizedUserId: String
}
