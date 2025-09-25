@preconcurrency import Foundation
import SwiftUI
import MessageUI

// MARK: - User-Generated Content Safety Manager
// Implements App Store required safety features for user-generated content

@MainActor
class UGCSafetyManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isReportingContent = false
    @Published var lastReportSubmitted: Date?
    @Published var blockedUserIds: Set<String> = []
    
    // MARK: - Reporting System
    private let reportingService = ContentReportingService()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Configuration
    private struct Config {
        static let reportCooldownMinutes = 5 // Prevent spam reporting
        static let maxReportsPerDay = 10
        static let reportSubmissionTimeout: TimeInterval = 30
        static let developerEmail = UGCWebhookConfiguration.fallbackEmail
        
        // PRODUCTION: Use dynamic configuration based on environment
        static var webhookConfig: UGCWebhookConfiguration.WebhookConfig {
            return UGCWebhookConfiguration.current
        }
    }
    
    init() {
        loadBlockedUsers()
    }
    
    // MARK: - Content Reporting
    func reportContent(
        contentId: String,
        contentType: UGCContentType,
        reason: ReportReason,
        additionalDetails: String? = nil,
        completion: @escaping (Result<Void, ReportingError>) -> Void
    ) {
        
        // Check rate limiting
        guard canSubmitReport() else {
            completion(.failure(.rateLimited))
            return
        }
        
        isReportingContent = true
        
        let report = ContentReport(
            id: UUID().uuidString,
            contentId: contentId,
            contentType: contentType,
            reason: reason,
            additionalDetails: additionalDetails,
            reporterDeviceId: getDeviceIdentifier(),
            timestamp: Date(),
            appVersion: getCurrentAppVersion()
        )
        
        Task {
            do {
                try await submitReport(report)
                
                await MainActor.run {
                    self.isReportingContent = false
                    self.lastReportSubmitted = Date()
                    completion(.success(()))
                }
                
                // Track analytics
                trackReportSubmission(report: report)
                
            } catch {
                await MainActor.run {
                    self.isReportingContent = false
                    completion(.failure(.submissionFailed(error)))
                }
            }
        }
    }
    
    private func submitReport(_ report: ContentReport) async throws {
        // Primary submission: Send to developer backend
        do {
            try await submitToBackend(report)
        } catch {
            print("⚠️ Backend submission failed, falling back to email: \(error)")
            
            // Fallback: Email submission
            try await submitViaEmail(report)
        }
    }
    
    private func submitToBackend(_ report: ContentReport) async throws {
        let webhookConfig = Config.webhookConfig
        
        guard let url = URL(string: webhookConfig.webhookURL) else {
            throw ReportingError.invalidConfiguration
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("SketchAI-iOS/\(getCurrentAppVersion())", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(webhookConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = webhookConfig.timeout
        
        // Security headers to prevent replay attacks
        request.setValue("\(Date().timeIntervalSince1970)", forHTTPHeaderField: "X-Timestamp")
        request.setValue(report.id, forHTTPHeaderField: "X-Report-ID")
        
        // Enhanced JSON encoding with error handling
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let reportData = try encoder.encode(report)
        request.httpBody = reportData
        
        // Submit with retry logic
        var lastError: Error?
        for attempt in 1...webhookConfig.maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ReportingError.serverError
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    // Success - log response for debugging
                    if let responseData = data,
                       let responseJson = try? JSONSerialization.jsonObject(with: responseData) {
                        print("✅ Report submitted successfully: \(responseJson)")
                    } else {
                        print("✅ Report submitted successfully to backend")
                    }
                    return
                    
                case 429:
                    // Rate limited - don't retry
                    throw ReportingError.rateLimited
                    
                case 401, 403:
                    // Authentication failed - don't retry
                    throw ReportingError.invalidConfiguration
                    
                case 500...599:
                    // Server error - retry
                    throw ReportingError.serverError
                    
                default:
                    throw ReportingError.serverError
                }
                
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if case ReportingError.rateLimited = error,
                   case ReportingError.invalidConfiguration = error {
                    throw error
                }
                
                // Wait before retry (exponential backoff)
                if attempt < webhookConfig.maxRetries {
                    let delay = TimeInterval(attempt * attempt) // 1s, 4s, 9s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    print("⚠️ Retrying webhook submission (attempt \(attempt + 1)/\(webhookConfig.maxRetries))")
                }
            }
        }
        
        // All retries failed
        throw lastError ?? ReportingError.serverError
    }
    
    private func submitViaEmail(_ report: ContentReport) async throws {
        // Format report for email
        let emailBody = formatReportForEmail(report)
        let subject = "Content Report - \(report.reason.displayName)"
        
        // Store for manual email sending
        await MainActor.run {
            self.promptEmailSubmission(subject: subject, body: emailBody)
        }
    }
    
    private func formatReportForEmail(_ report: ContentReport) -> String {
        return """
        Content Report - SketchAI iOS App
        ================================
        
        Report ID: \(report.id)
        Timestamp: \(ISO8601DateFormatter().string(from: report.timestamp))
        
        Content Details:
        - Content ID: \(report.contentId)
        - Content Type: \(report.contentType.displayName)
        - Report Reason: \(report.reason.displayName)
        
        Additional Details:
        \(report.additionalDetails ?? "None provided")
        
        Technical Information:
        - App Version: \(report.appVersion)
        - Device Identifier: \(report.reporterDeviceId)
        
        Please review and take appropriate action within 24 hours as required by App Store guidelines.
        """
    }
    
    // MARK: - User Blocking
    func blockUser(_ userId: String, completion: @escaping (Result<Void, BlockingError>) -> Void) {
        guard !blockedUserIds.contains(userId) else {
            completion(.failure(.alreadyBlocked))
            return
        }
        
        blockedUserIds.insert(userId)
        saveBlockedUsers()
        
        // Notify other parts of the app
        NotificationCenter.default.post(
            name: .userWasBlocked,
            object: nil,
            userInfo: ["userId": userId]
        )
        
        completion(.success(()))
        
        print("🚫 User blocked: \(userId)")
    }
    
    func unblockUser(_ userId: String, completion: @escaping (Result<Void, BlockingError>) -> Void) {
        guard blockedUserIds.contains(userId) else {
            completion(.failure(.notBlocked))
            return
        }
        
        blockedUserIds.remove(userId)
        saveBlockedUsers()
        
        // Notify other parts of the app
        NotificationCenter.default.post(
            name: .userWasUnblocked,
            object: nil,
            userInfo: ["userId": userId]
        )
        
        completion(.success(()))
        
        print("✅ User unblocked: \(userId)")
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUserIds.contains(userId)
    }
    
    // MARK: - Content Filtering
    func shouldHideContent(authorId: String) -> Bool {
        return isUserBlocked(authorId)
    }
    
    func filterUserGeneratedContent<T: UGCContent>(_ content: [T]) -> [T] {
        return content.filter { !shouldHideContent(authorId: $0.authorId ?? "") }
    }
    
    // MARK: - Rate Limiting
    private func canSubmitReport() -> Bool {
        // Check cooldown period
        if let lastReport = lastReportSubmitted {
            let timeSinceLastReport = Date().timeIntervalSince(lastReport)
            let cooldownSeconds = Config.reportCooldownMinutes * 60
            
            if timeSinceLastReport < TimeInterval(cooldownSeconds) {
                return false
            }
        }
        
        // Check daily limit
        let reportsToday = getReportsSubmittedToday()
        return reportsToday < Config.maxReportsPerDay
    }
    
    private func getReportsSubmittedToday() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let reportsKey = "reports_\(today.timeIntervalSince1970)"
        return userDefaults.integer(forKey: reportsKey)
    }
    
    private func incrementDailyReportCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let reportsKey = "reports_\(today.timeIntervalSince1970)"
        let currentCount = userDefaults.integer(forKey: reportsKey)
        userDefaults.set(currentCount + 1, forKey: reportsKey)
    }
    
    // MARK: - Persistence
    private func saveBlockedUsers() {
        let blockedArray = Array(blockedUserIds)
        userDefaults.set(blockedArray, forKey: "blockedUserIds")
    }
    
    private func loadBlockedUsers() {
        if let blockedArray = userDefaults.array(forKey: "blockedUserIds") as? [String] {
            blockedUserIds = Set(blockedArray)
        }
    }
    
    // MARK: - Email Composition
    private func promptEmailSubmission(subject: String, body: String) {
        DispatchQueue.main.async {
            if MFMailComposeViewController.canSendMail() {
                let mailComposer = MFMailComposeViewController()
                mailComposer.setToRecipients([Config.developerEmail])
                mailComposer.setSubject(subject)
                mailComposer.setMessageBody(body, isHTML: false)
                
                // Present mail composer
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(mailComposer, animated: true)
                }
            } else {
                // Fallback: Copy to clipboard and show instructions
                UIPasteboard.general.string = body
                self.showEmailFallbackAlert(subject: subject)
            }
        }
    }
    
    private func showEmailFallbackAlert(subject: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Report Copied",
                message: "Your report has been copied to the clipboard. Please email it to \(Config.developerEmail) with subject '\(subject)'",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getDeviceIdentifier() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    private func getCurrentAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    }
    
    private func trackReportSubmission(report: ContentReport) {
        let event = [
            "event": "content_report_submitted",
            "content_type": report.contentType.rawValue,
            "reason": report.reason.rawValue,
            "timestamp": report.timestamp.timeIntervalSince1970
        ] as [String: Any]
        
        print("📊 Content Report: \(event)")
        // Integrate with analytics service
    }
}

