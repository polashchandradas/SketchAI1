import Foundation
import SwiftUI
import UIKit

// MARK: - Feature Gate Manager
class FeatureGateManager: ObservableObject {
    
    // MARK: - Dependencies
    private let subscriptionManager: ProductionSubscriptionManager
    
    // MARK: - Published Properties
    @Published var shouldShowPaywall = false
    @Published var paywallContext: PaywallContext = .general
    
    // MARK: - Configuration
    private struct Config {
        static let freeExportsPerWeek = 5
        static let freeAdvancedLessonsPerWeek = 1
        static let exportWatermarkText = "Created with SketchAI"
    }
    
    init(subscriptionManager: ProductionSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }
    
    // MARK: - Core Feature Gates with Optimized UX Timing
    
    @MainActor func canAccessLesson(_ lesson: Lesson) -> FeatureGateResult {
        // Check if lesson requires premium access
        guard lesson.isPremium else {
            return .allowed
        }
        
        // Pro users have unlimited access
        if subscriptionManager.isProUser {
            return .allowed
        }
        
        // Check lesson tokens for free users - Allow some free access
        if !subscriptionManager.isProUser && subscriptionManager.lessonTokens > 0 {
            return .tokenRequired
        }
        
        // Allow first premium lesson for free to demonstrate value
        if shouldAllowFreePremiumLesson() {
            return .allowed
        }
        
        return .blocked(.lessonGate)
    }
    
    // MARK: - User-Friendly Paywall Timing Logic
    
    private func shouldAllowFreePremiumLesson() -> Bool {
        // Allow first premium lesson for free to demonstrate value
        let hasUsedFreePremiumLesson = UserDefaults.standard.bool(forKey: "hasUsedFreePremiumLesson")
        return !hasUsedFreePremiumLesson
    }
    
    private func markFreePremiumLessonUsed() {
        UserDefaults.standard.set(true, forKey: "hasUsedFreePremiumLesson")
    }
    
    @MainActor func canImportCustomImages() -> FeatureGateResult {
        if subscriptionManager.isProUser {
            return .allowed
        }
        
        // Allow limited custom image imports for free users
        if canUseWeeklyFeature("customImageImport", limit: 2) {
            return .allowed
        }
        
        return .blocked(.imageImportGate)
    }
    
    @MainActor func canExportWithoutWatermark() -> FeatureGateResult {
        if subscriptionManager.isProUser {
            return .allowed
        }
        
        // Allow limited watermark-free exports for free users
        if canUseWeeklyFeature("watermarkFreeExport", limit: 3) {
            return .allowed
        }
        
        return .blocked(.exportGate)
    }
    
    @MainActor func canAccessAdvancedAIFeatures() -> FeatureGateResult {
        if subscriptionManager.isProUser {
            return .allowed
        }
        
        // Allow limited advanced AI features for free users
        if canUseWeeklyFeature("advancedAI", limit: 5) {
            return .allowed
        }
        
        return .blocked(.general)
    }
    
    @MainActor func canAccessPremiumDrawingTools() -> FeatureGateResult {
        if subscriptionManager.isProUser {
            return .allowed
        }
        
        // Allow limited premium tools for free users
        if canUseWeeklyFeature("premiumTools", limit: 3) {
            return .allowed
        }
        
        return .blocked(.general)
    }
    
    @MainActor func canAccessPrioritySupport() -> FeatureGateResult {
        if subscriptionManager.isProUser {
            return .allowed
        }
        return .blocked(.general)
    }
    
    // MARK: - Generic Feature Access Methods
    
    @MainActor func checkAccess(for feature: PremiumFeature) -> FeatureGateResult {
        switch feature {
        case .unlimitedLessons:
            return subscriptionManager.isProUser ? .allowed : .blocked(.general)
        case .customImageImport:
            return canImportCustomImages()
        case .watermarkRemoval:
            return canExportWithoutWatermark()
        case .advancedAI, .advancedAIGuidance:
            return canAccessAdvancedAIFeatures()
        case .premiumTools:
            return canAccessPremiumDrawingTools()
        case .prioritySupport:
            return canAccessPrioritySupport()
        case .cloudSync:
            return subscriptionManager.isProUser ? .allowed : .blocked(.general)
        case .timelapseExport:
            return subscriptionManager.isProUser ? .allowed : .blocked(.general)
        case .socialSharing:
            return subscriptionManager.isProUser ? .allowed : .blocked(.general)
        case .unlimitedLessonTokens:
            return subscriptionManager.isProUser ? .allowed : .blocked(.general)
        case .premiumLessons:
            return subscriptionManager.isProUser ? .allowed : .blocked(.lessonGate)
        }
    }
    
    @MainActor func requestAccess(for feature: PremiumFeature, from source: PaywallTriggerSource) {
        let gateResult = checkAccess(for: feature)
        
        switch gateResult {
        case .allowed:
            // Access already granted, no action needed
            break
        case .tokenRequired:
            // Show paywall for token purchase or subscription
            showPaywall(context: .lessonGate)
        case .blocked(let context):
            showPaywall(context: context)
        }
    }
    
