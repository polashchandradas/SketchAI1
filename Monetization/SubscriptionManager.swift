import Foundation
import SwiftUI
import Combine
import StoreKit

// MARK: - RevenueCat Integration Note
// This file provides the architecture for RevenueCat integration.
// To complete the implementation, add RevenueCat SDK via Swift Package Manager:
// 1. File → Add Package Dependencies
// 2. Enter: https://github.com/RevenueCat/purchases-ios
// 3. Import RevenueCat and uncomment the RevenueCat-specific code below

// import RevenueCat

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProUser: Bool = false
    @Published var currentSubscription: SubscriptionTier = .free
    @Published var lessonTokens: Int = 3 // Free tier starts with 3 tokens
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isLoading: Bool = false
    @Published var lastError: SubscriptionError?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Configuration
    private struct Config {
        static let revenueCatAPIKey = "your_revenuecat_public_api_key_here" // Replace with actual key
        static let proEntitlementID = "pro_access"
        static let weeklyTokensEntitlementID = "weekly_tokens"
        
        // Product IDs - must match App Store Connect and RevenueCat
        static let weeklyProSubscription = "sketchai_pro_weekly"
        static let monthlyProSubscription = "sketchai_pro_monthly"
        static let annualProSubscription = "sketchai_pro_annual"
        static let lessonTokensPack = "sketchai_tokens_10pack"
        
        // Free tier limits
        static let freeWeeklyLessons = 3
        static let freeTokenRefreshInterval: TimeInterval = 7 * 24 * 60 * 60 // 1 week
    }
    
    // MARK: - Initialization
    init() {
        configureRevenueCat()
        loadCachedSubscriptionState()
        setupSubscriptionObserver()
        checkTokenRefresh()
    }
    
    // MARK: - RevenueCat Configuration
    private func configureRevenueCat() {
        // Uncomment when RevenueCat is added via Swift Package Manager
        /*
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.revenueCatAPIKey)
        
        // Set user ID if available
        if let userID = getCurrentUserID() {
            Purchases.shared.logIn(userID) { customerInfo, created, error in
                if let error = error {
                    print("RevenueCat login error: \(error)")
                } else {
                    self.updateSubscriptionStatus(from: customerInfo)
                }
            }
        }
        */
    }
    
    // MARK: - Subscription Status Management
    func refreshSubscriptionStatus() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Uncomment when RevenueCat is integrated
        /*
        Purchases.shared.getCustomerInfo { customerInfo, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.lastError = .revenueCatError(error.localizedDescription)
                } else if let customerInfo = customerInfo {
                    self.updateSubscriptionStatus(from: customerInfo)
                }
            }
        }
        */
        
        // Fallback for development without RevenueCat
        await MainActor.run {
            isLoading = false
            loadCachedSubscriptionState()
        }
    }
    
    private func updateSubscriptionStatus(from customerInfo: Any) {
        // Uncomment when RevenueCat is integrated
        /*
        guard let customerInfo = customerInfo as? CustomerInfo else { return }
        
        // Check Pro entitlement
        let hasProAccess = customerInfo.entitlements[Config.proEntitlementID]?.isActive == true
        
        // Update subscription tier
        if hasProAccess {
            if customerInfo.entitlements[Config.proEntitlementID]?.productIdentifier == Config.weeklyProSubscription {
                currentSubscription = .proWeekly
            } else if customerInfo.entitlements[Config.proEntitlementID]?.productIdentifier == Config.monthlyProSubscription {
                currentSubscription = .proMonthly
            } else if customerInfo.entitlements[Config.proEntitlementID]?.productIdentifier == Config.annualProSubscription {
                currentSubscription = .proAnnual
            }
            
            subscriptionStatus = .subscribed
            isProUser = true
            
            // Pro users get unlimited tokens (represented as high number)
            lessonTokens = 999
        } else {
            currentSubscription = .free
            subscriptionStatus = .notSubscribed
            isProUser = false
        }
        
        // Cache the subscription state
        cacheSubscriptionState()
        */
    }
    
    // MARK: - Purchase Methods
    func purchaseSubscription(_ tier: SubscriptionTier) async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        let _ = getProductID(for: tier)
        
        // Uncomment when RevenueCat is integrated
        /*
        return await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                guard let offerings = offerings,
                      let currentOffering = offerings.current,
                      let package = self.findPackage(productID: productID, in: currentOffering) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.lastError = .productNotFound
                    }
                    continuation.resume(returning: false)
                    return
                }
                
                Purchases.shared.purchase(package: package) { transaction, customerInfo, error, userCancelled in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            if !userCancelled {
                                self.lastError = .purchaseFailed(error.localizedDescription)
                            }
                            continuation.resume(returning: false)
                        } else if let customerInfo = customerInfo {
                            self.updateSubscriptionStatus(from: customerInfo)
                            continuation.resume(returning: true)
                        } else {
                            continuation.resume(returning: false)
                        }
                    }
                }
            }
        }
        */
        
        // Fallback for development without RevenueCat
        await MainActor.run {
            isLoading = false
            // Simulate successful purchase for development
            simulatePurchase(tier)
        }
        
        return true
    }
    
    func purchaseLessonTokens() async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        // Uncomment when RevenueCat is integrated
        /*
        return await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                guard let offerings = offerings,
                      let currentOffering = offerings.current,
                      let tokenPackage = self.findPackage(productID: Config.lessonTokensPack, in: currentOffering) else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.lastError = .productNotFound
                    }
                    continuation.resume(returning: false)
                    return
                }
                
                Purchases.shared.purchase(package: tokenPackage) { transaction, customerInfo, error, userCancelled in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            if !userCancelled {
                                self.lastError = .purchaseFailed(error.localizedDescription)
                            }
                            continuation.resume(returning: false)
                        } else {
                            // Add 10 tokens for successful purchase
                            self.lessonTokens += 10
                            self.cacheSubscriptionState()
                            continuation.resume(returning: true)
                        }
                    }
                }
            }
        }
        */
        
        // Fallback for development without RevenueCat
        await MainActor.run {
            isLoading = false
            lessonTokens += 10
            cacheSubscriptionState()
        }
        
        return true
    }
    
    func purchaseTokens(_ count: Int) async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        // Fallback for development without RevenueCat
        await MainActor.run {
            isLoading = false
            // Simulate successful token purchase for development
            lessonTokens += count
        }
        
        return true
    }
    
    func restorePurchases() async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        // Uncomment when RevenueCat is integrated
        /*
        return await withCheckedContinuation { continuation in
            Purchases.shared.restorePurchases { customerInfo, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.lastError = .restoreFailed(error.localizedDescription)
                        continuation.resume(returning: false)
                    } else if let customerInfo = customerInfo {
                        self.updateSubscriptionStatus(from: customerInfo)
                        continuation.resume(returning: true)
                    } else {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
        */
        
        // Fallback for development without RevenueCat
        await MainActor.run {
            isLoading = false
        }
        
        return true
    }
    
    // MARK: - Token Management
    func consumeLessonToken() -> Bool {
        guard canAccessLesson() else { return false }
        
        if !isProUser && lessonTokens > 0 {
            lessonTokens -= 1
            cacheSubscriptionState()
            return true
        } else if isProUser {
            // Pro users have unlimited access
            return true
        }
        
        return false
    }
    
    func canAccessLesson() -> Bool {
        return isProUser || lessonTokens > 0
    }
    
    private func checkTokenRefresh() {
        guard !isProUser else { return }
        
        let lastRefreshDate = userDefaults.object(forKey: "lastTokenRefresh") as? Date ?? Date.distantPast
        let now = Date()
        
        if now.timeIntervalSince(lastRefreshDate) >= Config.freeTokenRefreshInterval {
            lessonTokens = min(lessonTokens + Config.freeWeeklyLessons, Config.freeWeeklyLessons)
            userDefaults.set(now, forKey: "lastTokenRefresh")
            cacheSubscriptionState()
        }
    }
    
    // MARK: - Subscription Observer
    private func setupSubscriptionObserver() {
        // Observe subscription status changes
        NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionStatusChanged"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    private func getProductID(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free:
            return ""
        case .proWeekly:
            return Config.weeklyProSubscription
        case .proMonthly:
            return Config.monthlyProSubscription
        case .proAnnual:
            return Config.annualProSubscription
        }
    }
    
    private func getCurrentUserID() -> String? {
        // Return user ID if available for RevenueCat user identification
        return userDefaults.string(forKey: "userID")
    }
    
    // Uncomment when RevenueCat is integrated
    /*
    private func findPackage(productID: String, in offering: Offering) -> Package? {
        return offering.availablePackages.first { package in
            package.storeProduct.productIdentifier == productID
        }
    }
    */
    
    // MARK: - Cache Management
    private func cacheSubscriptionState() {
        userDefaults.set(isProUser, forKey: "isProUser")
        userDefaults.set(currentSubscription.rawValue, forKey: "currentSubscription")
        userDefaults.set(lessonTokens, forKey: "lessonTokens")
        userDefaults.set(subscriptionStatus.rawValue, forKey: "subscriptionStatus")
    }
    
    private func loadCachedSubscriptionState() {
        isProUser = userDefaults.bool(forKey: "isProUser")
        lessonTokens = userDefaults.integer(forKey: "lessonTokens")
        
        if lessonTokens == 0 && !isProUser {
            lessonTokens = Config.freeWeeklyLessons
        }
        
        if let subscriptionTierRaw = userDefaults.object(forKey: "currentSubscription") as? String,
           let tier = SubscriptionTier(rawValue: subscriptionTierRaw) {
            currentSubscription = tier
        }
        
        if let statusRaw = userDefaults.object(forKey: "subscriptionStatus") as? String,
           let status = SubscriptionStatus(rawValue: statusRaw) {
            subscriptionStatus = status
        }
    }
    
    // MARK: - Development Helpers
    private func simulatePurchase(_ tier: SubscriptionTier) {
        currentSubscription = tier
        isProUser = tier != .free
        subscriptionStatus = tier != .free ? .subscribed : .notSubscribed
        
        if isProUser {
            lessonTokens = 999 // Unlimited for pro users
        }
        
        cacheSubscriptionState()
    }
    
    // MARK: - Public Utility Methods
    func getSubscriptionFeatures(_ tier: SubscriptionTier) -> [String] {
        return tier.features
    }
    
    func getSubscriptionPrice(_ tier: SubscriptionTier) -> String {
        return tier.price
    }
    
    func canImportCustomImages() -> Bool {
        return isProUser
    }
    
    func hasWatermarkRemoval() -> Bool {
        return isProUser
    }
    
    func hasAdvancedAIGuidance() -> Bool {
        return isProUser
    }
    
    func hasPrioritySupport() -> Bool {
        return isProUser
    }
}