// MARK: - Supporting Data Structures

struct ContentReport: Codable {
    let id: String
    let contentId: String
    let contentType: UGCContentType
    let reason: ReportReason
    let additionalDetails: String?
    let reporterDeviceId: String
    let timestamp: Date
    let appVersion: String
}

enum UGCContentType: String, CaseIterable, Codable {
    case drawing = "drawing"
    case profile = "profile"
    case comment = "comment"
    case gallery = "gallery"
    
    var displayName: String {
        switch self {
        case .drawing: return "Drawing"
        case .profile: return "User Profile"
        case .comment: return "Comment"
        case .gallery: return "Gallery Item"
        }
    }
}

enum ReportReason: String, CaseIterable, Codable {
    case inappropriate = "inappropriate"
    case spam = "spam"
    case harassment = "harassment"
    case violence = "violence"
    case hateSpeech = "hate_speech"
    case sexualContent = "sexual_content"
    case copyrightViolation = "copyright"
    case impersonation = "impersonation"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .inappropriate: return "Inappropriate Content"
        case .spam: return "Spam"
        case .harassment: return "Harassment"
        case .violence: return "Violence"
        case .hateSpeech: return "Hate Speech"
        case .sexualContent: return "Sexual Content"
        case .copyrightViolation: return "Copyright Violation"
        case .impersonation: return "Impersonation"
        case .other: return "Other"
        }
    }
    
    var description: String {
        switch self {
        case .inappropriate: return "Content that is offensive or inappropriate"
        case .spam: return "Unwanted or repetitive content"
        case .harassment: return "Bullying or harassment of users"
        case .violence: return "Content depicting violence"
        case .hateSpeech: return "Content targeting individuals or groups"
        case .sexualContent: return "Inappropriate sexual content"
        case .copyrightViolation: return "Content that violates copyright"
        case .impersonation: return "Pretending to be someone else"
        case .other: return "Other policy violations"
        }
    }
}

