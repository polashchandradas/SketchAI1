import Foundation
import SwiftUI
import Combine

// MARK: - Step Progression Manager
@MainActor
class StepProgressionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStepIndex = 0
    @Published var stepCompletionStates: [StepCompletionState] = []
    @Published var overallProgress: Double = 0.0
    @Published var canProgressToNext = false
    @Published var shouldShowNextStepHint = false
    @Published var adaptiveDifficultyLevel: DifficultyAdjustment = .normal
    
    // MARK: - Configuration
    private let lesson: Lesson
    private let drawingEngine: DrawingAlgorithmEngine
    private let strokeAnalyzer = UnifiedStrokeAnalyzer()
    
    // MARK: - DTW Performance Adapter
    private var dtwAdapter: ((StrokeFeedback) -> Void)?
    
    // MARK: - Step Analysis
    private var stepAnalytics: [StepAnalytics] = []
    private var userPerformanceHistory: UserPerformanceHistory
    
    // MARK: - Timing and Adaptation
    private var stepStartTime = Date()
    private var totalSessionTime: TimeInterval = 0
    private var strugglingThreshold: TimeInterval = 120 // 2 minutes
    private var excellentThreshold: TimeInterval = 30   // 30 seconds
    
    // MARK: - Configuration Constants
    private struct Config {
        static let minAccuracyForProgression: Double = 0.6
        static let excellentAccuracyThreshold: Double = 0.85
        static let maxAttemptsBeforeHint = 3
        static let adaptationSensitivity: Double = 0.1
        static let progressSmoothingFactor: Double = 0.3
    }
    
    init(lesson: Lesson, drawingEngine: DrawingAlgorithmEngine) {
        self.lesson = lesson
        self.drawingEngine = drawingEngine
        self.userPerformanceHistory = UserPerformanceHistory()
        
        initializeStepStates()
        setupProgressionLogic()
    }
    
    // MARK: - Initialization
    private func initializeStepStates() {
        stepCompletionStates = lesson.steps.map { _ in
            StepCompletionState()
        }
        
        stepAnalytics = lesson.steps.map { step in
            StepAnalytics(stepNumber: step.stepNumber, stepInstruction: step.instruction)
        }
    }
    
    private func setupProgressionLogic() {
        // Monitor drawing engine state changes
        drawingEngine.$analysisComplete
            .sink { [weak self] complete in
                if complete {
                    self?.evaluateCurrentStep()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Step Evaluation
    func evaluateStrokeForCurrentStep(_ strokeFeedback: StrokeFeedback) {
        guard currentStepIndex < stepCompletionStates.count else { return }
        
        var stepState = stepCompletionStates[currentStepIndex]
        let analytics = stepAnalytics[currentStepIndex]
        
        // Update step state with new stroke data
        stepState.attempts += 1
        stepState.accuracyScores.append(strokeFeedback.accuracy)
        stepState.lastAttemptTime = Date()
        
        // Update analytics
        analytics.strokeCount += 1
        analytics.totalAccuracy += strokeFeedback.accuracy
        analytics.timeSpent = Date().timeIntervalSince(stepStartTime)
        
        // Calculate current step accuracy
        let currentAccuracy = stepState.accuracyScores.reduce(0, +) / Double(stepState.accuracyScores.count)
        stepState.currentAccuracy = currentAccuracy
        
        // Determine if step is complete
        let isStepComplete = evaluateStepCompletion(stepState, strokeFeedback: strokeFeedback)
        stepState.isCompleted = isStepComplete
        
        // Update states
        stepCompletionStates[currentStepIndex] = stepState
        stepAnalytics[currentStepIndex] = analytics
        
        // Update progression capabilities
        updateProgressionState()
        
        // Adaptive difficulty adjustment
        adjustDifficultyIfNeeded()
        
        // Check for hints
        checkForHintTriggers()
        
        // DTW performance adaptation
        if let adapter = dtwAdapter {
            adapter(strokeFeedback)
        }
    }
    
    private func evaluateStepCompletion(_ stepState: StepCompletionState, strokeFeedback: StrokeFeedback) -> Bool {
        // Multiple criteria for step completion
        let accuracyMet = stepState.currentAccuracy >= Config.minAccuracyForProgression
        let hasGoodStrokes = stepState.accuracyScores.filter { $0 >= Config.minAccuracyForProgression }.count >= 2
        let recentStrokeGood = strokeFeedback.accuracy >= Config.minAccuracyForProgression
        
        return accuracyMet && (hasGoodStrokes || recentStrokeGood)
    }
    
    private func evaluateCurrentStep() {
        guard currentStepIndex < stepAnalytics.count else { return }
        
        let analytics = stepAnalytics[currentStepIndex]
        let stepState = stepCompletionStates[currentStepIndex]
        
        // Performance classification
        let performance = classifyStepPerformance(analytics: analytics, state: stepState)
        stepAnalytics[currentStepIndex].performance = performance
        
        // Update user performance history
        userPerformanceHistory.recordStepPerformance(
            category: lesson.category,
            difficulty: lesson.difficulty,
            performance: performance,
            timeSpent: analytics.timeSpent,
            accuracy: stepState.currentAccuracy
        )
        
        updateOverallProgress()
    }
    
    private func classifyStepPerformance(analytics: StepAnalytics, state: StepCompletionState) -> StepPerformance {
        let accuracy = state.currentAccuracy
        let timeSpent = analytics.timeSpent
        let attempts = state.attempts
        
        if accuracy >= Config.excellentAccuracyThreshold && timeSpent <= excellentThreshold {
            return .excellent
        } else if accuracy >= Config.minAccuracyForProgression && attempts <= 3 {
            return .good
        } else if accuracy >= Config.minAccuracyForProgression {
            return .satisfactory
        } else if attempts >= 5 || timeSpent >= strugglingThreshold {
            return .struggling
        } else {
            return .needsImprovement
        }
    }
    
    // MARK: - Step Navigation
    func progressToNextStep() -> Bool {
        guard canProgressToNext else { return false }
        guard currentStepIndex < lesson.steps.count - 1 else { return false }
        
        // Record step completion
        completeCurrentStep()
        
        // Move to next step
        currentStepIndex += 1
        stepStartTime = Date()
        
        // Reset progression state
        canProgressToNext = false
        shouldShowNextStepHint = false
        
        // Notify drawing engine
        drawingEngine.nextStep()
        
        return true
    }
    
    func goToPreviousStep() -> Bool {
        guard currentStepIndex > 0 else { return false }
        
        currentStepIndex -= 1
        stepStartTime = Date()
        
        // Reset current step state if returning
        stepCompletionStates[currentStepIndex].isCompleted = false
        canProgressToNext = false
        shouldShowNextStepHint = false
        
        // Notify drawing engine
        drawingEngine.previousStep()
        
        return true
    }
    
    func jumpToStep(_ stepIndex: Int) -> Bool {
        guard stepIndex >= 0 && stepIndex < lesson.steps.count else { return false }
        guard stepIndex <= getHighestUnlockedStep() else { return false }
        
        currentStepIndex = stepIndex
        stepStartTime = Date()
        
        // Update drawing engine
        drawingEngine.currentStep = stepIndex
        
        return true
    }
    
    private func completeCurrentStep() {
        guard currentStepIndex < stepCompletionStates.count else { return }
        
        stepCompletionStates[currentStepIndex].isCompleted = true
        stepCompletionStates[currentStepIndex].completionTime = Date()
        
        let timeSpent = Date().timeIntervalSince(stepStartTime)
        stepAnalytics[currentStepIndex].timeSpent = timeSpent
        totalSessionTime += timeSpent
    }
    
    // MARK: - Progress State Management
    private func updateProgressionState() {
        let currentState = stepCompletionStates[currentStepIndex]
        canProgressToNext = currentState.isCompleted
        
        updateOverallProgress()
    }
    
    private func updateOverallProgress() {
        let completedSteps = stepCompletionStates.filter { $0.isCompleted }.count
        let totalSteps = stepCompletionStates.count
        
        let newProgress = Double(completedSteps) / Double(totalSteps)
        
        // Smooth progress updates
        withAnimation(.easeInOut(duration: 0.5)) {
            overallProgress = newProgress
        }
    }
    
    private func getHighestUnlockedStep() -> Int {
        // Allow access to current step + 1 if current is complete
        let completedCount = stepCompletionStates.filter { $0.isCompleted }.count
        return min(completedCount, lesson.steps.count - 1)
    }
    
    // MARK: - Adaptive Difficulty
    private func adjustDifficultyIfNeeded() {
        let currentState = stepCompletionStates[currentStepIndex]
        let analytics = stepAnalytics[currentStepIndex]
        
        // Analyze recent performance
        let recentAccuracies = Array(currentState.accuracyScores.suffix(3))
        let averageRecentAccuracy = recentAccuracies.isEmpty ? 0 : recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)
        
        let timeSpent = analytics.timeSpent
        let attempts = currentState.attempts
        
        // Determine if difficulty adjustment is needed
        if averageRecentAccuracy < 0.4 || timeSpent > strugglingThreshold || attempts > 5 {
            // Make easier
            if adaptiveDifficultyLevel.rawValue > DifficultyAdjustment.easier.rawValue {
                adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue - 1) ?? .easier
                applyDifficultyAdjustment()
            }
        } else if averageRecentAccuracy > 0.9 && timeSpent < excellentThreshold && attempts <= 2 {
            // Make harder
            if adaptiveDifficultyLevel.rawValue < DifficultyAdjustment.harder.rawValue {
                adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue + 1) ?? .harder
                applyDifficultyAdjustment()
            }
        }
    }
    
    private func applyDifficultyAdjustment() {
        // Adjust guide tolerance and feedback sensitivity based on difficulty
        guard let currentGuide = drawingEngine.getCurrentGuide() else { return }
        
        var adjustedGuide = currentGuide
        
        switch adaptiveDifficultyLevel {
        case .easier:
            adjustedGuide.tolerance *= 1.5 // More forgiving
        case .normal:
            break // Default tolerance
        case .harder:
            adjustedGuide.tolerance *= 0.7 // More precise
        }
        
        // Update the guide in the drawing engine
        drawingEngine.updateCurrentGuide(adjustedGuide)
    }
    
    // MARK: - Hint System
    private func checkForHintTriggers() {
        let currentState = stepCompletionStates[currentStepIndex]
        
        // Show hint if user is struggling
        if currentState.attempts >= Config.maxAttemptsBeforeHint && 
           !currentState.isCompleted && 
           !shouldShowNextStepHint {
            
            shouldShowNextStepHint = true
        }
    }
    
    func dismissHint() {
        shouldShowNextStepHint = false
    }
    
    // MARK: - Performance Analytics
    func getStepAnalytics(for stepIndex: Int) -> StepAnalytics? {
        guard stepIndex >= 0 && stepIndex < stepAnalytics.count else { return nil }
        return stepAnalytics[stepIndex]
    }
    
    func getSessionSummary() -> SessionSummary {
        let completedSteps = stepCompletionStates.filter { $0.isCompleted }.count
        let totalAccuracy = stepAnalytics.reduce(0) { $0 + $1.totalAccuracy }
        let totalStrokes = stepAnalytics.reduce(0) { $0 + $1.strokeCount }
        let averageAccuracy = totalStrokes > 0 ? totalAccuracy / Double(totalStrokes) : 0
        
        return SessionSummary(
            lessonTitle: lesson.title,
            completedSteps: completedSteps,
            totalSteps: lesson.steps.count,
            averageAccuracy: averageAccuracy,
            totalTime: totalSessionTime,
            difficultyAdjustments: adaptiveDifficultyLevel
        )
    }
    
    // MARK: - Reset and Recovery
    func resetCurrentStep() {
        guard currentStepIndex < stepCompletionStates.count else { return }
        
        stepCompletionStates[currentStepIndex] = StepCompletionState()
        stepAnalytics[currentStepIndex].reset()
        stepStartTime = Date()
        
        canProgressToNext = false
        shouldShowNextStepHint = false
    }
    
    func resetAllProgress() {
        currentStepIndex = 0
        stepCompletionStates = lesson.steps.map { _ in StepCompletionState() }
        stepAnalytics = lesson.steps.map { step in 
            StepAnalytics(stepNumber: step.stepNumber, stepInstruction: step.instruction)
        }
        
        overallProgress = 0.0
        canProgressToNext = false
        shouldShowNextStepHint = false
        adaptiveDifficultyLevel = .normal
        totalSessionTime = 0
        stepStartTime = Date()
    }
    
    // MARK: - DTW Integration
    func setDTWPerformanceAdapter(_ adapter: @escaping (StrokeFeedback) -> Void) {
        self.dtwAdapter = adapter
    }
    
    // MARK: - Enhanced Progression Features
    
    /// Check if the entire lesson can be completed
    var canCompleteLesson: Bool {
        let completedSteps = stepCompletionStates.filter { $0.isCompleted }.count
        return completedSteps >= lesson.steps.count || 
               (completedSteps >= lesson.steps.count - 1 && canProgressToNext)
    }
    
    /// Get total time spent in the session
    var totalTime: TimeInterval {
        return totalSessionTime + Date().timeIntervalSince(stepStartTime)
    }
    
    /// Start the lesson session
    func startLesson() {
        stepStartTime = Date()
        totalSessionTime = 0
        currentStepIndex = 0
        
        // Initialize first step
        if !stepCompletionStates.isEmpty {
            stepCompletionStates[0].lastAttemptTime = Date()
        }
    }
    
    /// Get current step information
    var currentStep: LessonStep? {
        guard currentStepIndex < lesson.steps.count else { return nil }
        return lesson.steps[currentStepIndex]
    }
    
    /// Get progress for a specific step
    func getStepProgress(_ stepIndex: Int) -> Double {
        guard stepIndex < stepCompletionStates.count else { return 0.0 }
        let state = stepCompletionStates[stepIndex]
        
        if state.isCompleted {
            return 1.0
        } else if state.attempts > 0 {
            return min(state.currentAccuracy, 0.9) // Cap at 90% until complete
        } else {
            return 0.0
        }
    }
    
    /// Increase difficulty for advanced users
    func increaseDifficulty() {
        if adaptiveDifficultyLevel.rawValue < DifficultyAdjustment.harder.rawValue {
            adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue + 1) ?? .harder
            applyDifficultyAdjustment()
        }
    }
    
    /// Decrease difficulty for struggling users
    func decreaseDifficulty() {
        if adaptiveDifficultyLevel.rawValue > DifficultyAdjustment.easier.rawValue {
            adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue - 1) ?? .easier
            applyDifficultyAdjustment()
        }
    }
    
    /// Get lesson completion status
    func getLessonCompletionStatus() -> LessonCompletionStatus {
        let completedSteps = stepCompletionStates.filter { $0.isCompleted }.count
        let totalSteps = lesson.steps.count
        let overallAccuracy = stepCompletionStates.reduce(0.0) { $0 + $1.averageAccuracy } / Double(totalSteps)
        
        if completedSteps == totalSteps {
            return LessonCompletionStatus(
                isComplete: true,
                completedSteps: completedSteps,
                totalSteps: totalSteps,
                overallAccuracy: overallAccuracy,
                totalTime: totalTime,
                performance: classifyOverallPerformance()
            )
        } else {
            return LessonCompletionStatus(
                isComplete: false,
                completedSteps: completedSteps,
                totalSteps: totalSteps,
                overallAccuracy: overallAccuracy,
                totalTime: totalTime,
                performance: .inProgress
            )
        }
    }
    
    private func classifyOverallPerformance() -> LessonPerformance {
        let completedSteps = stepCompletionStates.filter { $0.isCompleted }
        let averageAccuracy = completedSteps.reduce(0.0) { $0 + $1.averageAccuracy } / Double(completedSteps.count)
        let averageAttempts = completedSteps.reduce(0) { $0 + $1.attempts } / completedSteps.count
        
        if averageAccuracy >= 0.9 && averageAttempts <= 2 {
            return .masterful
        } else if averageAccuracy >= 0.8 && averageAttempts <= 3 {
            return .excellent
        } else if averageAccuracy >= 0.7 {
            return .good
        } else if averageAccuracy >= 0.6 {
            return .satisfactory
        } else {
            return .needsImprovement
        }
    }
    
    /// Generate personalized feedback for the user
    func generatePersonalizedFeedback() -> PersonalizedFeedback {
        let completionStatus = getLessonCompletionStatus()
        let strongAreas = identifyStrongAreas()
        let improvementAreas = identifyImprovementAreas()
        let suggestions = generateImprovementSuggestions()
        
        return PersonalizedFeedback(
            completionStatus: completionStatus,
            strongAreas: strongAreas,
            improvementAreas: improvementAreas,
            suggestions: suggestions,
            nextRecommendations: generateNextStepRecommendations()
        )
    }
    
    private func identifyStrongAreas() -> [String] {
        var strongAreas: [String] = []
        
        let excellentSteps = stepAnalytics.filter { $0.performance == .excellent || $0.performance == .good }
        
        if excellentSteps.count > stepAnalytics.count / 2 {
            strongAreas.append("Consistent accuracy")
        }
        
        let quickSteps = stepAnalytics.filter { $0.timeSpent < excellentThreshold }
        if quickSteps.count > stepAnalytics.count / 3 {
            strongAreas.append("Quick learning")
        }
        
        let efficientSteps = stepCompletionStates.filter { $0.attempts <= 2 && $0.isCompleted }
        if efficientSteps.count > stepCompletionStates.count / 2 {
            strongAreas.append("Efficient stroke technique")
        }
        
        return strongAreas
    }
    
    private func identifyImprovementAreas() -> [String] {
        var improvementAreas: [String] = []
        
        let strugglingSteps = stepAnalytics.filter { $0.performance == .struggling || $0.performance == .needsImprovement }
        
        if strugglingSteps.count > stepAnalytics.count / 3 {
            improvementAreas.append("Stroke accuracy")
        }
        
        let slowSteps = stepAnalytics.filter { $0.timeSpent > strugglingThreshold }
        if slowSteps.count > stepAnalytics.count / 4 {
            improvementAreas.append("Drawing speed")
        }
        
        let multipleAttemptSteps = stepCompletionStates.filter { $0.attempts > 4 }
        if multipleAttemptSteps.count > stepCompletionStates.count / 4 {
            improvementAreas.append("First-try accuracy")
        }
        
        return improvementAreas
    }
    
    private func generateImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        let improvementAreas = identifyImprovementAreas()
        
        if improvementAreas.contains("Stroke accuracy") {
            suggestions.append("🎯 Try practicing basic shapes - it'll make your strokes more precise!")
            suggestions.append("💪 Take your time with each stroke - slow and steady wins the race!")
        }
        
        if improvementAreas.contains("Drawing speed") {
            suggestions.append("✨ Be confident with your first stroke - you've got this!")
            suggestions.append("🔄 Practice the same shapes a few times to build your muscle memory")
        }
        
        if improvementAreas.contains("First-try accuracy") {
            suggestions.append("👀 Take a moment to picture the stroke in your mind before drawing")
            suggestions.append("📐 Use the guide lines as your helpful friends - they're there to guide you!")
        }
        
        if suggestions.isEmpty {
            suggestions.append("🌟 Amazing work! Keep practicing to become an even better artist!")
        }
        
        return suggestions
    }
    
    private func generateNextStepRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let performance = classifyOverallPerformance()
        
        switch performance {
        case .masterful, .excellent:
            recommendations.append("🌟 You're ready for advanced lessons in \(lesson.category.rawValue) - you're amazing!")
            recommendations.append("🎨 Try a new category to discover even more of your artistic talents!")
            
        case .good:
            recommendations.append("💪 Practice similar lessons to make your skills even stronger!")
            recommendations.append("🚀 When you're ready, try the next level - you've got this!")
            
        case .satisfactory:
            recommendations.append("🔄 Try this lesson again to make your drawings even better!")
            recommendations.append("📐 Practice basic shapes to build a strong foundation")
            
        case .needsImprovement:
            recommendations.append("🎯 Focus on the basics - every great artist started there!")
            recommendations.append("✨ Try some easier lessons first to build your confidence")
            
        case .inProgress:
            recommendations.append("🎨 Finish this lesson first - you're doing great!")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Data Structures

struct LessonCompletionStatus {
    let isComplete: Bool
    let completedSteps: Int
    let totalSteps: Int
    let overallAccuracy: Double
    let totalTime: TimeInterval
    let performance: LessonPerformance
}

enum LessonPerformance {
    case masterful
    case excellent
    case good
    case satisfactory
    case needsImprovement
    case inProgress
}

struct PersonalizedFeedback {
    let completionStatus: LessonCompletionStatus
    let strongAreas: [String]
    let improvementAreas: [String]
    let suggestions: [String]
    let nextRecommendations: [String]
}

struct StepCompletionState {
    var isCompleted = false
    var attempts = 0
    var accuracyScores: [Double] = []
    var currentAccuracy = 0.0
    var lastAttemptTime = Date()
    var completionTime: Date?
    
    var averageAccuracy: Double {
        accuracyScores.isEmpty ? 0.0 : accuracyScores.reduce(0, +) / Double(accuracyScores.count)
    }
}

class StepAnalytics {
    let stepNumber: Int
    let stepInstruction: String
    var strokeCount = 0
    var totalAccuracy = 0.0
    var timeSpent: TimeInterval = 0
    var performance: StepPerformance = .notStarted
    
    init(stepNumber: Int, stepInstruction: String) {
        self.stepNumber = stepNumber
        self.stepInstruction = stepInstruction
    }
    
    func reset() {
        strokeCount = 0
        totalAccuracy = 0.0
        timeSpent = 0
        performance = .notStarted
    }
    
    var averageAccuracy: Double {
        strokeCount > 0 ? totalAccuracy / Double(strokeCount) : 0.0
    }
}

enum StepPerformance: String, CaseIterable {
    case notStarted = "Not Started"
    case struggling = "Struggling"
    case needsImprovement = "Needs Improvement"
    case satisfactory = "Satisfactory"
    case good = "Good"
    case excellent = "Excellent"
    
    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .struggling: return .red
        case .needsImprovement: return .orange
        case .satisfactory: return .yellow
        case .good: return .blue
        case .excellent: return .green
        }
    }
    
    var emoji: String {
        switch self {
        case .notStarted: return "⚪"
        case .struggling: return "😅"
        case .needsImprovement: return "🤔"
        case .satisfactory: return "👍"
        case .good: return "😊"
        case .excellent: return "⭐"
        }
    }
}

