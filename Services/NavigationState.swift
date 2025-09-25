import Foundation
import SwiftUI
import Combine

// MARK: - Navigation State Service
class NavigationState: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedTab: TabType = .home
    @Published var navigationPath = NavigationPath()
    @Published var showingOnboarding: Bool = false
    @Published var showingLessonDetail: Bool = false
    @Published var selectedLesson: Lesson?
    
    // MARK: - Sheet and Alert States
    @Published var showingSettingsSheet: Bool = false
    @Published var showingGallerySheet: Bool = false
    @Published var showingExportSheet: Bool = false
    @Published var showingPaywallSheet: Bool = false
    @Published var showingPhotoImporter: Bool = false
    
    // MARK: - Drawing Flow States
    @Published var isInDrawingSession: Bool = false
    @Published var currentDrawingLesson: Lesson?
    @Published var shouldShowDrawingCompletion: Bool = false
    
    // MARK: - Deep Link Handling
    @Published var pendingDeepLink: URL?
    
    // MARK: - Tab Navigation
    func selectTab(_ tab: TabType) {
        selectedTab = tab
    }
    
    func resetToHomeTab() {
        selectedTab = .home
        navigationPath = NavigationPath()
    }
    
    // MARK: - Lesson Navigation
    func showLessonDetail(_ lesson: Lesson) {
        selectedLesson = lesson
        showingLessonDetail = true
    }
    
    func hideLessonDetail() {
        showingLessonDetail = false
        selectedLesson = nil
    }
    
    func startDrawingSession(for lesson: Lesson) {
        currentDrawingLesson = lesson
        isInDrawingSession = true
        selectedTab = .lessons // Ensure we're on the right tab
    }
    
    func endDrawingSession() {
        isInDrawingSession = false
        currentDrawingLesson = nil
        shouldShowDrawingCompletion = false
    }
    
    func showDrawingCompletion() {
        shouldShowDrawingCompletion = true
    }
    
    // MARK: - Sheet Management
    func showSettings() {
        showingSettingsSheet = true
    }
    
    func hideSettings() {
        showingSettingsSheet = false
    }
    
    func showGallery() {
        showingGallerySheet = true
    }
    
    func hideGallery() {
        showingGallerySheet = false
    }
    
    func showExportOptions() {
        showingExportSheet = true
    }
    
    func hideExportOptions() {
        showingExportSheet = false
    }
    
    func showPaywall() {
        showingPaywallSheet = true
    }
    
    func hidePaywall() {
        showingPaywallSheet = false
    }
    
    // MARK: - Onboarding Flow
    func startOnboarding() {
        showingOnboarding = true
    }
    
    func completeOnboarding() {
        showingOnboarding = false
    }
    
    // MARK: - Navigation Path Management
    func pushToPath<V: Hashable>(_ value: V) {
        navigationPath.append(value)
    }
    
    func popFromPath() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
    
    // MARK: - Deep Link Handling
    func handleDeepLink(_ url: URL) {
        pendingDeepLink = url
        processDeepLink(url)
    }
    
    private func processDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }
        
        switch host {
        case "lesson":
            handleLessonDeepLink(components)
        case "gallery":
            handleGalleryDeepLink()
        case "profile":
            handleProfileDeepLink()
        case "settings":
            handleSettingsDeepLink()
        default:
            break
        }
        
        pendingDeepLink = nil
    }
    
    private func handleLessonDeepLink(_ components: URLComponents) {
        // Extract lesson ID from path or query parameters
        let pathComponents = components.path.components(separatedBy: "/")
        if pathComponents.count > 1 {
            let lessonID = pathComponents[1]
            // Find lesson by ID and navigate to it
            if let lesson = LessonData.sampleLessons.first(where: { $0.id.uuidString == lessonID }) {
                selectedTab = .lessons
                showLessonDetail(lesson)
            }
        }
    }
    
    private func handleGalleryDeepLink() {
        selectedTab = .gallery
    }
    
    private func handleProfileDeepLink() {
        selectedTab = .profile
    }
    
    private func handleSettingsDeepLink() {
        selectedTab = .profile
        showSettings()
    }
    
    // MARK: - State Reset
    func resetAllStates() {
        selectedTab = .home
        navigationPath = NavigationPath()
        showingOnboarding = false
        showingLessonDetail = false
        selectedLesson = nil
        
        showingSettingsSheet = false
        showingGallerySheet = false
        showingExportSheet = false
        showingPaywallSheet = false
        
        isInDrawingSession = false
        currentDrawingLesson = nil
        shouldShowDrawingCompletion = false
        
        pendingDeepLink = nil
    }
    
    // MARK: - Navigation Analytics
    func getCurrentNavigationState() -> NavigationAnalytics {
        return NavigationAnalytics(
            currentTab: selectedTab,
            isInDrawingSession: isInDrawingSession,
            hasActiveLessonDetail: showingLessonDetail,
            activeSheets: getActiveSheets(),
            navigationDepth: navigationPath.count
        )
    }
    
    private func getActiveSheets() -> [String] {
        var activeSheets: [String] = []
        
        if showingOnboarding { activeSheets.append("onboarding") }
        if showingLessonDetail { activeSheets.append("lessonDetail") }
        if showingSettingsSheet { activeSheets.append("settings") }
        if showingGallerySheet { activeSheets.append("gallery") }
        if showingExportSheet { activeSheets.append("export") }
        if showingPaywallSheet { activeSheets.append("paywall") }
        
        return activeSheets
    }
}

// MARK: - Supporting Types
struct NavigationAnalytics {
    let currentTab: TabType
    let isInDrawingSession: Bool
    let hasActiveLessonDetail: Bool
    let activeSheets: [String]
    let navigationDepth: Int
}