    // MARK: - Feature Access Actions
    
    @MainActor func accessLesson(_ lesson: Lesson, completion: @escaping (Bool) -> Void) {
        let gateResult = canAccessLesson(lesson)
        
        switch gateResult {
        case .allowed:
            // Mark free premium lesson as used if applicable
            if lesson.isPremium && shouldAllowFreePremiumLesson() {
                markFreePremiumLessonUsed()
            }
            completion(true)
            
        case .tokenRequired:
            if subscriptionManager.consumeToken() {
                completion(true)
            } else {
                // Show gentle paywall with value proposition
                showPaywall(context: .lessonGate)
                completion(false)
            }
            
        case .blocked(let context):
            // Show contextual paywall with clear value proposition
            showPaywall(context: context)
            completion(false)
        }
    }
    
    @MainActor func requestImageImport(completion: @escaping (Bool) -> Void) {
        let gateResult = canImportCustomImages()
        
        switch gateResult {
        case .allowed:
            completion(true)
        case .blocked(let context):
            showPaywall(context: context)
            completion(false)
        case .tokenRequired:
            // Image import doesn't use tokens, only subscription
            showPaywall(context: .imageImportGate)
            completion(false)
        }
    }
    
    @MainActor func requestWatermarkRemoval(completion: @escaping (Bool) -> Void) {
        let gateResult = canExportWithoutWatermark()
        
        switch gateResult {
        case .allowed:
            completion(true)
        case .blocked(let context):
            showPaywall(context: context)
            completion(false)
        case .tokenRequired:
            // Watermark removal doesn't use tokens, only subscription
            showPaywall(context: .exportGate)
            completion(false)
        }
    }
    
    // MARK: - Export Watermarking
    
    @MainActor func getExportWatermark() -> String? {
        if subscriptionManager.isProUser {
            return nil
        }
        return Config.exportWatermarkText
    }
    
    @MainActor func shouldApplyWatermark() -> Bool {
        return !subscriptionManager.isProUser
    }
    
    // MARK: - UI Helper Methods
    
    @MainActor func getLessonAccessText(_ lesson: Lesson) -> String {
        let gateResult = canAccessLesson(lesson)
        
        switch gateResult {
        case .allowed:
            return "Start Drawing"
        case .tokenRequired:
            return "Use 1 Token"
        case .blocked:
            return "Upgrade to Access"
        }
    }
    
    @MainActor func getLessonAccessIcon(_ lesson: Lesson) -> String {
        let gateResult = canAccessLesson(lesson)
        
        switch gateResult {
        case .allowed:
            return "play.fill"
        case .tokenRequired:
            return "ticket.fill"
        case .blocked:
            return "crown.fill"
        }
    }
    
    @MainActor func getLessonAccessColor(_ lesson: Lesson) -> Color {
        let gateResult = canAccessLesson(lesson)
        
        switch gateResult {
        case .allowed:
            return lesson.category.color
        case .tokenRequired:
            return .orange
        case .blocked:
            return .yellow
        }
    }
    
    func getFeaturePromptText(for feature: PremiumFeature) -> String {
        switch feature {
        case .unlimitedLessons:
            return "Upgrade to access unlimited premium lessons"
        case .customImageImport:
            return "Upgrade to import your own images"
        case .watermarkRemoval:
            return "Upgrade to export without watermarks"
        case .advancedAI:
            return "Upgrade for enhanced AI accuracy and feedback"
        case .premiumTools:
            return "Upgrade to unlock premium drawing tools"
        case .prioritySupport:
            return "Upgrade for priority customer support"
        case .cloudSync:
            return "Upgrade to sync your drawings across devices"
        case .timelapseExport:
            return "Upgrade to export timelapse videos"
        case .socialSharing:
            return "Upgrade to share on social media"
        case .unlimitedLessonTokens:
            return "Upgrade for unlimited lesson tokens"
        case .premiumLessons:
            return "Upgrade to access premium lessons"
        case .advancedAIGuidance:
            return "Upgrade for advanced AI guidance"
        }
    }
    
    // MARK: - Paywall Management
    
    func showPaywall(context: PaywallContext) {
        paywallContext = context
        shouldShowPaywall = true
    }
    
    func dismissPaywall() {
        shouldShowPaywall = false
    }
    
    // MARK: - Token Display Helpers
    
    @MainActor func getTokenDisplayText() -> String {
        if subscriptionManager.isProUser {
            return "∞ Unlimited"
        } else {
            let tokens = subscriptionManager.lessonTokens
            return "\(tokens) Token\(tokens == 1 ? "" : "s")"
        }
    }
    
    @MainActor func getTokenDisplayIcon() -> String {
        return subscriptionManager.isProUser ? "infinity" : "ticket.fill"
    }
    
    @MainActor func getTokenDisplayColor() -> Color {
        if subscriptionManager.isProUser {
            return .green
        } else if subscriptionManager.lessonTokens > 0 {
            return .blue
        } else {
            return .red
        }
    }
    
    // MARK: - Subscription Status Helpers
    
