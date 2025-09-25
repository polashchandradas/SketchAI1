import Foundation
import SwiftUI
import Combine

// MARK: - User Profile Service
class UserProfileService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var userDrawings: [UserDrawing] = []
    @Published var achievements: [Achievement] = []
    @Published var streakCount: Int = 0
    @Published var isFirstLaunch: Bool = false
    @Published var recentDrawings: [UserDrawing] = []
    @Published var recentAchievements: [Achievement] = []
    
    // MARK: - Dependencies
    let persistenceService: PersistenceService // Made public for optimized gallery service
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(persistenceService: PersistenceService) {
        print("🚀 [USERPROFILE] Initializing UserProfileService")
        self.persistenceService = persistenceService
        loadInitialData()
        print("✅ [USERPROFILE] UserProfileService initialization complete")
    }
    
    // MARK: - Data Loading
    private func loadInitialData() {
        print("📊 [USERPROFILE] Loading initial data...")
        loadUserData()
        print("📊 [USERPROFILE] User data loaded")
        loadAchievements()
        print("📊 [USERPROFILE] Achievements loaded")
        checkFirstLaunch()
        print("📊 [USERPROFILE] First launch check complete: \(isFirstLaunch)")
    }
    
    func loadUserData() {
        streakCount = persistenceService.loadStreakCount()
        userDrawings = persistenceService.loadUserDrawings()
        
        // Set recent drawings (last 5 drawings)
        recentDrawings = Array(userDrawings.prefix(5))
    }
    
    private func loadAchievements() {
        let savedAchievements = persistenceService.loadAchievements()
        if savedAchievements.isEmpty {
            // First launch - use default achievements
            achievements = AchievementData.defaultAchievements
            persistenceService.saveAchievements(achievements)
        } else {
            achievements = savedAchievements
        }
        
        // Set recent achievements (last 3 unlocked achievements)
        recentAchievements = Array(achievements.filter { $0.isUnlocked }.prefix(3))
    }
    
    private func checkFirstLaunch() {
        isFirstLaunch = !persistenceService.hasCompletedOnboarding()
    }
    
    // MARK: - User Actions
    func completeOnboarding() {
        persistenceService.saveOnboardingComplete(true)
        isFirstLaunch = false
    }
    
    func addDrawing(_ drawing: UserDrawing) {
        userDrawings.append(drawing)
        persistenceService.saveUserDrawing(drawing)
        updateStreak()
        checkAchievements()
    }
    
    func removeDrawing(_ drawing: UserDrawing) {
        userDrawings.removeAll { $0.id == drawing.id }
        persistenceService.deleteUserDrawing(drawing)
    }
    
    func toggleDrawingFavorite(_ drawing: UserDrawing) {
        if let index = userDrawings.firstIndex(where: { $0.id == drawing.id }) {
            userDrawings[index].isFavorite.toggle()
            persistenceService.saveUserDrawing(userDrawings[index])
        }
    }
    
    func toggleDrawingFavorite(drawingId: UUID) {
        if let index = userDrawings.firstIndex(where: { $0.id == drawingId }) {
            userDrawings[index].isFavorite.toggle()
            persistenceService.saveUserDrawing(userDrawings[index])
        }
    }
    
    func deleteDrawing(drawingId: UUID) {
        if let drawing = userDrawings.first(where: { $0.id == drawingId }) {
            removeDrawing(drawing)
        }
    }
    
    // MARK: - Streak Management
    private func updateStreak() {
        let today = Date()
        let lastDrawingDate = persistenceService.loadLastDrawingDate()
        
        if let lastDate = lastDrawingDate {
            let calendar = Calendar.current
            if calendar.isDate(today, inSameDayAs: lastDate) {
                // Same day, don't update streak
                return
            } else if calendar.dateInterval(of: .day, for: lastDate)?.end == calendar.dateInterval(of: .day, for: today)?.start {
                // Consecutive day
                streakCount += 1
            } else {
                // Streak broken
                streakCount = 1
            }
        } else {
            streakCount = 1
        }
        
        persistenceService.saveLastDrawingDate(today)
        persistenceService.saveStreakCount(streakCount)
    }
    
    // MARK: - Achievement Management
    private func checkAchievements() {
        for achievement in achievements {
            if !achievement.isUnlocked {
                achievement.checkUnlockCondition(userDrawings: userDrawings, streakCount: streakCount)
            }
        }
        persistenceService.saveAchievements(achievements)
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index].isUnlocked = true
            persistenceService.saveAchievements(achievements)
        }
    }
    
    // MARK: - Profile Updates
    func updateUserProfile(_ user: User) {
        currentUser = user
        // TODO: Persist user data when Core Data model is implemented
    }
    
    // MARK: - Statistics
    func getDrawingCount(for category: LessonCategory) -> Int {
        return userDrawings.filter { $0.category == category }.count
    }
    
    func getTotalDrawingTime() -> TimeInterval {
        return userDrawings.reduce(0) { $0 + $1.completionTime }
    }
    
    func getFavoriteDrawings() -> [UserDrawing] {
        return userDrawings.filter { $0.isFavorite }
    }
    
    func getRecentDrawings(limit: Int = 10) -> [UserDrawing] {
        return Array(userDrawings.sorted { $0.createdDate > $1.createdDate }.prefix(limit))
    }
    
    func getRecentAchievements(limit: Int = 5) -> [Achievement] {
        return Array(achievements.filter { $0.isUnlocked }.suffix(limit))
    }
    
    func updateLessonStats(lessonId: UUID, accuracy: Double, completionTime: TimeInterval) {
        // Update user statistics based on lesson completion
        if let currentUser = currentUser {
            var updatedUser = currentUser
            updatedUser.totalLessonsCompleted += 1
            self.currentUser = updatedUser
        }
        
        // Update streak and other stats
        updateStreak()
        
        // Check for achievements based on the completed lesson
        checkAchievements()
    }
    
    func checkForNewAchievements() {
        // Check all achievement conditions
        checkAchievements()
    }
    
    // MARK: - Progress Analytics
    func getCompletionRate(for category: LessonCategory) -> Double {
        let categoryDrawings = getDrawingCount(for: category)
        let totalLessons = LessonData.sampleLessons.filter { $0.category == category }.count
        
        guard totalLessons > 0 else { return 0.0 }
        return Double(categoryDrawings) / Double(totalLessons)
    }
    
    func getWeeklyProgress() -> [Date: Int] {
        let calendar = Calendar.current
        let now = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        
        let weeklyDrawings = userDrawings.filter { $0.createdDate >= weekAgo }
        
        var dailyCounts: [Date: Int] = [:]
        for drawing in weeklyDrawings {
            let day = calendar.startOfDay(for: drawing.createdDate)
            dailyCounts[day, default: 0] += 1
        }
        
        return dailyCounts
    }
    
    // MARK: - Adaptive Difficulty Persistence
    func saveAdaptiveDifficultySettings(_ settings: AdaptiveDifficultySettings) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "adaptiveDifficultySettings")
        }
    }
    
    func loadAdaptiveDifficultySettings() -> AdaptiveDifficultySettings {
        if let data = UserDefaults.standard.data(forKey: "adaptiveDifficultySettings"),
           let settings = try? JSONDecoder().decode(AdaptiveDifficultySettings.self, from: data) {
            return settings
        }
        return AdaptiveDifficultySettings() // Default settings
    }
    
    func updateAdaptiveDifficulty(for category: LessonCategory, level: DifficultyAdjustment) {
        var settings = loadAdaptiveDifficultySettings()
        settings.categoryDifficulties[category] = level
        settings.lastUpdated = Date()
        saveAdaptiveDifficultySettings(settings)
    }
    
    func getAdaptiveDifficulty(for category: LessonCategory) -> DifficultyAdjustment {
        let settings = loadAdaptiveDifficultySettings()
        return settings.categoryDifficulties[category] ?? .normal
    }
}