// DifficultyAdjustment enum moved to DataModels.swift

struct SessionSummary {
    let lessonTitle: String
    let completedSteps: Int
    let totalSteps: Int
    let averageAccuracy: Double
    let totalTime: TimeInterval
    let difficultyAdjustments: DifficultyAdjustment
    
    var completionPercentage: Double {
        Double(completedSteps) / Double(totalSteps)
    }
    
    var formattedTime: String {
        let minutes = Int(totalTime) / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class UserPerformanceHistory: ObservableObject {
    @Published var categoryPerformance: [LessonCategory: CategoryPerformance] = [:]
    
    func recordStepPerformance(
        category: LessonCategory,
        difficulty: DifficultyLevel,
        performance: StepPerformance,
        timeSpent: TimeInterval,
        accuracy: Double
    ) {
        var categoryPerf = categoryPerformance[category] ?? CategoryPerformance()
        categoryPerf.addPerformance(
            difficulty: difficulty,
            performance: performance,
            timeSpent: timeSpent,
            accuracy: accuracy
        )
        categoryPerformance[category] = categoryPerf
    }
}

struct CategoryPerformance {
    var totalAttempts = 0
    var averageAccuracy = 0.0
    var averageTime: TimeInterval = 0
    var performanceDistribution: [StepPerformance: Int] = [:]
    
    mutating func addPerformance(difficulty: DifficultyLevel, performance: StepPerformance, timeSpent: TimeInterval, accuracy: Double) {
        totalAttempts += 1
        averageAccuracy = (averageAccuracy * Double(totalAttempts - 1) + accuracy) / Double(totalAttempts)
        averageTime = (averageTime * Double(totalAttempts - 1) + timeSpent) / Double(totalAttempts)
        
        performanceDistribution[performance, default: 0] += 1
    }
}

// MARK: - Drawing Engine Extension
extension DrawingAlgorithmEngine {
    func updateCurrentGuide(_ guide: DrawingGuide) {
        guard currentStep < currentGuides.count else { return }
        currentGuides[currentStep] = guide
    }
}

