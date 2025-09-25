import Foundation
import SwiftUI
import Combine
import Vision
import UIKit

@MainActor
class LessonService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var lessons: [Lesson] = []
    @Published var filteredLessons: [Lesson] = []
    @Published var selectedCategory: LessonCategory?
    @Published var selectedDifficulty: DifficultyLevel?
    @Published var searchText: String = ""
    @Published var showOnlyFavorites: Bool = false
    @Published var showOnlyCompleted: Bool = false
    @Published var generatedLessons: [Lesson] = []
    @Published var isGeneratingLesson = false
    @Published var dailyLesson: Lesson?
    @Published var recentLessons: [Lesson] = []
    
    // MARK: - Dependencies
    private let persistenceService: PersistenceService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User Progress Tracking
    private var userProgress: [UUID: LessonProgress] = [:]
    private var currentUserId: String?
    
    // MARK: - Vision Analysis Integration
    private var visionAnalyzer: VisionLessonAnalyzer?
    
    @MainActor
    private func getVisionAnalyzer() -> VisionLessonAnalyzer {
        if visionAnalyzer == nil {
            visionAnalyzer = VisionLessonAnalyzer()
        }
        return visionAnalyzer!
    }
    
    // MARK: - Initialization
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        self.currentUserId = persistenceService.loadUserID()
        loadLessons()
        loadUserProgress()
        setupFilterObservers()
    }
    
    // MARK: - Data Loading
    private func loadLessons() {
        lessons = LessonData.sampleLessons
        
        // Apply user progress to lessons
        updateLessonsWithProgress()
        
        // Set daily lesson (first lesson for now)
        dailyLesson = lessons.first
        
        // Set recent lessons (first 5 lessons)
        recentLessons = Array(lessons.prefix(5))
        
        applyFilters()
    }
    
    private func loadUserProgress() {
        let allProgress = persistenceService.loadAllLessonProgress(userId: currentUserId)
        userProgress = Dictionary(uniqueKeysWithValues: allProgress.map { ($0.lessonId, $0) })
    }
    
    private func updateLessonsWithProgress() {
        for i in 0..<lessons.count {
            let lessonId = lessons[i].id
            if let progress = userProgress[lessonId] {
                lessons[i].isCompleted = progress.isCompleted
                lessons[i].isFavorite = progress.isFavorite
            }
        }
    }
    
    private func setupFilterObservers() {
        // Observe filter changes and apply them automatically
        Publishers.CombineLatest4(
            $selectedCategory,
            $selectedDifficulty,
            $searchText,
            $showOnlyFavorites
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
        
        $showOnlyCompleted
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Filtering and Search
    private func applyFilters() {
        var filtered = lessons
        
        // Category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Difficulty filter
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Favorites filter
        if showOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Completed filter
        if showOnlyCompleted {
            filtered = filtered.filter { $0.isCompleted }
        }
        
        filteredLessons = filtered.sorted { $0.title < $1.title }
    }
    
    // MARK: - Filter Management
    func setCategory(_ category: LessonCategory?) {
        selectedCategory = category
    }
    
    func setDifficulty(_ difficulty: DifficultyLevel?) {
        selectedDifficulty = difficulty
    }
    
    func setSearchText(_ text: String) {
        searchText = text
    }
    
    func toggleFavoritesFilter() {
        showOnlyFavorites.toggle()
    }
    
    func toggleCompletedFilter() {
        showOnlyCompleted.toggle()
    }
    
    func clearAllFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
        showOnlyFavorites = false
        showOnlyCompleted = false
    }
    
    // MARK: - Lesson Management
    func toggleLessonFavorite(_ lesson: Lesson) {
        if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
            // Update local state
            lessons[index].isFavorite.toggle()
            
            // Persist to Core Data
            persistenceService.toggleLessonFavorite(lessonId: lesson.id, userId: currentUserId)
            
            // Update progress cache
            if var progress = userProgress[lesson.id] {
                progress.toggleFavorite()
                userProgress[lesson.id] = progress
            } else {
                let newProgress = LessonProgress(lessonId: lesson.id, userId: currentUserId)
                var mutableProgress = newProgress
                mutableProgress.toggleFavorite()
                userProgress[lesson.id] = mutableProgress
            }
            
            applyFilters()
        }
    }
    
    func markLessonCompleted(_ lesson: Lesson, accuracyScore: Double = 0.0, timeSpent: Double = 0.0) {
        if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
            // Update local state
            lessons[index].isCompleted = true
            
            // Persist to Core Data
            persistenceService.markLessonCompleted(
                lessonId: lesson.id, 
                userId: currentUserId, 
                accuracyScore: accuracyScore, 
                timeSpent: timeSpent
            )
            
            // Update progress cache
            if var progress = userProgress[lesson.id] {
                progress.markCompleted(accuracyScore: accuracyScore)
                progress.timeSpent += timeSpent
                userProgress[lesson.id] = progress
            } else {
                let newProgress = LessonProgress(lessonId: lesson.id, userId: currentUserId)
                var mutableProgress = newProgress
                mutableProgress.markCompleted(accuracyScore: accuracyScore)
                mutableProgress.timeSpent = timeSpent
                userProgress[lesson.id] = mutableProgress
            }
            
            applyFilters()
        }
    }
    
    func markLessonCompleted(_ lessonId: UUID, accuracyScore: Double = 0.0, timeSpent: Double = 0.0) {
        if let index = lessons.firstIndex(where: { $0.id == lessonId }) {
            markLessonCompleted(lessons[index], accuracyScore: accuracyScore, timeSpent: timeSpent)
        }
    }
    
    func resetLessonCompletion(_ lesson: Lesson) {
        if let index = lessons.firstIndex(where: { $0.id == lesson.id }) {
            // Update local state
            lessons[index].isCompleted = false
            
            // Delete progress from Core Data
            persistenceService.deleteLessonProgress(lessonId: lesson.id, userId: currentUserId)
            
            // Remove from progress cache
            userProgress.removeValue(forKey: lesson.id)
            
            applyFilters()
        }
    }
    
    func updateLessonProgress(_ lesson: Lesson, currentStep: Int, totalSteps: Int, timeSpent: Double = 0.0) {
        // Persist step progress to Core Data
        persistenceService.updateLessonProgress(
            lessonId: lesson.id,
            userId: currentUserId,
            currentStep: currentStep,
            totalSteps: totalSteps,
            timeSpent: timeSpent
        )
        
        // Update progress cache
        if var progress = userProgress[lesson.id] {
            progress.updateProgress(currentStep: currentStep, totalSteps: totalSteps, timeSpent: timeSpent)
            userProgress[lesson.id] = progress
        } else {
            let newProgress = LessonProgress(lessonId: lesson.id, userId: currentUserId)
            var mutableProgress = newProgress
            mutableProgress.updateProgress(currentStep: currentStep, totalSteps: totalSteps, timeSpent: timeSpent)
            userProgress[lesson.id] = mutableProgress
        }
    }
    
    // MARK: - Lesson Queries
    func getLesson(by id: UUID) -> Lesson? {
        return lessons.first { $0.id == id }
    }
    
    func getLessons(for category: LessonCategory) -> [Lesson] {
        return lessons.filter { $0.category == category }
    }
    
    func getLessons(for difficulty: DifficultyLevel) -> [Lesson] {
        return lessons.filter { $0.difficulty == difficulty }
    }
    
    func getPremiumLessons() -> [Lesson] {
        return lessons.filter { $0.isPremium }
    }
    
    func getFreeLessons() -> [Lesson] {
        return lessons.filter { !$0.isPremium }
    }
    
    func getFavoriteLessons() -> [Lesson] {
        return lessons.filter { $0.isFavorite }
    }
    
    func getCompletedLessons() -> [Lesson] {
        return lessons.filter { $0.isCompleted }
    }
    
    func getIncompleteLessons() -> [Lesson] {
        return lessons.filter { !$0.isCompleted }
    }
    
    // MARK: - Lesson Recommendations
    func getRecommendedLessons(for user: User? = nil, limit: Int = 5) -> [Lesson] {
        // Basic recommendation algorithm
        var recommended = lessons
        
        // Filter out completed lessons
        recommended = recommended.filter { !$0.isCompleted }
        
        // Prioritize free lessons for non-pro users
        if user?.isPro != true {
            recommended = recommended.filter { !$0.isPremium }
        }
        
        // Sort by difficulty and estimated time
        recommended = recommended.sorted { lhs, rhs in
            if lhs.difficulty == rhs.difficulty {
                return lhs.estimatedTime < rhs.estimatedTime
            }
            return lhs.difficulty.rawValue < rhs.difficulty.rawValue
        }
        
        return Array(recommended.prefix(limit))
    }
    
    func getNextLesson(after currentLesson: Lesson) -> Lesson? {
        let categoryLessons = getLessons(for: currentLesson.category)
            .filter { !$0.isCompleted }
            .sorted { $0.difficulty.rawValue < $1.difficulty.rawValue }
        
        // Find current lesson index
        if let currentIndex = categoryLessons.firstIndex(where: { $0.id == currentLesson.id }) {
            let nextIndex = currentIndex + 1
            if nextIndex < categoryLessons.count {
                return categoryLessons[nextIndex]
            }
        }
        
        return nil
    }
    
    // MARK: - Statistics
    func getCompletionStatistics() -> LessonStatistics {
        let totalLessons = lessons.count
        let completedLessons = getCompletedLessons().count
        let favoriteLessons = getFavoriteLessons().count
        let premiumLessons = getPremiumLessons().count
        
        let categoryStats = LessonCategory.allCases.map { category in
            CategoryStatistics(
                category: category,
                total: getLessons(for: category).count,
                completed: getLessons(for: category).filter { $0.isCompleted }.count
            )
        }
        
        let difficultyStats = DifficultyLevel.allCases.map { difficulty in
            DifficultyStatistics(
                difficulty: difficulty,
                total: getLessons(for: difficulty).count,
                completed: getLessons(for: difficulty).filter { $0.isCompleted }.count
            )
        }
        
        return LessonStatistics(
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            favoriteLessons: favoriteLessons,
            premiumLessons: premiumLessons,
            completionPercentage: totalLessons > 0 ? Double(completedLessons) / Double(totalLessons) : 0.0,
            categoryStatistics: categoryStats,
            difficultyStatistics: difficultyStats
        )
    }
    
    func getUserStatistics() -> (completed: Int, favorites: Int, totalTimeSpent: Double) {
        return persistenceService.getLessonStatistics(userId: currentUserId)
    }
    
    func getLessonProgress(for lesson: Lesson) -> LessonProgress? {
        return userProgress[lesson.id]
    }
    
    func getEstimatedTimeRemaining() -> TimeInterval {
        let incompleteLessons = getIncompleteLessons()
        return TimeInterval(incompleteLessons.reduce(0) { $0 + $1.estimatedTime } * 60) // Convert minutes to seconds
    }
    
    func getNextRecommendedLesson(after currentLesson: Lesson) -> Lesson? {
        return getNextLesson(after: currentLesson)
    }
    
    // MARK: - Vision-Powered Lesson Generation
    
    /// Generate a custom lesson from an imported photo using Vision analysis
    func generateLessonFromPhoto(_ image: UIImage, completion: @escaping @Sendable (Result<Lesson, Error>) -> Void) {
        isGeneratingLesson = true
        
        Task { @MainActor in
            do {
                let generatedLesson = try await getVisionAnalyzer().generateLesson(from: image)
                
                self.generatedLessons.append(generatedLesson)
                self.lessons.append(generatedLesson)
                self.applyFilters()
                self.isGeneratingLesson = false
                completion(.success(generatedLesson))
            } catch {
                self.isGeneratingLesson = false
                completion(.failure(error))
            }
        }
    }
    
    /// Generate multiple lesson variations based on image analysis
    @MainActor
    func generateLessonVariations(from image: UIImage, count: Int = 3) async -> [Lesson] {
        isGeneratingLesson = true
        defer { isGeneratingLesson = false }
        
        do {
            let variations = try await getVisionAnalyzer().generateLessonVariations(from: image, count: count)
            
            self.generatedLessons.append(contentsOf: variations)
            self.lessons.append(contentsOf: variations)
            self.applyFilters()
            
            return variations
        } catch {
            print("Error generating lesson variations: \(error)")
            return []
        }
    }
    
    /// Analyze image and suggest appropriate lesson category and difficulty
    func analyzeLessonRequirements(for image: UIImage) async -> LessonRequirements? {
        do {
            return try await getVisionAnalyzer().analyzeLessonRequirements(for: image)
        } catch {
            print("Error analyzing lesson requirements: \(error)")
            return nil
        }
    }
    
    /// Generate adaptive lesson content based on user performance
    func generateAdaptiveLesson(basedOn userPerformance: UserPerformanceData, category: LessonCategory) async -> Lesson? {
        do {
            return try await getVisionAnalyzer().generateAdaptiveLesson(
                basedOn: userPerformance,
                category: category
            )
        } catch {
            print("Error generating adaptive lesson: \(error)")
            return nil
        }
    }
    
    /// Remove a generated lesson
    func removeGeneratedLesson(_ lesson: Lesson) {
        // Remove from generated lessons array
        generatedLessons.removeAll { $0.id == lesson.id }
        
        // Remove from main lessons array
        lessons.removeAll { $0.id == lesson.id }
        
        // Reapply filters
        applyFilters()
    }
    
    /// Clear all generated lessons
    func clearAllGeneratedLessons() {
        // Remove all generated lessons from main lessons array
        for generatedLesson in generatedLessons {
            lessons.removeAll { $0.id == generatedLesson.id }
        }
        
        // Clear generated lessons array
        generatedLessons.removeAll()
        
        // Reapply filters
        applyFilters()
    }
}

// MARK: - Supporting Types
struct LessonStatistics {
    let totalLessons: Int
    let completedLessons: Int
    let favoriteLessons: Int
    let premiumLessons: Int
    let completionPercentage: Double
    let categoryStatistics: [CategoryStatistics]
    let difficultyStatistics: [DifficultyStatistics]
}

struct CategoryStatistics {
    let category: LessonCategory
    let total: Int
    let completed: Int
    
    var completionPercentage: Double {
        total > 0 ? Double(completed) / Double(total) : 0.0
    }
}

struct DifficultyStatistics {
    let difficulty: DifficultyLevel
    let total: Int
    let completed: Int
    
    var completionPercentage: Double {
        total > 0 ? Double(completed) / Double(total) : 0.0
    }
}
