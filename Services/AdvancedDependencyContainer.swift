import SwiftUI
import Foundation

// MARK: - Advanced Dependency Injection Container
// This implements a modern dependency injection pattern that reduces @EnvironmentObject overuse
// while maintaining clean architecture and testability.

// MARK: - Service Protocols
protocol UserProfileServiceProtocol: ObservableObject {
    var currentUser: User? { get }
    var userDrawings: [UserDrawing] { get }
    var recentDrawings: [UserDrawing] { get }
    var achievements: [Achievement] { get }
    var recentAchievements: [Achievement] { get }
    var streakCount: Int { get }
    var isFirstLaunch: Bool { get }
    
    func loadUserData()
    func addDrawing(_ drawing: UserDrawing)
    func markLessonCompleted(_ lessonId: UUID)
}

protocol LessonServiceProtocol: ObservableObject {
    var lessons: [Lesson] { get }
    var dailyLesson: Lesson? { get }
    var recentLessons: [Lesson] { get }
    var generatedLessons: [Lesson] { get }
    
    func markLessonCompleted(_ lessonId: UUID)
    func removeGeneratedLesson(_ lesson: Lesson)
}

protocol MonetizationServiceProtocol: ObservableObject {
    var isPro: Bool { get }
    var shouldShowPaywall: Bool { get set }
    var paywallContext: PaywallContext { get }
    var subscriptionManager: ProductionSubscriptionManager { get }
}

protocol NavigationStateProtocol: ObservableObject {
    var selectedTab: TabType { get set }
    var showingPhotoImporter: Bool { get set }
    var selectedLesson: Lesson? { get set }
}

// MARK: - Custom Environment Keys
private struct UserProfileServiceKey: EnvironmentKey {
    static let defaultValue: UserProfileServiceProtocol = MockUserProfileService()
}

private struct LessonServiceKey: EnvironmentKey {
    static let defaultValue: LessonServiceProtocol = MockLessonService()
}

private struct MonetizationServiceKey: EnvironmentKey {
    static let defaultValue: MonetizationServiceProtocol = MockMonetizationService()
}

private struct NavigationStateKey: EnvironmentKey {
    static let defaultValue: NavigationStateProtocol = MockNavigationState()
}

// MARK: - Environment Values Extension
extension EnvironmentValues {
    var userProfileService: UserProfileServiceProtocol {
        get { self[UserProfileServiceKey.self] }
        set { self[UserProfileServiceKey.self] = newValue }
    }
    
    var lessonService: LessonServiceProtocol {
        get { self[LessonServiceKey.self] }
        set { self[LessonServiceKey.self] = newValue }
    }
    
    var monetizationService: MonetizationServiceProtocol {
        get { self[MonetizationServiceKey.self] }
        set { self[MonetizationServiceKey.self] = newValue }
    }
    
    var navigationState: NavigationStateProtocol {
        get { self[NavigationStateKey.self] }
        set { self[NavigationStateKey.self] = newValue }
    }
}

// MARK: - Advanced Dependency Container
@Observable
class AdvancedDependencyContainer {
    // MARK: - Core Services
    let userProfileService: UserProfileServiceProtocol
    let lessonService: LessonServiceProtocol
    let monetizationService: MonetizationServiceProtocol
    let navigationState: NavigationStateProtocol
    
    // MARK: - Initialization
    init(
        userProfileService: UserProfileServiceProtocol? = nil,
        lessonService: LessonServiceProtocol? = nil,
        monetizationService: MonetizationServiceProtocol? = nil,
        navigationState: NavigationStateProtocol? = nil
    ) {
        // Use provided services or create default ones
        self.userProfileService = userProfileService ?? UserProfileService(persistenceService: PersistenceService())
        self.lessonService = lessonService ?? LessonService(persistenceService: PersistenceService())
        self.monetizationService = monetizationService ?? MonetizationService()
        self.navigationState = navigationState ?? NavigationState()
    }
    
    // MARK: - Environment Setup
    func setupEnvironment() -> some View {
        EmptyView()
            .environment(\.userProfileService, userProfileService)
            .environment(\.lessonService, lessonService)
            .environment(\.monetizationService, monetizationService)
            .environment(\.navigationState, navigationState)
    }
}

// MARK: - Mock Services for Testing
class MockUserProfileService: UserProfileServiceProtocol {
    @Published var currentUser: User? = User.sampleUser
    @Published var userDrawings: [UserDrawing] = []
    @Published var recentDrawings: [UserDrawing] = []
    @Published var achievements: [Achievement] = []
    @Published var recentAchievements: [Achievement] = []
    @Published var streakCount: Int = 5
    @Published var isFirstLaunch: Bool = false
    
    func loadUserData() {}
    func addDrawing(_ drawing: UserDrawing) {}
    func markLessonCompleted(_ lessonId: UUID) {}
}

class MockLessonService: LessonServiceProtocol {
    @Published var lessons: [Lesson] = LessonData.sampleLessons
    @Published var dailyLesson: Lesson? = LessonData.sampleLessons.first
    @Published var recentLessons: [Lesson] = []
    @Published var generatedLessons: [Lesson] = []
    
    func markLessonCompleted(_ lessonId: UUID) {}
    func removeGeneratedLesson(_ lesson: Lesson) {}
}

class MockMonetizationService: MonetizationServiceProtocol {
    @Published var isPro: Bool = false
    @Published var shouldShowPaywall: Bool = false
    @Published var paywallContext: PaywallContext = .general
    @Published var subscriptionManager: ProductionSubscriptionManager = ProductionSubscriptionManager()
}

class MockNavigationState: NavigationStateProtocol {
    @Published var selectedTab: TabType = .home
    @Published var showingPhotoImporter: Bool = false
    @Published var selectedLesson: Lesson? = nil
}

// MARK: - View Modifier for Easy Environment Setup
struct DependencyContainerModifier: ViewModifier {
    let container: AdvancedDependencyContainer
    
    func body(content: Content) -> some View {
        content
            .environment(\.userProfileService, container.userProfileService)
            .environment(\.lessonService, container.lessonService)
            .environment(\.monetizationService, container.monetizationService)
            .environment(\.navigationState, container.navigationState)
    }
}

extension View {
    func withDependencyContainer(_ container: AdvancedDependencyContainer) -> some View {
        modifier(DependencyContainerModifier(container: container))
    }
}

// MARK: - Service Extensions for Protocol Conformance
extension UserProfileService: UserProfileServiceProtocol {}
extension LessonService: LessonServiceProtocol {}
extension MonetizationService: MonetizationServiceProtocol {}
extension NavigationState: NavigationStateProtocol {}