// MARK: - Supporting Enums and Structs

enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case proWeekly = "pro_weekly"
    case proMonthly = "pro_monthly"
    case proAnnual = "pro_annual"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .proWeekly: return "Pro Weekly"
        case .proMonthly: return "Pro Monthly"
        case .proAnnual: return "Pro Annual"
        }
    }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .proWeekly: return "$2.99/week"
        case .proMonthly: return "$9.99/month"
        case .proAnnual: return "$79.99/year"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "3 free lessons per week",
                "Basic drawing tools",
                "Watermarked exports",
                "Limited AI guidance"
            ]
        case .proWeekly, .proMonthly, .proAnnual:
            return [
                "Unlimited lessons",
                "Import your own images",
                "Remove watermarks",
                "Advanced AI guidance",
                "Premium drawing tools",
                "Cloud sync",
                "Priority support"
            ]
        }
    }
    
    var savings: String? {
        switch self {
        case .free, .proWeekly, .proMonthly:
            return nil
        case .proAnnual:
            return "Save 33%"
        }
    }
    
    var isPopular: Bool {
        return self == .proMonthly
    }
}

enum SubscriptionStatus: String {
    case notSubscribed = "not_subscribed"
    case subscribed = "subscribed"
    case expired = "expired"
    case gracePeriod = "grace_period"
    case canceled = "canceled"
}

enum SubscriptionError: Error, LocalizedError, Equatable {
    case productNotFound
    case purchaseFailed(String)
    case restoreFailed(String)
    case revenueCatError(String)
    case networkError
    case userCanceled
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found. Please try again later."
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Failed to restore purchases: \(message)"
        case .revenueCatError(let message):
            return "Subscription service error: \(message)"
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .userCanceled:
            return "Purchase was canceled."
        }
    }
}


