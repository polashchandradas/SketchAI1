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
    
    // MARK: - Enhanced Adaptive Learning
    private var learningVelocity: Double = 0.0
    private var confidenceLevel: Double = 0.5
    private var frustrationLevel: Double = 0.0
    private var adaptiveStepGenerator: AdaptiveStepGenerator?
    private var learningPatterns: LearningPatternAnalyzer
    
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
        
        // Enhanced Adaptive Learning Constants
        static let learningVelocityThreshold: Double = 0.3
        static let masteryThreshold: Double = 0.9
        static let frustrationThreshold: TimeInterval = 180 // 3 minutes
        static let confidenceBuildingThreshold: Int = 3
        static let adaptiveStepGenerationThreshold: Double = 0.7
    }
    
    init(lesson: Lesson, drawingEngine: DrawingAlgorithmEngine) {
        self.lesson = lesson
        self.drawingEngine = drawingEngine
        self.userPerformanceHistory = UserPerformanceHistory()
        self.learningPatterns = LearningPatternAnalyzer()
        self.adaptiveStepGenerator = AdaptiveStepGenerator()
        
        initializeStepStates()
        setupProgressionLogic()
        initializeAdaptiveLearning()
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
    
    private func initializeAdaptiveLearning() {
        // Initialize adaptive learning parameters
        learningVelocity = 0.0
        confidenceLevel = 0.5
        frustrationLevel = 0.0
        
        // Set up learning pattern analysis
        learningPatterns.startAnalysis()
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
        
        // Enhanced Adaptive Learning Analysis
        updateLearningMetrics(strokeFeedback)
        analyzeLearningPatterns()
        adjustConfidenceLevel()
        detectFrustrationSignals()
        
        // Adaptive difficulty adjustment
        adjustDifficultyIfNeeded()
        
        // Check for hints
        checkForHintTriggers()
        
        // Generate adaptive steps if needed
        checkForAdaptiveStepGeneration()
        
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
    
    // MARK: - Enhanced Adaptive Learning Methods
    
    /// Update learning velocity and confidence metrics
    private func updateLearningMetrics(_ strokeFeedback: StrokeFeedback) {
        let currentTime = Date()
        let timeSinceLastStroke = currentTime.timeIntervalSince(stepStartTime)
        
        // Calculate learning velocity (improvement rate)
        let recentAccuracies = Array(stepCompletionStates[currentStepIndex].accuracyScores.suffix(5))
        if recentAccuracies.count >= 3 {
            let improvement = recentAccuracies.last! - recentAccuracies.first!
            learningVelocity = improvement / Double(recentAccuracies.count)
        }
        
        // Update confidence based on recent performance
        let recentPerformance = recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)
        confidenceLevel = min(1.0, max(0.0, confidenceLevel + (recentPerformance - 0.5) * 0.1))
        
        // Update learning patterns
        learningPatterns.recordStroke(
            accuracy: strokeFeedback.accuracy,
            timeSpent: timeSinceLastStroke,
            confidence: confidenceLevel
        )
    }
    
    /// Analyze learning patterns for personalized adaptation
    private func analyzeLearningPatterns() {
        let patterns = learningPatterns.analyzePatterns()
        
        // Adjust learning approach based on patterns
        switch patterns.learningStyle {
        case .visual:
            // Provide more visual guidance
            break
        case .kinesthetic:
            // Emphasize muscle memory practice
            break
        case .analytical:
            // Provide more detailed feedback
            break
        case .mixed:
            // Balanced approach
            break
        }
        
        // Adjust for learning pace
        if patterns.pace == .fast {
            // Increase challenge level
            if adaptiveDifficultyLevel.rawValue < DifficultyAdjustment.harder.rawValue {
                adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue + 1) ?? .harder
            }
        } else if patterns.pace == .slow {
            // Provide more support
            if adaptiveDifficultyLevel.rawValue > DifficultyAdjustment.easier.rawValue {
                adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue - 1) ?? .easier
            }
        }
    }
    
    /// Adjust confidence level based on performance
    private func adjustConfidenceLevel() {
        let currentState = stepCompletionStates[currentStepIndex]
        let recentAccuracies = Array(currentState.accuracyScores.suffix(3))
        
        if !recentAccuracies.isEmpty {
            let averageRecentAccuracy = recentAccuracies.reduce(0, +) / Double(recentAccuracies.count)
            
            // Boost confidence for good performance
            if averageRecentAccuracy >= Config.masteryThreshold {
                confidenceLevel = min(1.0, confidenceLevel + 0.1)
            }
            // Reduce confidence for poor performance
            else if averageRecentAccuracy < Config.minAccuracyForProgression {
                confidenceLevel = max(0.0, confidenceLevel - 0.05)
            }
        }
    }
    
    /// Detect frustration signals and provide support
    private func detectFrustrationSignals() {
        let currentState = stepCompletionStates[currentStepIndex]
        let timeSpent = Date().timeIntervalSince(stepStartTime)
        
        // Calculate frustration level
        let attemptFrustration = Double(currentState.attempts) / 10.0
        let timeFrustration = timeSpent / Config.frustrationThreshold
        let accuracyFrustration = max(0, (Config.minAccuracyForProgression - currentState.currentAccuracy) * 2)
        
        frustrationLevel = min(1.0, (attemptFrustration + timeFrustration + accuracyFrustration) / 3.0)
        
        // Provide support if frustrated
        if frustrationLevel > 0.7 {
            // Show encouraging message
            shouldShowNextStepHint = true
            // Temporarily reduce difficulty
            if adaptiveDifficultyLevel.rawValue > DifficultyAdjustment.easier.rawValue {
                adaptiveDifficultyLevel = DifficultyAdjustment(rawValue: adaptiveDifficultyLevel.rawValue - 1) ?? .easier
            }
        }
    }
    
    /// Check if adaptive step generation is needed
    private func checkForAdaptiveStepGeneration() {
        let currentState = stepCompletionStates[currentStepIndex]
        let performance = classifyStepPerformance(
            analytics: stepAnalytics[currentStepIndex],
            state: currentState
        )
        
        // Generate adaptive steps for struggling users
        if performance == .struggling && currentState.attempts >= 5 {
            generateAdaptiveSteps()
        }
        
        // Generate challenge steps for excellent users
        if performance == .excellent && currentState.attempts <= 2 {
            generateChallengeSteps()
        }
    }
    
    /// Generate adaptive steps for struggling users
    private func generateAdaptiveSteps() {
        guard let generator = adaptiveStepGenerator else { return }
        
        let currentStep = lesson.steps[currentStepIndex]
        let adaptiveSteps = generator.generateSupportSteps(
            for: currentStep,
            userPerformance: stepCompletionStates[currentStepIndex],
            learningStyle: learningPatterns.analyzePatterns().learningStyle
        )
        
        // Insert adaptive steps before current step
        // This would require modifying the lesson structure
        print("🎯 Generated \(adaptiveSteps.count) adaptive support steps")
    }
    
    /// Generate challenge steps for advanced users
    private func generateChallengeSteps() {
        guard let generator = adaptiveStepGenerator else { return }
        
        let currentStep = lesson.steps[currentStepIndex]
        let challengeSteps = generator.generateChallengeSteps(
            for: currentStep,
            userPerformance: stepCompletionStates[currentStepIndex],
            confidenceLevel: confidenceLevel
        )
        
        print("🚀 Generated \(challengeSteps.count) challenge steps")
    }
    
    /// Get comprehensive learning analytics
    func getLearningAnalytics() -> LearningAnalytics {
        return LearningAnalytics(
            learningVelocity: learningVelocity,
            confidenceLevel: confidenceLevel,
            frustrationLevel: frustrationLevel,
            learningPatterns: learningPatterns.analyzePatterns(),
            adaptiveDifficulty: adaptiveDifficultyLevel,
            sessionProgress: overallProgress,
            timeSpent: totalTime
        )
    }
    
    /// Reset adaptive learning state
    func resetAdaptiveLearning() {
        learningVelocity = 0.0
        confidenceLevel = 0.5
        frustrationLevel = 0.0
        learningPatterns.reset()
        adaptiveDifficultyLevel = .normal
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

// MARK: - Enhanced Adaptive Learning Data Structures

struct LearningAnalytics {
    let learningVelocity: Double
    let confidenceLevel: Double
    let frustrationLevel: Double
    let learningPatterns: LearningPatterns
    let adaptiveDifficulty: DifficultyAdjustment
    let sessionProgress: Double
    let timeSpent: TimeInterval
    
    var learningEfficiency: Double {
        return learningVelocity * confidenceLevel * (1.0 - frustrationLevel)
    }
    
    var needsSupport: Bool {
        return frustrationLevel > 0.7 || confidenceLevel < 0.3
    }
    
    var readyForChallenge: Bool {
        return confidenceLevel > 0.8 && learningVelocity > 0.1 && frustrationLevel < 0.3
    }
}

struct LearningPatterns {
    let learningStyle: LearningStyle
    let pace: LearningPace
    let strengths: [String]
    let challenges: [String]
    let recommendedApproach: String
}

enum LearningStyle {
    case visual
    case kinesthetic
    case analytical
    case mixed
}

enum LearningPace {
    case slow
    case normal
    case fast
}

class LearningPatternAnalyzer: ObservableObject {
    private var strokeData: [StrokeData] = []
    private var analysisStartTime = Date()
    
    func startAnalysis() {
        analysisStartTime = Date()
        strokeData.removeAll()
    }
    
    func recordStroke(accuracy: Double, timeSpent: TimeInterval, confidence: Double) {
        let strokeData = StrokeData(
            accuracy: accuracy,
            timeSpent: timeSpent,
            confidence: confidence,
            timestamp: Date()
        )
        self.strokeData.append(strokeData)
    }
    
    func analyzePatterns() -> LearningPatterns {
        guard !strokeData.isEmpty else {
            return LearningPatterns(
                learningStyle: .mixed,
                pace: .normal,
                strengths: [],
                challenges: [],
                recommendedApproach: "Standard approach"
            )
        }
        
        let learningStyle = determineLearningStyle()
        let pace = determineLearningPace()
        let strengths = identifyStrengths()
        let challenges = identifyChallenges()
        let recommendedApproach = generateRecommendation()
        
        return LearningPatterns(
            learningStyle: learningStyle,
            pace: pace,
            strengths: strengths,
            challenges: challenges,
            recommendedApproach: recommendedApproach
        )
    }
    
    private func determineLearningStyle() -> LearningStyle {
        // Analyze patterns to determine learning style
        let accuracyImprovement = calculateAccuracyImprovement()
        let timeConsistency = calculateTimeConsistency()
        let confidenceStability = calculateConfidenceStability()
        
        if accuracyImprovement > 0.3 && timeConsistency > 0.7 {
            return .kinesthetic
        } else if confidenceStability > 0.8 {
            return .analytical
        } else if timeConsistency < 0.5 {
            return .visual
        } else {
            return .mixed
        }
    }
    
    private func determineLearningPace() -> LearningPace {
        let averageTime = strokeData.map { $0.timeSpent }.reduce(0, +) / Double(strokeData.count)
        
        if averageTime < 10 {
            return .fast
        } else if averageTime > 30 {
            return .slow
        } else {
            return .normal
        }
    }
    
    private func identifyStrengths() -> [String] {
        var strengths: [String] = []
        
        let averageAccuracy = strokeData.map { $0.accuracy }.reduce(0, +) / Double(strokeData.count)
        if averageAccuracy > 0.8 {
            strengths.append("High accuracy")
        }
        
        let timeImprovement = calculateTimeImprovement()
        if timeImprovement > 0.2 {
            strengths.append("Speed improvement")
        }
        
        let confidenceGrowth = calculateConfidenceGrowth()
        if confidenceGrowth > 0.3 {
            strengths.append("Confidence building")
        }
        
        return strengths
    }
    
    private func identifyChallenges() -> [String] {
        var challenges: [String] = []
        
        let accuracyVariability = calculateAccuracyVariability()
        if accuracyVariability > 0.3 {
            challenges.append("Consistency")
        }
        
        let timeVariability = calculateTimeVariability()
        if timeVariability > 0.5 {
            challenges.append("Pace control")
        }
        
        let lowConfidencePeriods = strokeData.filter { $0.confidence < 0.4 }.count
        if Double(lowConfidencePeriods) / Double(strokeData.count) > 0.3 {
            challenges.append("Confidence maintenance")
        }
        
        return challenges
    }
    
    private func generateRecommendation() -> String {
        let patterns = analyzePatterns()
        
        switch patterns.learningStyle {
        case .visual:
            return "Focus on visual guides and reference images"
        case .kinesthetic:
            return "Emphasize muscle memory and repetitive practice"
        case .analytical:
            return "Provide detailed feedback and step-by-step breakdowns"
        case .mixed:
            return "Use a balanced approach with multiple learning methods"
        }
    }
    
    // Helper methods for pattern analysis
    private func calculateAccuracyImprovement() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let firstHalf = Array(strokeData.prefix(strokeData.count / 2))
        let secondHalf = Array(strokeData.suffix(strokeData.count / 2))
        
        let firstAvg = firstHalf.map { $0.accuracy }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.accuracy }.reduce(0, +) / Double(secondHalf.count)
        
        return secondAvg - firstAvg
    }
    
    private func calculateTimeConsistency() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let times = strokeData.map { $0.timeSpent }
        let average = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
        return 1.0 / (1.0 + sqrt(variance))
    }
    
    private func calculateConfidenceStability() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let confidences = strokeData.map { $0.confidence }
        let average = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.map { pow($0 - average, 2) }.reduce(0, +) / Double(confidences.count)
        return 1.0 / (1.0 + sqrt(variance))
    }
    
    private func calculateTimeImprovement() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let firstHalf = Array(strokeData.prefix(strokeData.count / 2))
        let secondHalf = Array(strokeData.suffix(strokeData.count / 2))
        
        let firstAvg = firstHalf.map { $0.timeSpent }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.timeSpent }.reduce(0, +) / Double(secondHalf.count)
        
        return (firstAvg - secondAvg) / firstAvg
    }
    
    private func calculateAccuracyVariability() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let accuracies = strokeData.map { $0.accuracy }
        let average = accuracies.reduce(0, +) / Double(accuracies.count)
        let variance = accuracies.map { pow($0 - average, 2) }.reduce(0, +) / Double(accuracies.count)
        return sqrt(variance)
    }
    
    private func calculateTimeVariability() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let times = strokeData.map { $0.timeSpent }
        let average = times.reduce(0, +) / Double(times.count)
        let variance = times.map { pow($0 - average, 2) }.reduce(0, +) / Double(times.count)
        return sqrt(variance) / average
    }
    
    private func calculateConfidenceGrowth() -> Double {
        guard strokeData.count >= 3 else { return 0.0 }
        let firstHalf = Array(strokeData.prefix(strokeData.count / 2))
        let secondHalf = Array(strokeData.suffix(strokeData.count / 2))
        
        let firstAvg = firstHalf.map { $0.confidence }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.confidence }.reduce(0, +) / Double(secondHalf.count)
        
        return secondAvg - firstAvg
    }
    
    func reset() {
        strokeData.removeAll()
        analysisStartTime = Date()
    }
}

