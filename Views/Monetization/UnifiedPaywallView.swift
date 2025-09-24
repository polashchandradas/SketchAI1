import SwiftUI
import Combine

// MARK: - Unified Context-Aware Paywall
// This replaces both PaywallView and PaywallViewController with a single, superior implementation

struct UnifiedPaywallView: View {
    @ObservedObject var subscriptionManager: ProductionSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    // Configuration
    private let context: PaywallContext
    private let showCloseButton: Bool
    
    // State
    @State private var selectedTier: SubscriptionTier = .proMonthly
    @State private var showingTokenPurchase = false
    @State private var isAnimating = false
    @State private var currentFeatureIndex = 0
    
    init(
        subscriptionManager: ProductionSubscriptionManager,
        context: PaywallContext = .general,
        showCloseButton: Bool = true
    ) {
        self.subscriptionManager = subscriptionManager
        self.context = context
        self.showCloseButton = showCloseButton
    }
    
    var body: some View {
        ZStack {
            // 🎨 Dynamic background based on context
            contextualBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 📱 Header with context-aware messaging
                    ContextualHeaderView(
                        context: context,
                        showCloseButton: showCloseButton,
                        onClose: { dismiss() }
                    )
                    
                    // ✨ Animated features showcase
                    AnimatedFeaturesShowcase(
                        context: context,
                        isAnimating: $isAnimating,
                        currentIndex: $currentFeatureIndex
                    )
                    
                    // 💰 Smart subscription plans
                    SmartSubscriptionPlansView(
                        selectedTier: $selectedTier,
                        context: context,
                        subscriptionManager: subscriptionManager
                    )
                    
                    // 🎯 Context-aware CTA
                    ContextualCTAButton(
                        selectedTier: selectedTier,
                        context: context,
                        subscriptionManager: subscriptionManager,
                        onPurchase: { handlePurchase() }
                    )
                    
                    // 🔄 Alternative options (tokens, restore)
                    AlternativeOptionsSection(
                        context: context,
                        subscriptionManager: subscriptionManager,
                        showTokenPurchase: $showingTokenPurchase
                    )
                    
                    // ⚖️ Trust indicators and legal
                    TrustIndicatorsView()
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            startAnimations()
        }
        .sheet(isPresented: $showingTokenPurchase) {
            TokenPurchaseView(subscriptionManager: subscriptionManager)
        }
        .alert("Error", isPresented: .constant(subscriptionManager.lastError != nil)) {
            Button("OK") {
                subscriptionManager.lastError = nil
            }
        } message: {
            Text(subscriptionManager.lastError?.localizedDescription ?? "")
        }
    }
    
