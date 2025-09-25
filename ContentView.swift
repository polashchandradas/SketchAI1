import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var navigationState: NavigationState
    
    var body: some View {
        if userProfileService.isFirstLaunch {
            OnboardingView()
                .onAppear {
                    print("🚀 [CONTENTVIEW] Showing OnboardingView - isFirstLaunch: \(userProfileService.isFirstLaunch)")
                }
        } else {
            MainTabView()
                .onAppear {
                    print("🚀 [CONTENTVIEW] Showing MainTabView - isFirstLaunch: \(userProfileService.isFirstLaunch)")
                }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var monetizationService: MonetizationService
    
    var body: some View {
        TabView(selection: $navigationState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: TabType.home.iconName)
                    Text(TabType.home.title)
                }
                .tag(TabType.home)
            
            LessonsView()
                .tabItem {
                    Image(systemName: TabType.lessons.iconName)
                    Text(TabType.lessons.title)
                }
                .tag(TabType.lessons)
            
            GalleryView()
                .tabItem {
                    Image(systemName: TabType.gallery.iconName)
                    Text(TabType.gallery.title)
                }
                .tag(TabType.gallery)
            
            ProfileView()
                .tabItem {
                    Image(systemName: TabType.profile.iconName)
                    Text(TabType.profile.title)
                }
                .tag(TabType.profile)
        }
        .sheet(isPresented: $monetizationService.shouldShowPaywall) {
            UnifiedPaywallView(
                subscriptionManager: monetizationService.subscriptionManager,
                context: monetizationService.paywallContext,
                showCloseButton: true
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $navigationState.showingPhotoImporter) {
            PhotoImporterView { selectedImage in
                // Handle selected image
                navigationState.showingPhotoImporter = false
                // TODO: Pass image to appropriate handler
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(UserProfileService(persistenceService: PersistenceService()))
        .environmentObject(NavigationState())
}
