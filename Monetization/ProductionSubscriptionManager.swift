import Foundation
import SwiftUI
import Combine
import StoreKit

// MARK: - Production-Ready Subscription Manager with RevenueCat
// This implementation follows 2024 iOS monetization best practices

@MainActor
class ProductionSubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProUser: Bool = false
    @Published var currentSubscription: SubscriptionTier = .free
    @Published var lessonTokens: Int = 3
    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isLoading: Bool = false
    @Published var lastError: SubscriptionError?
    @Published var activeEntitlements: Set<String> = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let persistenceService: PersistenceService
    
    // MARK: - RevenueCat Configuration
    private struct RevenueCatConfig {
        // 🔑 Replace with your actual RevenueCat API key from dashboard
        static let apiKey = "appl_your_revenuecat_public_api_key_here"
        
        // 🎯 Entitlement IDs (configured in RevenueCat dashboard)
        static let proEntitlementID = "pro_access"
        static let premiumLessonsID = "premium_lessons"
        static let watermarkRemovalID = "watermark_removal"
        static let advancedAIID = "advanced_ai"
        static let customImportsID = "custom_imports"
        
        // 📦 Product IDs (must match App Store Connect)
        static let weeklyPro = "sketchai_pro_weekly"
        static let monthlyPro = "sketchai_pro_monthly"
        static let annualPro = "sketchai_pro_annual"
        static let tokenPack10 = "sketchai_tokens_10"
        static let tokenPack25 = "sketchai_tokens_25"
        
        // 🆓 Free tier configuration
        static let freeWeeklyTokens = 3
        static let tokenRefreshDays = 7
    }
    
    // MARK: - Initialization
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        
        setupRevenueCat()
        loadCachedState()
        setupObservers()
        checkTokenRefresh()
    }
    
    // MARK: - StoreKit 2 Setup
    private func setupRevenueCat() {
        // 🔧 Configure StoreKit 2 for native subscription management
        setupStoreKitObserver()
        print("🔧 StoreKit 2 configured for production")
    }
    
    private func setupStoreKitObserver() {
        // Set up StoreKit 2 transaction listener
        Task {
            for await result in Transaction.updates {
                await handleTransactionUpdate(result)
            }
        }
    }
    
    @MainActor
    private func handleTransactionUpdate(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else {
            // Handle unverified transactions
            print("⚠️ Unverified transaction received")
            return
        }
        
        // Process the verified transaction
        switch transaction.productType {
        case .autoRenewable:
            handleSubscriptionTransaction(transaction)
        case .consumable:
            handleTokenPurchaseTransaction(transaction)
        default:
            break
        }
        
        // Mark transaction as finished
        await transaction.finish()
    }
    
    private func handleSubscriptionTransaction(_ transaction: StoreKit.Transaction) {
        Task { @MainActor in
            // Update subscription status based on transaction
            let productID = transaction.productID
            
            switch productID {
            case RevenueCatConfig.weeklyPro:
                currentSubscription = .proWeekly
            case RevenueCatConfig.monthlyPro:
                currentSubscription = .proMonthly
            case RevenueCatConfig.annualPro:
                currentSubscription = .proAnnual
            default:
                return
            }
            
            isProUser = true
            subscriptionStatus = .subscribed
            lessonTokens = 999 // Unlimited for pro users
            
            activeEntitlements.insert("pro_access")
            saveState()
            
            print("✅ Subscription activated: \(productID)")
        }
    }
    
    private func handleTokenPurchaseTransaction(_ transaction: StoreKit.Transaction) {
        Task { @MainActor in
            let productID = transaction.productID
            
            switch productID {
            case RevenueCatConfig.tokenPack10:
                lessonTokens += 10
            case RevenueCatConfig.tokenPack25:
                lessonTokens += 25
            default:
                return
            }
            
            saveState()
            print("✅ Tokens added: \(productID)")
        }
    }
    
    // MARK: - Subscription Management
    func refreshSubscriptionStatus() async {
        await MainActor.run { isLoading = true }
        
        // 🔄 Check current subscription status using StoreKit 2
        await checkActiveSubscriptions()
        await MainActor.run {
            self.isLoading = false
            self.lastError = nil
        }
    }
    
    private func checkActiveSubscriptions() async {
        var hasActiveSubscription = false
        var currentTier: SubscriptionTier = .free
        var entitlements: Set<String> = []
        
        // Check all subscription entitlements
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            // Check if subscription is still active
            if let expirationDate = transaction.expirationDate,
               expirationDate > Date() {
                hasActiveSubscription = true
                entitlements.insert("pro_access")
                
                // Determine subscription tier
                switch transaction.productID {
                case RevenueCatConfig.weeklyPro:
                    currentTier = .proWeekly
                case RevenueCatConfig.monthlyPro:
                    currentTier = .proMonthly
                case RevenueCatConfig.annualPro:
                    currentTier = .proAnnual
                default:
                    break
                }
            }
        }
        
        await MainActor.run {
            self.isProUser = hasActiveSubscription
            self.currentSubscription = currentTier
            self.subscriptionStatus = hasActiveSubscription ? .subscribed : .notSubscribed
            self.activeEntitlements = entitlements
            
            if hasActiveSubscription {
                self.lessonTokens = 999 // Unlimited for pro users
            }
            
            self.saveState()
        }
    }
    
    // MARK: - Purchase Methods
    func purchaseSubscription(_ tier: SubscriptionTier) async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        let productID = getProductID(for: tier)
        
        do {
            // 🛒 Request products from the App Store
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                await MainActor.run {
                    self.lastError = .productNotFound
                    self.isLoading = false
                }
                return false
            }
            
            // 💳 Initiate the purchase
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful purchase
                await handlePurchaseSuccess(verification, tier: tier)
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.lastError = .userCanceled
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.isLoading = false
                    // Transaction is pending (e.g., requires parental approval)
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.lastError = .purchaseFailed("Unknown purchase result")
                    self.isLoading = false
                }
                return false
            }
            
        } catch {
            await MainActor.run {
                self.lastError = .purchaseFailed(error.localizedDescription)
                self.isLoading = false
                self.trackPurchaseEvent(tier: tier, success: false)
            }
            return false
        }
    }
    
    private func handlePurchaseSuccess(_ verification: VerificationResult<StoreKit.Transaction>, tier: SubscriptionTier) async {
        guard case .verified(let transaction) = verification else {
            await MainActor.run {
                self.lastError = .purchaseFailed("Transaction verification failed")
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = false
            self.currentSubscription = tier
            self.isProUser = true
            self.subscriptionStatus = .subscribed
            self.lessonTokens = 999 // Unlimited for pro users
            self.activeEntitlements.insert("pro_access")
            
            // 🎉 Track successful purchase
            self.trackPurchaseEvent(tier: tier, success: true)
            
            // 💾 Save to persistence
            self.persistenceService.saveSubscriptionData(SubscriptionData(
                tier: tier.rawValue,
                isActive: self.isProUser,
                tokens: self.lessonTokens,
                status: self.subscriptionStatus.rawValue
            ))
            
            self.saveState()
        }
        
        // Mark transaction as finished
        await transaction.finish()
    }
    
    func purchaseTokens(_ tokenCount: Int) async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        let productID = getTokenProductID(for: tokenCount)
        
        do {
            // 🛒 Request token products from the App Store
            let products = try await Product.products(for: [productID])
            guard let product = products.first else {
                await MainActor.run {
                    self.lastError = .productNotFound
                    self.isLoading = false
                }
                return false
            }
            
            // 💳 Initiate the token purchase
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle successful token purchase
                await handleTokenPurchaseSuccess(verification, tokenCount: tokenCount)
                return true
                
            case .userCancelled:
                await MainActor.run {
                    self.lastError = .userCanceled
                    self.isLoading = false
                }
                return false
                
            case .pending:
                await MainActor.run {
                    self.isLoading = false
                }
                return false
                
            @unknown default:
                await MainActor.run {
                    self.lastError = .purchaseFailed("Unknown purchase result")
                    self.isLoading = false
                }
                return false
            }
            
        } catch {
            await MainActor.run {
                self.lastError = .purchaseFailed(error.localizedDescription)
                self.isLoading = false
                self.trackTokenPurchase(count: tokenCount, success: false)
            }
            return false
        }
    }
    
    private func handleTokenPurchaseSuccess(_ verification: VerificationResult<StoreKit.Transaction>, tokenCount: Int) async {
        guard case .verified(let transaction) = verification else {
            await MainActor.run {
                self.lastError = .purchaseFailed("Transaction verification failed")
                self.isLoading = false
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = false
            // ➕ Add tokens (consumable purchase)
            self.lessonTokens += tokenCount
            self.saveState()
            
            // 📊 Track token purchase
            self.trackTokenPurchase(count: tokenCount, success: true)
        }
        
        // Mark transaction as finished (important for consumables)
        await transaction.finish()
    }
    
    func restorePurchases() async -> Bool {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            // 🔄 Sync with App Store and restore purchases using StoreKit 2
            try await AppStore.sync()
            
            // Check for any restored transactions
            await checkActiveSubscriptions()
            
            await MainActor.run {
                self.isLoading = false
                self.lastError = nil
            }
            
            return true
            
        } catch {
            await MainActor.run {
                self.lastError = .restoreFailed(error.localizedDescription)
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Feature Access Control
    func hasAccess(to feature: ProductionPremiumFeature) -> Bool {
        switch feature {
        case .premiumLessons:
            return isProUser || lessonTokens > 0
        case .watermarkRemoval, .customImageImport, .advancedAI, .prioritySupport:
            return isProUser
        case .unlimitedTokens:
            return isProUser
        case .cloudSync:
            return isProUser
        }
    }
    
    func consumeToken() -> Bool {
        guard !isProUser && lessonTokens > 0 else { return isProUser }
        
        lessonTokens -= 1
        saveState()
        
        // 📈 Track token consumption
        trackTokenConsumption()
        
        return true
    }
    
    // MARK: - Private Helpers
    
    private func getProductID(for tier: SubscriptionTier) -> String {
        switch tier {
        case .free: return ""
        case .proWeekly: return RevenueCatConfig.weeklyPro
        case .proMonthly: return RevenueCatConfig.monthlyPro
        case .proAnnual: return RevenueCatConfig.annualPro
        }
    }
    
    private func getTokenProductID(for count: Int) -> String {
        switch count {
        case 10: return RevenueCatConfig.tokenPack10
        case 25: return RevenueCatConfig.tokenPack25
        default: return RevenueCatConfig.tokenPack10
        }
    }
    
    private func getUserID() -> String? {
        return persistenceService.loadUserID()
    }
    
    
    // MARK: - Token Refresh Logic
    private func checkTokenRefresh() {
        guard !isProUser else { return }
        
        let lastRefreshKey = "lastTokenRefresh"
        let lastRefresh = userDefaults.object(forKey: lastRefreshKey) as? Date ?? Date.distantPast
        let daysSinceRefresh = Calendar.current.dateComponents([.day], from: lastRefresh, to: Date()).day ?? 0
        
        if daysSinceRefresh >= RevenueCatConfig.tokenRefreshDays {
            lessonTokens = min(lessonTokens + RevenueCatConfig.freeWeeklyTokens, RevenueCatConfig.freeWeeklyTokens)
            userDefaults.set(Date(), forKey: lastRefreshKey)
            saveState()
            
            print("🔄 Refreshed tokens: \(lessonTokens)")
        }
    }
    
    // MARK: - State Management
    private func loadCachedState() {
        isProUser = userDefaults.bool(forKey: "isProUser")
        lessonTokens = userDefaults.integer(forKey: "lessonTokens")
        
        if lessonTokens == 0 && !isProUser {
            lessonTokens = RevenueCatConfig.freeWeeklyTokens
        }
        
        if let tierRaw = userDefaults.string(forKey: "currentSubscription"),
           let tier = SubscriptionTier(rawValue: tierRaw) {
            currentSubscription = tier
        }
        
        if let statusRaw = userDefaults.string(forKey: "subscriptionStatus"),
           let status = SubscriptionStatus(rawValue: statusRaw) {
            subscriptionStatus = status
        }
    }
    
    private func saveState() {
        userDefaults.set(isProUser, forKey: "isProUser")
        userDefaults.set(currentSubscription.rawValue, forKey: "currentSubscription")
        userDefaults.set(lessonTokens, forKey: "lessonTokens")
        userDefaults.set(subscriptionStatus.rawValue, forKey: "subscriptionStatus")
        
        // 💾 Persist to Core Data
        persistenceService.saveSubscriptionData(SubscriptionData(
            tier: currentSubscription.rawValue,
            isActive: isProUser,
            tokens: lessonTokens,
            status: subscriptionStatus.rawValue
        ))
    }
    
    // MARK: - Analytics & Tracking
    private func trackPurchaseEvent(tier: SubscriptionTier, success: Bool) {
        // 📊 Track purchase events for analytics
        let event = [
            "event": "subscription_purchase",
            "tier": tier.rawValue,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        print("📊 Purchase Event: \(event)")
        // Integrate with your analytics service (Firebase, Mixpanel, etc.)
    }
    
    private func trackTokenPurchase(count: Int, success: Bool) {
        let event = [
            "event": "token_purchase",
            "count": count,
            "success": success,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        print("📊 Token Purchase: \(event)")
    }
    
    private func trackTokenConsumption() {
        let event = [
            "event": "token_consumed",
            "remaining": lessonTokens,
            "timestamp": Date().timeIntervalSince1970
        ] as [String : Any]
        
        print("📊 Token Consumed: \(event)")
    }
    
    // MARK: - Observers Setup
    private func setupObservers() {
        // 🔄 Refresh status when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Development Helpers
    private func simulatePurchase(_ tier: SubscriptionTier) {
        currentSubscription = tier
        isProUser = tier != .free
        subscriptionStatus = tier != .free ? .subscribed : .notSubscribed
        
        if isProUser {
            lessonTokens = 999
        }
        
        saveState()
        print("🚧 Simulated purchase: \(tier)")
    }
}


// MARK: - Supporting Types
enum ProductionPremiumFeature {
    case premiumLessons
    case watermarkRemoval
    case customImageImport
    case advancedAI
    case unlimitedTokens
    case cloudSync
    case prioritySupport
}

struct SubscriptionData: Codable {
    let tier: String
    let isActive: Bool
    let tokens: Int
    let status: String
}