    // MARK: - Contextual Background
    private var contextualBackground: some View {
        Group {
            switch context {
            case .lessonGate:
                // 📚 Learning-focused gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.6), Color.purple.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .exportMenu:
                // 🎨 Creative-focused gradient
                LinearGradient(
                    colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.6), Color.red.opacity(0.4)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            case .sharingMenu:
                // 🌐 Social-focused gradient
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.teal.opacity(0.6), Color.cyan.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .drawingCanvas:
                // ✏️ Creativity-focused gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6), Color.blue.opacity(0.4)],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            case .general:
                // 🎯 General appeal gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.5), Color.pink.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .profile:
                // 👤 Profile-focused gradient
                LinearGradient(
                    colors: [Color.indigo.opacity(0.7), Color.blue.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .exportGate:
                // 💧 Export-focused gradient
                LinearGradient(
                    colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.6), Color.red.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .imageImportGate:
                // 📸 Import-focused gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6), Color.teal.opacity(0.4)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
        }
    }
    
    // MARK: - Actions
    private func handlePurchase() {
        Task {
            let success = await subscriptionManager.purchaseSubscription(selectedTier)
            if success {
                dismiss()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 0.8)) {
            isAnimating = true
        }
        
        // 🔄 Cycle through features
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                currentFeatureIndex = (currentFeatureIndex + 1) % getContextualFeatures().count
            }
        }
    }
    
    private func getContextualFeatures() -> [ContextualFeature] {
        switch context {
        case .lessonGate:
            return [
                ContextualFeature(
                    icon: "infinity.circle.fill",
                    title: "Unlimited Lessons",
                    description: "Access our entire premium library",
                    color: .blue
                ),
                ContextualFeature(
                    icon: "star.circle.fill", 
                    title: "Advanced AI Guidance",
                    description: "Get detailed feedback on every stroke",
                    color: .purple
                ),
                ContextualFeature(
                    icon: "person.crop.circle.badge.checkmark.fill",
                    title: "Personalized Learning",
                    description: "AI adapts to your skill level",
                    color: .green
                )
            ]
        case .exportMenu:
            return [
                ContextualFeature(
                    icon: "drop.fill",
                    title: "Watermark-Free Exports",
                    description: "Clean videos ready for sharing",
                    color: .orange
                ),
                ContextualFeature(
                    icon: "video.circle.fill",
                    title: "HD Time-lapse Videos",
                    description: "Export in stunning quality",
                    color: .red
                ),
                ContextualFeature(
                    icon: "square.and.arrow.up.circle.fill",
                    title: "Multiple Export Formats",
                    description: "Choose from various file types",
                    color: .pink
                )
            ]
        case .sharingMenu:
            return [
                ContextualFeature(
                    icon: "heart.circle.fill",
                    title: "Social Media Ready",
                    description: "Perfect for Instagram & TikTok",
                    color: .pink
                ),
                ContextualFeature(
                    icon: "sparkles",
                    title: "Before/After Comparisons",
                    description: "Show your artistic journey",
                    color: .cyan
                ),
                ContextualFeature(
                    icon: "crown.fill",
                    title: "Premium Sharing Tools",
                    description: "Advanced editing options",
                    color: .yellow
                )
            ]
        case .drawingCanvas:
            return [
                ContextualFeature(
                    icon: "wand.and.rays",
                    title: "Advanced AI Coach",
                    description: "Real-time stroke guidance",
                    color: .purple
                ),
                ContextualFeature(
                    icon: "paintbrush.pointed.fill",
                    title: "Premium Drawing Tools",
                    description: "Professional-grade brushes",
                    color: .blue
                ),
                ContextualFeature(
                    icon: "photo.badge.plus.fill",
                    title: "Import Your Photos",
                    description: "Turn any image into a lesson",
                    color: .green
                )
            ]
        case .general:
            return [
                ContextualFeature(
                    icon: "infinity.circle.fill",
                    title: "Unlimited Everything",
                    description: "Full access to all features",
                    color: .blue
                ),
                ContextualFeature(
                    icon: "star.circle.fill",
                    title: "Premium Experience",
                    description: "No limits, no watermarks",
                    color: .purple
                ),
                ContextualFeature(
                    icon: "heart.circle.fill",
                    title: "Join the Community",
                    description: "Connect with fellow artists",
                    color: .pink
                )
            ]
        case .profile:
            return [
                ContextualFeature(
                    icon: "crown.fill",
                    title: "SketchAI Pro",
                    description: "Unlock all premium features",
                    color: .yellow
                ),
                ContextualFeature(
                    icon: "infinity.circle.fill",
                    title: "Unlimited Access",
                    description: "All lessons and tools",
                    color: .blue
                ),
                ContextualFeature(
                    icon: "star.circle.fill",
                    title: "Premium Support",
                    description: "Priority customer service",
                    color: .purple
                )
            ]
        case .exportGate:
            return [
                ContextualFeature(
                    icon: "drop.fill",
                    title: "Remove Watermarks",
                    description: "Export clean, professional content",
                    color: .orange
                ),
                ContextualFeature(
                    icon: "video.circle.fill",
                    title: "HD Export Quality",
                    description: "Full resolution exports",
                    color: .red
                ),
                ContextualFeature(
                    icon: "square.and.arrow.up.circle.fill",
                    title: "Multiple Formats",
                    description: "Export in various file types",
                    color: .pink
                )
            ]
        case .imageImportGate:
            return [
                ContextualFeature(
                    icon: "photo.badge.plus.fill",
                    title: "Import Any Image",
                    description: "Turn photos into drawing lessons",
                    color: .blue
                ),
                ContextualFeature(
                    icon: "wand.and.rays",
                    title: "AI Analysis",
                    description: "Automatic proportions and guides",
                    color: .purple
                ),
                ContextualFeature(
                    icon: "paintbrush.pointed.fill",
                    title: "Custom Lessons",
                    description: "Personalized learning experience",
                    color: .green
                )
            ]
        }
    }
}

// MARK: - Contextual Header View
struct ContextualHeaderView: View {
    let context: PaywallContext
    let showCloseButton: Bool
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 🚫 Close button
            if showCloseButton {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // 🎯 Context-specific icon
            contextIcon
                .font(.system(size: 64))
                .foregroundColor(.white)
                .shadow(radius: 10)
            
            // 📝 Context-specific messaging
            VStack(spacing: 8) {
                Text(contextTitle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(contextSubtitle)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private var contextIcon: Image {
        switch context {
        case .lessonGate:
            return Image(systemName: "graduationcap.fill")
        case .exportMenu:
            return Image(systemName: "square.and.arrow.up.fill")
        case .sharingMenu:
            return Image(systemName: "heart.fill")
        case .drawingCanvas:
            return Image(systemName: "paintbrush.pointed.fill")
        case .general:
            return Image(systemName: "crown.fill")
        case .profile:
            return Image(systemName: "person.crop.circle.fill")
        case .exportGate:
            return Image(systemName: "drop.fill")
        case .imageImportGate:
            return Image(systemName: "photo.badge.plus.fill")
        }
    }
    
    private var contextTitle: String {
        switch context {
        case .lessonGate:
            return "Unlock This Amazing Lesson"
        case .exportMenu:
            return "Share Your Art Without Limits"
        case .sharingMenu:
            return "Share Your Creativity"
        case .drawingCanvas:
            return "Enhance Your Artistic Journey"
        case .general:
            return "Unlock Your Full Potential"
        case .profile:
            return "Complete Your Artist Profile"
        case .exportGate:
            return "Share Clean, Beautiful Art"
        case .imageImportGate:
            return "Turn Photos Into Art Lessons"
        }
    }
    
    private var contextSubtitle: String {
        switch context {
        case .lessonGate:
            return "Get unlimited access to amazing lessons and helpful features"
        case .exportMenu:
            return "Share your beautiful art without any watermarks"
        case .sharingMenu:
            return "Create amazing before/after videos to show your progress"
        case .drawingCanvas:
            return "Get helpful AI guidance and awesome drawing tools"
        case .general:
            return "Unlock your full creative potential with SketchAI Pro"
        case .profile:
            return "Get access to all the amazing features and personalized tools"
        case .exportGate:
            return "Share your clean, beautiful artwork without watermarks"
        case .imageImportGate:
            return "Turn any photo into a fun, personalized drawing lesson"
        }
    }
}

// MARK: - Animated Features Showcase
struct AnimatedFeaturesShowcase: View {
    let context: PaywallContext
    @Binding var isAnimating: Bool
    @Binding var currentIndex: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Why Choose Pro?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // 🎭 Animated feature cards
            TabView(selection: $currentIndex) {
                ForEach(Array(getContextualFeatures().enumerated()), id: \.offset) { index, feature in
                    FeatureShowcaseCard(feature: feature, isActive: currentIndex == index)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 160)
            .animation(.spring(response: 0.8, dampingFraction: 0.8), value: currentIndex)
            
            // 📍 Custom page indicators
            HStack(spacing: 8) {
                ForEach(0..<getContextualFeatures().count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.white : Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentIndex)
                }
            }
        }
    }
    
    private func getContextualFeatures() -> [ContextualFeature] {
        // This would use the same logic as in UnifiedPaywallView
        return [
            ContextualFeature(icon: "star.fill", title: "Premium", description: "Best features", color: .yellow),
            ContextualFeature(icon: "heart.fill", title: "Loved", description: "By artists", color: .red),
            ContextualFeature(icon: "crown.fill", title: "Elite", description: "Experience", color: .purple)
        ]
    }
}

// MARK: - Feature Showcase Card
struct FeatureShowcaseCard: View {
    let feature: ContextualFeature
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // ✨ Animated icon
            Image(systemName: feature.icon)
                .font(.system(size: 36))
                .foregroundColor(feature.color)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isActive)
            
