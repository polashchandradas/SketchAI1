import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var monetizationService: MonetizationService
    @State private var showPaywall = false
    @State private var showSettings = false
    @State private var showAchievements = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    ProfileHeaderView()
                    
                    // Stats section
                    StatsGridView()
                    
                    // Subscription status
                    SubscriptionStatusView {
                        showPaywall = true
                    }
                    
                    // Achievements preview
                    AchievementsPreviewView {
                        showAchievements = true
                    }
                    
                    // Menu options
                    ProfileMenuView {
                        showSettings = true
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 1) // Small padding to ensure content doesn't touch top
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showPaywall) {
            UnifiedPaywallView(
                subscriptionManager: monetizationService.subscriptionManager,
                context: .profile
            )
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                Text("Settings")
                    .font(.title2)
                    .padding()
                    .navigationTitle("Settings")
            }
        }
        .sheet(isPresented: $showAchievements) {
            NavigationStack {
                Text("Achievements")
                    .font(.title2)
                    .padding()
                    .navigationTitle("Achievements")
            }
        }
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var monetizationService: MonetizationService
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile picture
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text("U")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if monetizationService.isPro {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .padding(4)
                                .background(Circle().fill(Color.white))
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            
            VStack(spacing: 4) {
                Text("Artist")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("artist@sketchai.com")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if monetizationService.isPro {
                    Text("SketchAI Pro")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct StatsGridView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var lessonService: LessonService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    icon: "flame.fill",
                    value: "\(userProfileService.streakCount)",
                    label: "Day Streak",
                    color: .orange
                )
                
                StatCard(
                    icon: "paintbrush.pointed.fill",
                    value: "\(userProfileService.userDrawings.count)",
                    label: "Drawings",
                    color: .blue
                )
                
                StatCard(
                    icon: "book.fill",
                    value: "\(completedLessonsCount)",
                    label: "Lessons Done",
                    color: .green
                )
                
                StatCard(
                    icon: "star.fill",
                    value: "\(unlockedAchievementsCount)",
                    label: "Achievements",
                    color: .yellow
                )
            }
        }
    }
    
    private var completedLessonsCount: Int {
        lessonService.lessons.filter { $0.isCompleted }.count
    }
    
    private var unlockedAchievementsCount: Int {
        userProfileService.achievements.filter { $0.isUnlocked }.count
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SubscriptionStatusView: View {
    @EnvironmentObject var monetizationService: MonetizationService
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription")
                .font(.headline)
            
            if monetizationService.isPro {
                ProStatusCard()
            } else {
                FreeStatusCard(onUpgrade: onUpgrade)
            }
        }
    }
}

struct ProStatusCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("SketchAI Pro")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text("All features unlocked")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Manage") {
                // Open subscription management in App Store
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
                
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}

struct FreeStatusCard: View {
    let onUpgrade: () -> Void
    
    var body: some View {
        Button(action: onUpgrade) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Plan")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Limited features • Upgrade for full access")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AchievementsPreviewView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    let onViewAll: () -> Void
    
    var recentAchievements: [Achievement] {
        Array(userProfileService.achievements.filter { $0.isUnlocked }.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                
                Spacer()
                
                Button("View All", action: onViewAll)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if recentAchievements.isEmpty {
                EmptyAchievementsView()
            } else {
                VStack(spacing: 8) {
                    ForEach(recentAchievements) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
        }
    }
}

struct AchievementRow: View {
    @ObservedObject var achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.iconName)
                .foregroundColor(.yellow)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyAchievementsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No achievements yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Complete lessons to unlock achievements!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProfileMenuView: View {
    let onSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("More")
                .font(.headline)
            
            VStack(spacing: 1) {
                MenuRow(
                    icon: "gear",
                    title: "Settings",
                    color: .gray,
                    action: onSettings
                )
                
                MenuRow(
                    icon: "questionmark.circle",
                    title: "Help & Support",
                    color: .blue
                ) {
                    // Open help and support
                    if let url = URL(string: "https://support.sketchai.app/help") {
                        UIApplication.shared.open(url)
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
                
                MenuRow(
                    icon: "star.bubble",
                    title: "Rate SketchAI",
                    color: .yellow
                ) {
                    // Open App Store review page
                    if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                MenuRow(
                    icon: "square.and.arrow.up",
                    title: "Share App",
                    color: .green
                ) {
                    // Present share sheet for the app
                    let appStoreURL = "https://apps.apple.com/app/sketchai"
                    let shareText = "Check out SketchAI - the AI-powered drawing app that teaches you to draw! 🎨✨"
                    
                    let activityVC = UIActivityViewController(
                        activityItems: [shareText, URL(string: appStoreURL)!],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserProfileService(persistenceService: PersistenceService()))
        .environmentObject(MonetizationService())
        .environmentObject(LessonService(persistenceService: PersistenceService()))
}

