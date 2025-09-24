import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @State private var currentPage = 0
    @State private var animationProgress: [Double] = [0, 0, 0, 0]
    @State private var floatingElements: [FloatingElement] = []
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let onboardingPages = [
        OnboardingPage(
            title: "Welcome to SketchAI",
            subtitle: "Your AI-powered drawing tutor",
            description: "Learn to draw anything with step-by-step AI guidance that adapts to your skill level.",
            imageName: "sketchai_welcome",
            backgroundColor: .blue
        ),
        OnboardingPage(
            title: "AI-Powered Guidance",
            subtitle: "Smart drawing assistance",
            description: "Our AI analyzes your drawings in real-time and provides instant feedback to improve your technique.",
            imageName: "ai_guidance",
            backgroundColor: .purple
        ),
        OnboardingPage(
            title: "Learn by Doing",
            subtitle: "Hands-on tutorials",
            description: "Practice with structured lessons covering faces, animals, objects, and advanced techniques.",
            imageName: "learn_drawing",
            backgroundColor: .green
        ),
        OnboardingPage(
            title: "Share Your Art",
            subtitle: "Show off your progress",
            description: "Export time-lapse videos of your drawing process and share your masterpieces on social media.",
            imageName: "share_art",
            backgroundColor: .orange
        )
    ]
    
    var body: some View {
        ZStack {
            // Enhanced background with floating elements
            ZStack {
                // Animated gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        onboardingPages[currentPage].backgroundColor.opacity(0.8),
                        onboardingPages[currentPage].backgroundColor.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .animation(.easeInOut(duration: 0.8), value: currentPage)
                
                // Floating elements for visual interest
                ForEach(floatingElements, id: \.id) { element in
                    Circle()
                        .fill(element.color.opacity(element.opacity))
                        .frame(width: element.size, height: element.size)
                        .position(element.position)
                        .blur(radius: element.blur)
                        .animation(.easeInOut(duration: element.duration).repeatForever(autoreverses: true), value: element.position)
                }
            }
            
            VStack(spacing: 0) {
                // Enhanced skip button
                HStack {
                    Spacer()
                    EnhancedSecondaryButton("Skip") {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            userProfileService.completeOnboarding()
                        }
                    }
                    .scaleEffect(0.8)
                }
                .padding()
                .padding(.top, 20) // Extra padding for status bar
                
                Spacer()
                
                // Enhanced onboarding content with custom page transitions and swipe gestures
                GeometryReader { geometry in
                    ZStack {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            EnhancedOnboardingPageView(
                                page: onboardingPages[index],
                                animationProgress: animationProgress[index],
                                isActive: currentPage == index
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(x: calculatePageOffset(for: index, screenWidth: geometry.size.width) + (isDragging ? dragOffset : 0))
                            .opacity(calculatePageOpacity(for: index))
                            .scaleEffect(calculatePageScale(for: index))
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                dragOffset = value.translation.width * 0.5 // Dampen the drag effect
                            }
                            .onEnded { value in
                                isDragging = false
                                dragOffset = 0
                                
                                let threshold: CGFloat = 50
                                if value.translation.width > threshold && currentPage > 0 {
                                    // Swipe right - go to previous page
                                    navigateToPage(currentPage - 1)
                                } else if value.translation.width < -threshold && currentPage < onboardingPages.count - 1 {
                                    // Swipe left - go to next page
                                    navigateToPage(currentPage + 1)
                                }
                            }
                    )
                }
                .frame(height: 500)
                .clipped()
                
                // Page indicators and navigation
                VStack(spacing: 30) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<onboardingPages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: currentPage == index ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                        }
                    }
                    .padding(10)
                    
                    // Navigation buttons
                    HStack {
                        if currentPage > 0 {
                            EnhancedSecondaryButton("Back") {
                                navigateToPage(currentPage - 1)
                            }
                        }
                        
                        Spacer()
                        
                        EnhancedPrimaryButton(currentPage == onboardingPages.count - 1 ? "Get Started" : "Next") {
                            if currentPage == onboardingPages.count - 1 {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                                    userProfileService.completeOnboarding()
                                }
                            } else {
                                navigateToPage(currentPage + 1)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 40) // Padding for home indicator
            }
        }
        .ignoresSafeArea()
        .onAppear {
            setupFloatingElements()
            startPageAnimation()
        }
        .onChange(of: currentPage) { _ in
            startPageAnimation()
        }
    }
    
    // MARK: - Animation Helpers
    private func calculatePageOffset(for index: Int, screenWidth: CGFloat) -> CGFloat {
        return CGFloat(index - currentPage) * screenWidth
    }
    
    private func calculatePageOpacity(for index: Int) -> Double {
        let distance = abs(index - currentPage)
        return distance == 0 ? 1.0 : 0.3
    }
    
    private func calculatePageScale(for index: Int) -> CGFloat {
        let distance = abs(index - currentPage)
        return distance == 0 ? 1.0 : 0.8
    }
    
    private func navigateToPage(_ page: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentPage = page
        }
    }
    
    private func startPageAnimation() {
        // Reset all animations
        for i in 0..<animationProgress.count {
            animationProgress[i] = 0
        }
        
        // Animate current page
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            animationProgress[currentPage] = 1.0
        }
    }
    
    private func setupFloatingElements() {
        floatingElements = (0..<8).map { _ in
            FloatingElement(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...400), // Fixed width for consistent behavior
                    y: CGFloat.random(in: 0...800) // Fixed height for consistent behavior
                ),
                size: CGFloat.random(in: 20...80),
                color: [.white, .blue, .purple, .green, .orange].randomElement() ?? .white,
                opacity: Double.random(in: 0.1...0.3),
                blur: CGFloat.random(in: 2...8),
                duration: Double.random(in: 3...8)
            )
        }
        
        // Animate floating elements
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            for i in floatingElements.indices {
                withAnimation(.easeInOut(duration: floatingElements[i].duration).repeatForever(autoreverses: true)) {
                    floatingElements[i].position = CGPoint(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Onboarding Page View
struct EnhancedOnboardingPageView: View {
    let page: OnboardingPage
    let animationProgress: Double
    let isActive: Bool
    
    @State private var iconRotation: Double = 0
    @State private var iconScale: CGFloat = 0.8
    @State private var textOffset: CGFloat = 50
    @State private var textOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Enhanced illustration with animations
            ZStack {
                // Background glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.backgroundColor.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(animationProgress * 1.2)
                    .opacity(animationProgress * 0.6)
                
                // Main illustration container
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
                    .overlay(
                        getPageIcon(for: page)
                            .font(.system(size: 80, weight: .light))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(iconRotation))
                            .scaleEffect(iconScale)
                    )
                    .shadow(color: page.backgroundColor.opacity(0.3), radius: 20, x: 0, y: 10)
                    .scaleEffect(0.8 + (animationProgress * 0.2))
                    .rotation3DEffect(
                        .degrees(isActive ? 0 : 15),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
            }
            
            // Enhanced text content with staggered animations
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .offset(y: textOffset * (1 - animationProgress))
                    .opacity(textOpacity)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: animationProgress)
                
                Text(page.subtitle)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .offset(y: textOffset * (1 - animationProgress))
                    .opacity(textOpacity * 0.9)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: animationProgress)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .offset(y: textOffset * (1 - animationProgress))
                    .opacity(textOpacity * 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animationProgress)
            }
        }
        .padding()
        .onChange(of: animationProgress) { progress in
            updateAnimations(progress: progress)
        }
    }
    
    private func getPageIcon(for page: OnboardingPage) -> Image {
        switch page.title {
        case "Welcome to SketchAI":
            return Image(systemName: "sparkles")
        case "AI-Powered Guidance":
            return Image(systemName: "brain.head.profile")
        case "Learn by Doing":
            return Image(systemName: "hand.draw")
        case "Share Your Art":
            return Image(systemName: "square.and.arrow.up.on.square")
        default:
            return Image(systemName: "star")
        }
    }
    
    private func updateAnimations(progress: Double) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            iconScale = 0.8 + (progress * 0.2)
            textOpacity = progress
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
            iconRotation = progress > 0.5 ? 360 : 0
        }
    }
}

// MARK: - Legacy Onboarding Page View (kept for compatibility)
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        EnhancedOnboardingPageView(
            page: page,
            animationProgress: 1.0,
            isActive: true
        )
    }
}

// MARK: - Supporting Data Structures
struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

struct FloatingElement {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let color: Color
    let opacity: Double
    let blur: CGFloat
    let duration: Double
}

#Preview {
    OnboardingView()
        .environmentObject(UserProfileService(persistenceService: PersistenceService()))
}