            VStack(spacing: 6) {
                Text(feature.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(feature.color.opacity(0.6), lineWidth: isActive ? 2 : 0)
                )
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isActive)
    }
}

// MARK: - Smart Subscription Plans
struct SmartSubscriptionPlansView: View {
    @Binding var selectedTier: SubscriptionTier
    let context: PaywallContext
    let subscriptionManager: ProductionSubscriptionManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(getRecommendedTiers(), id: \.self) { tier in
                    SmartSubscriptionCard(
                        tier: tier,
                        isSelected: selectedTier == tier,
                        isRecommended: tier == getRecommendedTier(),
                        context: context
                    ) {
                        selectedTier = tier
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func getRecommendedTiers() -> [SubscriptionTier] {
        switch context {
        case .lessonGate:
            return [.proAnnual, .proMonthly, .proWeekly]
        case .exportMenu, .sharingMenu:
            return [.proMonthly, .proAnnual, .proWeekly]
        case .drawingCanvas:
            return [.proAnnual, .proMonthly, .proWeekly]
        case .general:
            return [.proAnnual, .proMonthly, .proWeekly]
        case .profile:
            return [.proAnnual, .proMonthly, .proWeekly]
        case .exportGate:
            return [.proMonthly, .proAnnual, .proWeekly]
        case .imageImportGate:
            return [.proAnnual, .proMonthly, .proWeekly]
        }
    }
    
    private func getRecommendedTier() -> SubscriptionTier {
        switch context {
        case .lessonGate, .drawingCanvas:
            return .proAnnual // Best value for learning
        case .exportMenu, .sharingMenu:
            return .proMonthly // Flexible for creators
        case .general:
            return .proAnnual // Best overall value
        case .profile:
            return .proAnnual // Best value for complete access
        case .exportGate:
            return .proMonthly // Flexible for export needs
        case .imageImportGate:
            return .proAnnual // Best value for custom lessons
        }
    }
}

// MARK: - Smart Subscription Card
struct SmartSubscriptionCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isRecommended: Bool
    let context: PaywallContext
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tier.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                        
                        if let savings = tier.savings {
                            Text(savings)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(getContextualSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tier.price)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if tier != .free {
                        Text(getPeriodText())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // 📍 Selection indicator
                Circle()
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .padding(.leading, 12)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    private func getContextualSubtitle() -> String {
        switch context {
        case .lessonGate:
            return "Unlimited lessons + advanced AI"
        case .exportMenu:
            return "HD exports without watermarks"
        case .sharingMenu:
            return "Premium sharing tools"
        case .drawingCanvas:
            return "Advanced AI guidance"
        case .general:
            return "All premium features"
        case .profile:
            return "Complete profile access"
        case .exportGate:
            return "Clean, professional exports"
        case .imageImportGate:
            return "Custom AI-generated lessons"
        }
    }
    
    private func getPeriodText() -> String {
        switch tier {
        case .proWeekly: return "per week"
        case .proMonthly: return "per month"
        case .proAnnual: return "per year"
        case .free: return ""
        }
    }
}

// MARK: - Contextual CTA Button
struct ContextualCTAButton: View {
    let selectedTier: SubscriptionTier
    let context: PaywallContext
    let subscriptionManager: ProductionSubscriptionManager
    let onPurchase: () -> Void
    
    var body: some View {
        Button(action: onPurchase) {
            HStack {
                if subscriptionManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: getCTAIcon())
                        .font(.title3)
                }
                
                Text(getCTAText())
                    .fontWeight(.bold)
                    .font(.title3)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(getCTAGradient())
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .disabled(subscriptionManager.isLoading)
        .scaleEffect(subscriptionManager.isLoading ? 0.95 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: subscriptionManager.isLoading)
    }
    
    private func getCTAIcon() -> String {
        switch context {
        case .lessonGate: return "graduationcap.fill"
        case .exportMenu: return "square.and.arrow.up.fill"
        case .sharingMenu: return "heart.fill"
        case .drawingCanvas: return "paintbrush.pointed.fill"
        case .general: return "crown.fill"
        case .profile: return "person.crop.circle.fill"
        case .exportGate: return "drop.fill"
        case .imageImportGate: return "photo.badge.plus.fill"
        }
    }
    
    @MainActor private func getCTAText() -> String {
        if subscriptionManager.isLoading {
            return "Processing..."
        }
        
        switch context {
        case .lessonGate: return "Unlock All Lessons"
        case .exportMenu: return "Remove Watermarks"
        case .sharingMenu: return "Upgrade Sharing"
        case .drawingCanvas: return "Get Pro Tools"
        case .general: return "Start Free Trial"
        case .profile: return "Upgrade Profile"
        case .exportGate: return "Remove Watermarks"
        case .imageImportGate: return "Import Images"
        }
    }
    
    private func getCTAGradient() -> LinearGradient {
        switch context {
        case .lessonGate:
            return LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
        case .exportMenu:
            return LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
        case .sharingMenu:
            return LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing)
        case .drawingCanvas:
            return LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
        case .general:
            return LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
        case .profile:
            return LinearGradient(colors: [.indigo, .blue], startPoint: .leading, endPoint: .trailing)
        case .exportGate:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
        case .imageImportGate:
            return LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
        }
    }
}

// MARK: - Alternative Options Section
struct AlternativeOptionsSection: View {
    let context: PaywallContext
    let subscriptionManager: ProductionSubscriptionManager
    @Binding var showTokenPurchase: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 🪙 Token option (if relevant for context)
            if shouldShowTokenOption() {
                Button("Just This Once - 1 Token ($0.99)") {
                    showTokenPurchase = true
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
            }
            
            // 🔄 Restore purchases
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
            
            // ❓ Support
            Button("Need Help?") {
                // Open support
            }
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
        }
    }
    
    private func shouldShowTokenOption() -> Bool {
        switch context {
        case .lessonGate: return true
        case .exportMenu, .sharingMenu, .drawingCanvas: return false
        case .general: return true
        case .profile: return true
        case .exportGate: return true
        case .imageImportGate: return true
        }
    }
}

// MARK: - Trust Indicators
struct TrustIndicatorsView: View {
    var body: some View {
        VStack(spacing: 12) {
            // 🔒 Security badge
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                Text("Secure & Private")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // ⭐ Social proof
            HStack(spacing: 4) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                Text("4.9/5 from 10,000+ artists")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // 📜 Legal links
            HStack(spacing: 16) {
                Button("Terms") { /* Open terms */ }
                Button("Privacy") { /* Open privacy */ }
                Button("Support") { /* Open support */ }
            }
            .font(.caption2)
            .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Token Purchase View
struct TokenPurchaseView: View {
    @ObservedObject var subscriptionManager: ProductionSubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 🪙 Token options
                VStack(spacing: 16) {
                    Text("Buy Lesson Tokens")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Perfect for trying out premium lessons")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        TokenOptionCard(count: 1, price: "$0.99", subscriptionManager: subscriptionManager)
                        TokenOptionCard(count: 10, price: "$7.99", badge: "Save 20%", subscriptionManager: subscriptionManager)
                        TokenOptionCard(count: 25, price: "$17.99", badge: "Best Value", subscriptionManager: subscriptionManager)
                    }
                }
                
                Spacer()
                
                // 💡 Suggestion to upgrade
                VStack(spacing: 12) {
                    Text("💡 Pro Tip")
                        .font(.headline)
                    
                    Text("Get unlimited lessons for less than 10 tokens per month with Pro!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("View Pro Plans") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Lesson Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Token Option Card
struct TokenOptionCard: View {
    let count: Int
    let price: String
    let badge: String?
    let subscriptionManager: ProductionSubscriptionManager
    
    init(count: Int, price: String, badge: String? = nil, subscriptionManager: ProductionSubscriptionManager) {
        self.count = count
        self.price = price
        self.badge = badge
        self.subscriptionManager = subscriptionManager
    }
    
    var body: some View {
        Button {
            Task {
                await subscriptionManager.purchaseTokens(count)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(count) Token\(count > 1 ? "s" : "")")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text("Unlock \(count) premium lesson\(count > 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(price)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types
struct ContextualFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// This would be integrated with your existing PaywallContext enum
extension PaywallContext {
    // Add any additional context-specific properties here
}

#Preview {
    UnifiedPaywallView(
        subscriptionManager: ProductionSubscriptionManager(persistenceService: PersistenceService()),
        context: .lessonGate
    )
}
