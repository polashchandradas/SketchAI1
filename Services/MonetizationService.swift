import Foundation
import SwiftUI
import Combine

// MARK: - Monetization Service
class MonetizationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPro: Bool = false
    @Published var shouldShowPaywall: Bool = false
    @Published var paywallContext: PaywallContext = .general
    
    // MARK: - Dependencies
    @Published var subscriptionManager: ProductionSubscriptionManager!
    @Published var featureGateManager: FeatureGateManager!
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        Task { @MainActor in
            // Initialize subscription manager on MainActor
            self.subscriptionManager = ProductionSubscriptionManager(persistenceService: PersistenceService())
            setupDependencies()
            setupSubscriptionObserver()
        }
    }
    
    private func setupDependencies() {
        // Initialize feature gate manager after subscription manager is ready
        featureGateManager = FeatureGateManager(subscriptionManager: subscriptionManager)
        
        // Sync paywall display with feature gate manager
        featureGateManager.$shouldShowPaywall
            .sink { [weak self] shouldShow in
                self?.shouldShowPaywall = shouldShow
            }
            .store(in: &cancellables)
        
        featureGateManager.$paywallContext
            .sink { [weak self] context in
                self?.paywallContext = context
            }
            .store(in: &cancellables)
    }
    
    @MainActor private func setupSubscriptionObserver() {
        // Sync isPro with subscription manager
        subscriptionManager.$isProUser
            .sink { [weak self] isProUser in
                self?.isPro = isProUser
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Interface
    
    // MARK: - Subscription Management
    @MainActor func upgradeToProSubscription() {
        isPro = true
        subscriptionManager.isProUser = true
    }
    
    @MainActor func checkFeatureAccess(for feature: PremiumFeature) -> FeatureGateResult {
        guard let featureGateManager = featureGateManager else { 
            return .blocked(.general) 
        }
        return featureGateManager.checkAccess(for: feature)
    }
    
    func requestFeatureAccess(for feature: PremiumFeature, from source: PaywallTriggerSource) {
        Task { @MainActor in
            featureGateManager?.requestAccess(for: feature, from: source)
        }
    }
    
    // MARK: - Paywall Management
    func showPaywall(context: PaywallContext = .general) {
        paywallContext = context
        shouldShowPaywall = true
    }
    
    func hidePaywall() {
        shouldShowPaywall = false
    }
    
    // MARK: - Feature Checks (Convenience Methods)
    @MainActor func canExportWithoutWatermark() -> Bool {
        return checkFeatureAccess(for: .watermarkRemoval) == .allowed
    }
    
    @MainActor func canImportCustomImages() -> Bool {
        return checkFeatureAccess(for: .customImageImport) == .allowed
    }
    
    @MainActor func canUseAdvancedAI() -> Bool {
        return checkFeatureAccess(for: .advancedAIGuidance) == .allowed
    }
    
    @MainActor func canUsePremiumLessons() -> Bool {
        return checkFeatureAccess(for: .premiumLessons) == .allowed
    }
    
    @MainActor func canCreateTimelapseVideos() -> Bool {
        return checkFeatureAccess(for: .timelapseExport) == .allowed
    }
    
    @MainActor func canShareSocially() -> Bool {
        return checkFeatureAccess(for: .socialSharing) == .allowed
    }
    
    @MainActor func hasUnlimitedTokens() -> Bool {
        return checkFeatureAccess(for: .unlimitedLessonTokens) == .allowed
    }
    
    // MARK: - Token Management
    @MainActor func getLessonTokens() -> Int {
        return subscriptionManager.lessonTokens
    }
    
    @MainActor func consumeLessonToken() -> Bool {
        return subscriptionManager.consumeToken()
    }
    
    func purchaseLessonTokens() async -> Bool {
        // Choose default 10 tokens pack for compatibility
        return await subscriptionManager.purchaseTokens(10)
    }
    
    // MARK: - Subscription Info
    @MainActor func getCurrentSubscriptionTier() -> SubscriptionTier {
        return subscriptionManager.currentSubscription
    }
    
    @MainActor func getSubscriptionStatus() -> SubscriptionStatus {
        return subscriptionManager.subscriptionStatus
    }
    
    @MainActor func isLoading() -> Bool {
        return subscriptionManager.isLoading
    }
    
    @MainActor func getLastError() -> SubscriptionError? {
        return subscriptionManager.lastError
    }
    
    // MARK: - Purchase Operations
    func purchaseSubscription(_ tier: SubscriptionTier) async -> Bool {
        return await subscriptionManager.purchaseSubscription(tier)
    }
    
    func restorePurchases() async -> Bool {
        return await subscriptionManager.restorePurchases()
    }
    
    // MARK: - Feature Gate Helpers
    func requestPremiumLessonAccess(from source: PaywallTriggerSource = .lessonList) {
        requestFeatureAccess(for: .premiumLessons, from: source)
    }
    
    func requestExportAccess(from source: PaywallTriggerSource = .exportMenu) {
        requestFeatureAccess(for: .watermarkRemoval, from: source)
    }
    
    func requestAdvancedAIAccess(from source: PaywallTriggerSource = .drawingCanvas) {
        requestFeatureAccess(for: .advancedAIGuidance, from: source)
    }
    
    func requestSharingAccess(from source: PaywallTriggerSource = .sharingMenu) {
        requestFeatureAccess(for: .socialSharing, from: source)
    }
    
    // MARK: - Analytics and Insights
    @MainActor func getMonetizationAnalytics() -> MonetizationAnalytics {
        return MonetizationAnalytics(
            subscriptionTier: getCurrentSubscriptionTier(),
            tokensRemaining: getLessonTokens(),
            isPro: isPro,
            subscriptionStatus: getSubscriptionStatus(),
            lastPaywallContext: paywallContext
        )
    }
}

// MARK: - Supporting Types

enum PaywallTriggerSource {
    case exportMenu
    case drawingCanvas
    case sharingMenu
    case profile
    case lessonDetail
    case lessonList
    case gallery
    case settings
}

struct MonetizationAnalytics {
    let subscriptionTier: SubscriptionTier
    let tokensRemaining: Int
    let isPro: Bool
    let subscriptionStatus: SubscriptionStatus
    let lastPaywallContext: PaywallContext
}
