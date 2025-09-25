import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var monetizationService: MonetizationService
    @EnvironmentObject var lessonService: LessonService
    @EnvironmentObject var navigationState: NavigationState
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                mainContent
                    .padding()
            }
            .navigationTitle("SketchAI")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
        .sheet(isPresented: $showPaywall) {
            UnifiedPaywallView(
                subscriptionManager: monetizationService.subscriptionManager,
                context: .general
            )
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        LazyVStack(spacing: 20) {
            // Header with greeting
            HeaderView()
            
            // Streak and progress section
            StreakProgressView()
            
            // Daily lesson card
            DailyLessonCard()
            
            // Pro features banner (if not pro user)
            if !monetizationService.isPro {
                ProFeaturesBanner {
                    showPaywall = true
                }
            }
            
            // Recent lessons section
            RecentLessonsSection()
            
            // Recent drawings section
            RecentDrawingsSection()
            
            // Achievement highlights
            AchievementHighlightsSection()
            
            // Quick actions
            QuickActionsGrid()
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        // Refresh user data, lessons, etc.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

struct HeaderView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Ready to create something amazing?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Profile image
            Group {
                if let profileURLString = userProfileService.currentUser?.profileImageURL,
                   let profileURL = URL(string: profileURLString) {
                    AsyncImage(url: profileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
        }
        .padding(.horizontal, 16)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }
}

struct StreakProgressView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    
    var body: some View {
        HStack(spacing: 16) {
            // Streak card
            VStack {
                Text("\(userProfileService.currentUser?.currentStreak ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            // XP card
            VStack {
                Text("\(userProfileService.currentUser?.totalXP ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("Total XP")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            // Level card
            VStack {
                Text("Lvl \(userProfileService.currentUser?.level ?? 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("Artist Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
    }
}

struct DailyLessonCard: View {
    @EnvironmentObject var lessonService: LessonService
    
    var body: some View {
        if let dailyLesson = lessonService.dailyLesson {
            NavigationLink(destination: LessonDetailView(lesson: dailyLesson)) {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: dailyLesson.thumbnailImageName)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Lesson")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                        
                        Text(dailyLesson.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(dailyLesson.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
        }
    }
}

struct ProFeaturesBanner: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unlock Pro Features")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Get unlimited lessons, AI guidance, and more!")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
    }
}

struct RecentDrawingsSection: View {
    @EnvironmentObject var userProfileService: UserProfileService
    
    var body: some View {
        if !userProfileService.recentDrawings.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent Drawings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    NavigationLink("View All") {
                        GalleryView()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(userProfileService.recentDrawings.prefix(5)) { drawing in
                            RecentDrawingCard(drawing: drawing)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct RecentDrawingCard: View {
    let drawing: UserDrawing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: drawing.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            Text(drawing.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
    }
}

struct QuickActionsGrid: View {
    @EnvironmentObject var navigationState: NavigationState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 2),
                spacing: 16
            ) {
                QuickActionCard(
                    icon: "photo.badge.plus",
                    title: "Import Photo",
                    subtitle: "Turn photos into lessons",
                    color: .blue,
                    action: handleImportPhoto
                )
                
                QuickActionCard(
                    icon: "pencil.and.scribble",
                    title: "Free Draw",
                    subtitle: "Start drawing freely",
                    color: .green,
                    action: handleFreeDrawAction
                )
                
                QuickActionCard(
                    icon: "book.closed",
                    title: "Browse Lessons",
                    subtitle: "Explore all lessons",
                    color: .purple,
                    action: handleBrowseLessons
                )
                
                QuickActionCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "My Progress",
                    subtitle: "View your stats",
                    color: .orange,
                    action: handleViewProgress
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Action Handlers
    private func handleImportPhoto() {
        navigationState.showingPhotoImporter = true
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleFreeDrawAction() {
        // Create a free draw lesson
        let freeDrawLesson = Lesson(
            title: "Free Drawing",
            description: "Express your creativity with free-form drawing",
            category: .objects,
            difficulty: .beginner,
            thumbnailImageName: "free_draw_thumb",
            referenceImageName: "free_draw_ref",
            estimatedTime: 5, // 5 minutes
            isPremium: false,
            steps: [
                LessonStep(
                    stepNumber: 1,
                    instruction: "Start drawing whatever comes to mind",
                    guidancePoints: [],
                    shapeType: .line
                )
            ],
            tags: ["creative", "freeform"]
        )
        navigationState.selectedLesson = freeDrawLesson
        navigationState.selectedTab = TabType.lessons
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func handleBrowseLessons() {
        navigationState.selectedTab = TabType.lessons
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func handleViewProgress() {
        navigationState.selectedTab = TabType.profile
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentLessonsSection: View {
    @EnvironmentObject var lessonService: LessonService
    
    var body: some View {
        if !lessonService.recentLessons.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Continue Learning")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    NavigationLink("View All") {
                        LessonsView()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(lessonService.recentLessons.prefix(5)) { lesson in
                            RecentLessonCard(lesson: lesson)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct RecentLessonCard: View {
    let lesson: Lesson
    
    var body: some View {
        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: lesson.thumbnailImageName)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 160, height: 120)
                .cornerRadius(8)
                .clipped()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Circle()
                            .fill(lesson.difficulty.color)
                            .frame(width: 6, height: 6)
                        
                        Text(lesson.difficulty.rawValue)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(lesson.estimatedDuration / 60)min")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AchievementHighlightsSection: View {
    @EnvironmentObject var userProfileService: UserProfileService
    
    var body: some View {
        if !userProfileService.recentAchievements.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recent Achievements")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    NavigationLink("View All") {
                        ProfileView()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(userProfileService.recentAchievements.prefix(3)) { achievement in
                            AchievementHighlightCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct AchievementHighlightCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.iconName)
                .font(.title)
                .foregroundColor(.yellow)
                .frame(width: 50, height: 50)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(8)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 120)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// Extension for DifficultyLevel colors (defined in LessonsView.swift)

#Preview {
    NavigationView {
        HomeView()
    }
}