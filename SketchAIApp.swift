import SwiftUI
import CoreData

@main
struct SketchAIApp: App {
    // MARK: - State Objects for Services
    // Use @StateObject to ensure each service is instantiated once and its
    // lifecycle is managed by SwiftUI for the entire app session.
    @StateObject private var persistenceService = PersistenceService()
    @StateObject private var userProfileService: UserProfileService
    @StateObject private var lessonService: LessonService
    @StateObject private var monetizationService = MonetizationService()
    @StateObject private var navigationState = NavigationState()
    
    // Environment for lifecycle management
    @Environment(\.scenePhase) var scenePhase

    init() {
        // Initialize services that depend on others.
        // This pattern allows for clean dependency injection between services.
        let persistence = PersistenceService()
        self._persistenceService = StateObject(wrappedValue: persistence)
        self._userProfileService = StateObject(wrappedValue: UserProfileService(persistenceService: persistence))
        self._lessonService = StateObject(wrappedValue: LessonService(persistenceService: persistence))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ENHANCED: Reduced @EnvironmentObject usage - only inject essential services
                .environmentObject(userProfileService)
                .environmentObject(lessonService)
                .environmentObject(monetizationService)
                .environmentObject(navigationState)
                // The managedObjectContext for Core Data is also injected (if available).
                .environment(\.managedObjectContext, persistenceService.context)
                .preferredColorScheme(nil)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                print("App moving to background/inactive state. Saving context.")
                persistenceService.saveContext()
            }
        }
    }
}