struct StrokeData {
    let accuracy: Double
    let timeSpent: TimeInterval
    let confidence: Double
    let timestamp: Date
}

class AdaptiveStepGenerator {
    func generateSupportSteps(
        for step: LessonStep,
        userPerformance: StepCompletionState,
        learningStyle: LearningStyle
    ) -> [LessonStep] {
        var supportSteps: [LessonStep] = []
        
        // Generate simplified versions of the current step
        switch step.shapeType {
        case .circle:
            supportSteps.append(LessonStep(
                stepNumber: step.stepNumber,
                instruction: "Start with a simple dot, then expand it into a circle",
                guidancePoints: [],
                shapeType: .circle
            ))
        case .rectangle:
            supportSteps.append(LessonStep(
                stepNumber: step.stepNumber,
                instruction: "Draw two parallel lines, then connect them",
                guidancePoints: [],
                shapeType: .rectangle
            ))
        case .line:
            supportSteps.append(LessonStep(
                stepNumber: step.stepNumber,
                instruction: "Practice drawing straight lines first",
                guidancePoints: [],
                shapeType: .line
            ))
        default:
            break
        }
        
        return supportSteps
    }
    
    func generateChallengeSteps(
        for step: LessonStep,
        userPerformance: StepCompletionState,
        confidenceLevel: Double
    ) -> [LessonStep] {
        var challengeSteps: [LessonStep] = []
        
        // Generate advanced variations
        switch step.shapeType {
        case .circle:
            challengeSteps.append(LessonStep(
                stepNumber: step.stepNumber,
                instruction: "Draw a perfect circle in one smooth motion",
                guidancePoints: [],
                shapeType: .circle
            ))
        case .rectangle:
            challengeSteps.append(LessonStep(
                stepNumber: step.stepNumber,
                instruction: "Create a 3D cube with proper perspective",
                guidancePoints: [],
                shapeType: .rectangle
            ))
        default:
            break
        }
        
        return challengeSteps
    }
}

// MARK: - Drawing Engine Extension
extension DrawingAlgorithmEngine {
    func updateCurrentGuide(_ guide: DrawingGuide) {
        guard currentStep < currentGuides.count else { return }
        currentGuides[currentStep] = guide
    }
}