    @MainActor func getSubscriptionBadgeText() -> String? {
        switch subscriptionManager.currentSubscription {
        case .free:
            return nil
        case .proWeekly, .proMonthly, .proAnnual:
            return "PRO"
        }
    }
    
    func getSubscriptionBadgeColor() -> Color {
        return .yellow
    }
    
    // MARK: - Feature Availability Checks
    
    @MainActor func isFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedLessons,
             .customImageImport,
             .watermarkRemoval,
             .advancedAI,
             .premiumTools,
             .prioritySupport,
             .cloudSync,
             .timelapseExport,
             .socialSharing,
             .unlimitedLessonTokens,
             .premiumLessons,
             .advancedAIGuidance:
            return subscriptionManager.isProUser
        }
    }
    
    // MARK: - Weekly Limits (for free users)
    
    private func getWeeklyUsageKey(for feature: String) -> String {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        let year = calendar.component(.year, from: Date())
        return "\(feature)_usage_\(year)_\(weekOfYear)"
    }
    
    private func getCurrentWeeklyUsage(for feature: String) -> Int {
        let key = getWeeklyUsageKey(for: feature)
        return UserDefaults.standard.integer(forKey: key)
    }
    
    private func incrementWeeklyUsage(for feature: String) {
        let key = getWeeklyUsageKey(for: feature)
        let currentUsage = getCurrentWeeklyUsage(for: feature)
        UserDefaults.standard.set(currentUsage + 1, forKey: key)
    }
    
    @MainActor func canUseWeeklyFeature(_ feature: String, limit: Int) -> Bool {
        if subscriptionManager.isProUser {
            return true
        }
        
        return getCurrentWeeklyUsage(for: feature) < limit
    }
    
    @MainActor func useWeeklyFeature(_ feature: String) {
        if !subscriptionManager.isProUser {
            incrementWeeklyUsage(for: feature)
        }
    }
}

// MARK: - Supporting Enums and Structs

enum FeatureGateResult: Equatable {
    case allowed
    case tokenRequired
    case blocked(PaywallContext)
    
    static func == (lhs: FeatureGateResult, rhs: FeatureGateResult) -> Bool {
        switch (lhs, rhs) {
        case (.allowed, .allowed), (.tokenRequired, .tokenRequired):
            return true
        case (.blocked(let lhsContext), .blocked(let rhsContext)):
            return lhsContext == rhsContext
        default:
            return false
        }
    }
}

enum PremiumFeature: CaseIterable {
    case unlimitedLessons
    case customImageImport
    case watermarkRemoval
    case advancedAI
    case premiumTools
    case prioritySupport
    case cloudSync
    case timelapseExport
    case socialSharing
    case unlimitedLessonTokens
    case premiumLessons
    case advancedAIGuidance
    
    var displayName: String {
        switch self {
        case .unlimitedLessons: return "Unlimited Lessons"
        case .customImageImport: return "Custom Image Import"
        case .watermarkRemoval: return "Watermark Removal"
        case .advancedAI: return "Advanced AI Guidance"
        case .premiumTools: return "Premium Drawing Tools"
        case .prioritySupport: return "Priority Support"
        case .cloudSync: return "Cloud Sync"
        case .timelapseExport: return "Timelapse Export"
        case .socialSharing: return "Social Sharing"
        case .unlimitedLessonTokens: return "Unlimited Lesson Tokens"
        case .premiumLessons: return "Premium Lessons"
        case .advancedAIGuidance: return "Advanced AI Guidance"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedLessons: return "infinity"
        case .customImageImport: return "photo.badge.plus"
        case .watermarkRemoval: return "eye.slash"
        case .advancedAI: return "wand.and.stars"
        case .premiumTools: return "paintbrush.pointed"
        case .prioritySupport: return "headphones"
        case .cloudSync: return "icloud"
        case .timelapseExport: return "video.badge.plus"
        case .socialSharing: return "square.and.arrow.up"
        case .unlimitedLessonTokens: return "ticket"
        case .premiumLessons: return "graduationcap"
        case .advancedAIGuidance: return "brain.head.profile"
        }
    }
}

// MARK: - SwiftUI View Modifiers

struct FeatureGateModifier: ViewModifier {
    let featureGateManager: FeatureGateManager
    let feature: PremiumFeature
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if featureGateManager.isFeatureAvailable(feature) {
                    action()
                } else {
                    featureGateManager.showPaywall(context: .general)
                }
            }
            .overlay(
                Group {
                    if !featureGateManager.isFeatureAvailable(feature) {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(6)
                                    .padding(8)
                            }
                        }
                    }
                }
            )
    }
}

extension View {
    func featureGated(
        manager: FeatureGateManager,
        feature: PremiumFeature,
        action: @escaping () -> Void
    ) -> some View {
        modifier(FeatureGateModifier(
            featureGateManager: manager,
            feature: feature,
            action: action
        ))
    }
}

// MARK: - Lesson Extension for Premium Status
extension Lesson {
    var premiumBadge: some View {
        Group {
            if isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                    Text("PRO")
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow)
                .cornerRadius(8)
            }
        }
    }
}