// MARK: - Protocol for UGC Content
protocol UGCContent {
    var ugcId: String { get }
    var authorId: String? { get }
    var createdDate: Date { get }
}

// MARK: - Error Types
enum ReportingError: Error, LocalizedError {
    case rateLimited
    case submissionFailed(Error)
    case invalidConfiguration
    case serverError
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .rateLimited:
            return "You've submitted reports recently. Please wait before submitting another."
        case .submissionFailed(let error):
            return "Failed to submit report: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Reporting system is not properly configured"
        case .serverError:
            return "Server error occurred while submitting report"
        case .networkUnavailable:
            return "Network connection required to submit report"
        }
    }
}

enum BlockingError: Error, LocalizedError {
    case alreadyBlocked
    case notBlocked
    case invalidUserId
    
    var errorDescription: String? {
        switch self {
        case .alreadyBlocked:
            return "User is already blocked"
        case .notBlocked:
            return "User is not currently blocked"
        case .invalidUserId:
            return "Invalid user identifier"
        }
    }
}

// MARK: - Content Reporting Service
private class ContentReportingService {
    
    func submitReport(_ report: ContentReport) async throws {
        // This would integrate with your backend service
        // For now, implementing basic validation
        
        guard !report.contentId.isEmpty else {
            throw ReportingError.invalidConfiguration
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("📨 Report submitted: \(report.id)")
    }
}

// MARK: - Notification Extensions
extension NSNotification.Name {
    static let userWasBlocked = NSNotification.Name("UserWasBlocked")
    static let userWasUnblocked = NSNotification.Name("UserWasUnblocked")
    static let contentWasReported = NSNotification.Name("ContentWasReported")
}

// MARK: - UserDrawing UGC Conformance
extension UserDrawing: UGCContent {
    var ugcId: String {
        return self.id.uuidString
    }
    
    // Now uses the actual authorId field from the model
    // This enables proper blocking functionality
    
    // createdDate is already defined in UserDrawing struct
}
