import Foundation
import SwiftUI
import PencilKit
import CoreHaptics
import AVFoundation
import UIKit
import Darwin.Mach

// MARK: - Enhanced Drawing Canvas Coordinator
@MainActor
class DrawingCanvasCoordinator: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStroke: DrawingStroke?
    @Published var strokeFeedback: StrokeFeedback?
    @Published var showVisualFeedback = false
    @Published var currentAccuracy: Double = 0.0
    @Published var stepProgress: Double = 0.0
    @Published var isStepComplete = false
    @Published var showCelebration = false
    
    // MARK: - Enhanced DTW Feedback Properties
    @Published var dtwAccuracy: Double = 0.0
    @Published var temporalAccuracy: Double = 0.0
    @Published var velocityConsistency: Double = 0.0
    @Published var confidenceScore: Double = 0.0
    @Published var showDTWInsights = false
    @Published var dtwFeedbackMessage: String = ""
    @Published var dtwFeedbackColor: Color = .blue
    
    // MARK: - Drawing Engine Integration
    private let drawingEngine: DrawingAlgorithmEngine
    private let strokeAnalyzer = UnifiedStrokeAnalyzer()
    
    // MARK: - DTW Performance Monitoring  
    private var performanceCallback: ((Double) -> Void)?
    
    // MARK: - Feedback Systems
    private var hapticEngine: CHHapticEngine?
    private var audioPlayer: AVAudioPlayer?
    private var feedbackTimer: Timer?
    
    // MARK: - REAL-TIME UI OPTIMIZATION: Frame-Rate Aware Processing  
    private var activeStrokes: [PKStroke] = []
    private var strokeBuffer = CircularBuffer<CGPoint>(size: 150) // Optimized size based on Phase 2 analytics
    private var lastStrokeAnalysisTime = Date()
    
    // INDUSTRY STANDARD: Frame-rate aware throttling (16ms for 60fps, 8ms for 120fps)
    private var targetFrameRate: Double = 60.0 // Will be detected from device
    private var frameAwareThrottleInterval: TimeInterval {
        return 1.0 / targetFrameRate // 16.67ms for 60fps, 8.33ms for 120fps
    }
    
    // REAL-TIME PROCESSING: Incremental analysis state
    private var currentAnalysisTask: Task<Void, Never>?
    private var pendingAnalysisPoints: [CGPoint] = []
    private let processingQueue = DispatchQueue(label: "realtime.dtw", qos: .userInteractive)
    
    // PHASE 2: Advanced Memory Prediction and Monitoring
    private var memoryPressureObserver: NSObjectProtocol?
    private let memoryPredictor = MemoryPredictor()
    private let preemptiveCleanupManager = PreemptiveCleanupManager()
    private let memoryAnalytics = MemoryAnalytics()
    private var consecutiveAnalysisCount = 0
    private var lastMemoryCleanupTime = Date()
    private var adaptiveCleanupInterval: TimeInterval = 25.0 // PHASE 2: Dynamic cleanup interval based on usage patterns
    
    // PHASE 1 FIX: Add missing analysisThrottleInterval
    private var analysisThrottleInterval: TimeInterval = 0.12 // 120ms base interval for analysis throttling
    
    // MEMORY OPTIMIZATION: Add memory pressure monitoring
    private var memoryPressureLevel: Int = 0
    private var lastMemoryCheck = Date()
    private let memoryCheckInterval: TimeInterval = 5.0 // Check memory every 5 seconds
    
    // PHASE 2 FIX: Add missing currentMemoryMB property
    private var currentMemoryMB: Double {
        return getCurrentMemoryUsageMB()
    }
    
    // MARK: - Step Management
    var currentStep = 0
    private var stepStartTime = Date()
    private var stepStrokes: [DrawingStroke] = []
    
    // MEMORY FIX: Conservative limits only for extreme cases
    private let maxStepStrokes = 10000 // Very high limit - only for extreme memory pressure
    private let maxAnalysisCacheSize = 500 // Reasonable cache size for analysis
    
    // MARK: - Configuration
    private struct Config {
        static let minStrokePoints = 3
        static let maxStrokeBufferSize = 100
        static let accuracyThreshold = 0.7
        static let celebrationDelay: TimeInterval = 1.0
        static let feedbackDuration: TimeInterval = 2.0
    }
    
    init(drawingEngine: DrawingAlgorithmEngine) {
        self.drawingEngine = drawingEngine
        super.init()
        setupHapticEngine()
        setupAudioFeedback()
        setupDTWIntegration()
        detectDisplayRefreshRate()
    }
    
    // INDUSTRY STANDARD: Detect device display refresh rate for optimal throttling
    private func detectDisplayRefreshRate() {
        // Use device-specific frame rate detection since UIScreenMode.refreshRate is not available
        DispatchQueue.main.async {
            self.targetFrameRate = self.getDeviceOptimalFrameRate()
            print("🎯 REAL-TIME: Detected refresh rate: \(self.targetFrameRate)fps")
        }
    }
    
    // INDUSTRY STANDARD: Device-specific frame rate optimization
    private func getDeviceOptimalFrameRate() -> Double {
        let processorCount = ProcessInfo.processInfo.processorCount
        let memorySize = ProcessInfo.processInfo.physicalMemory
        
        // High-end devices can handle 120fps processing
        if processorCount >= 6 && memorySize >= 6_000_000_000 {
            return 120.0 // iPhone 13 Pro+ capabilities
        }
        // Mid-range devices optimized for 60fps
        else if processorCount >= 4 {
            return 60.0
        }
        // Lower-end devices use 30fps for stability
        else {
            return 30.0
        }
    }
    
    // MARK: - Essential Helper Functions (moved up for accessibility)
    
    private func getCurrentMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        
        return 50.0 // Safe default
    }
    
    private func calculateMaxAnalysisCount(memoryUsage: Double) -> Int {
        // Reduce max analysis count as memory usage increases
        if memoryUsage > 120.0 {
            return 20
        } else if memoryUsage > 80.0 {
            return 35
        } else if memoryUsage > 60.0 {
            return 45
        } else {
            return 60
        }
    }
    
    private func performPredictiveCleanup(prediction: MemoryPredictor.MemoryPrediction) {
        let memoryBefore = getCurrentMemoryUsageMB()
        
        switch prediction.recommendedAction {
        case .lightCleanup:
            performLightCleanup()
        case .aggressiveCleanup:
            performAggressiveCleanup()
        case .suspendOperations:
            performEmergencyCleanup()
        case .none:
            return
        }
        
        let memoryAfter = getCurrentMemoryUsageMB()
        memoryAnalytics.recordOperation(
            operation: "predictive_cleanup_\(prediction.recommendedAction)",
            memoryBefore: memoryBefore,
            memoryAfter: memoryAfter,
            duration: 0.1, // Estimate cleanup duration
            success: memoryAfter < memoryBefore
        )
        
        // Update adaptive cleanup interval based on effectiveness
        updateAdaptiveCleanupInterval(memoryRecovered: memoryBefore - memoryAfter)
    }
    
    private func performLightCleanup() {
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            strokeBuffer = CircularBuffer<CGPoint>(size: 120)
            // Only trim during actual memory pressure - keep most strokes
            if stepStrokes.count > 500 {
                stepStrokes = Array(stepStrokes.suffix(400)) // Keep 80% of strokes
            }
        }
        print("🧹 [DrawingCanvasCoordinator] Light cleanup performed with autoreleasepool")
    }
    
    private func performAggressiveCleanup() {
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            strokeBuffer = CircularBuffer<CGPoint>(size: 80)
            // Only trim during actual memory pressure - keep most strokes
            if stepStrokes.count > 200 {
                stepStrokes = Array(stepStrokes.suffix(150)) // Keep 75% of strokes
            }
            activeStrokes.removeAll(keepingCapacity: false)
            consecutiveAnalysisCount = 0
        }
        print("🧹 [DrawingCanvasCoordinator] Aggressive cleanup performed with autoreleasepool")
    }
    
    private func performEmergencyCleanup() {
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            strokeBuffer = CircularBuffer<CGPoint>(size: 50)
            // Only trim during emergency - keep most strokes
            if stepStrokes.count > 100 {
                stepStrokes = Array(stepStrokes.suffix(80)) // Keep 80% of strokes even in emergency
            }
            activeStrokes.removeAll(keepingCapacity: false)
            consecutiveAnalysisCount = 0
            
            // Clear any pending video frames
            // Note: Video recording engine cleanup handled separately
        }
        print("🚨 [DrawingCanvasCoordinator] Emergency cleanup performed with autoreleasepool")
    }
    
    private func updateAdaptiveCleanupInterval(memoryRecovered: Double) {
        // Adjust cleanup interval based on effectiveness
        if memoryRecovered > 10.0 {
            // Cleanup was very effective, can wait longer
            adaptiveCleanupInterval = min(35.0, adaptiveCleanupInterval * 1.2)
        } else if memoryRecovered < 2.0 {
            // Cleanup wasn't very effective, clean more frequently
            adaptiveCleanupInterval = max(15.0, adaptiveCleanupInterval * 0.8)
        }
        // Otherwise keep current interval
    }
    
    // MARK: - Unified Core ML Integration Setup with Memory Management
    private func setupDTWIntegration() {
        // Configure unified Core ML analyzer for optimal performance
        // Note: UnifiedStrokeAnalyzer is now used directly
        
        // PHASE 1 FIX: Setup memory pressure monitoring
        setupMemoryPressureMonitoring()
    }
    
    // PHASE 1 FIX: Memory pressure monitoring
    private func setupMemoryPressureMonitoring() {
        memoryPressureObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryPressure()
            }
        }
        
        // MEMORY OPTIMIZATION: Add periodic memory monitoring
        Timer.scheduledTimer(withTimeInterval: memoryCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMemoryPressure()
            }
        }
    }
    
    // MEMORY OPTIMIZATION: Proactive memory pressure checking
    private func checkMemoryPressure() {
        let currentMemory = getCurrentMemoryUsageMB()
        let now = Date()
        
        // Update memory pressure level based on usage (optimized for drawing apps)
        if currentMemory > 800.0 {
            memoryPressureLevel = 3 // Critical
            print("🚨 MEMORY: Critical memory pressure detected: \(currentMemory)MB")
            performEmergencyCleanup()
        } else if currentMemory > 600.0 {
            memoryPressureLevel = 2 // High
            print("⚠️ MEMORY: High memory pressure detected: \(currentMemory)MB")
            performAggressiveCleanup()
        } else if currentMemory > 400.0 {
            memoryPressureLevel = 1 // Medium
            print("📊 MEMORY: Medium memory pressure detected: \(currentMemory)MB")
            performLightCleanup()
        } else {
            memoryPressureLevel = 0 // Normal
        }
        
        lastMemoryCheck = now
    }
    
    @MainActor
    private func handleMemoryPressure() {
        // ENHANCED: More aggressive memory cleanup with autoreleasepool
        autoreleasepool {
            // PHASE 1 FIX: More aggressive memory cleanup
            strokeBuffer = CircularBuffer<CGPoint>(size: 100) // REDUCED to 100 during pressure
            
            // Only trim during memory pressure - keep most strokes
            if stepStrokes.count > 300 {
                stepStrokes = Array(stepStrokes.suffix(250)) // Keep 83% of strokes
            }
            
            // Force garbage collection with immediate cleanup
            activeStrokes.removeAll(keepingCapacity: false)
            activeStrokes = []
            
            // Reset analysis counter
            consecutiveAnalysisCount = 0
            
            // Clear any pending video frames
            // Note: Video recording engine cleanup handled separately
        }
        lastMemoryCleanupTime = Date()
        
        print("🧠 PHASE 1 Memory pressure handled: Aggressive cleanup performed")
        
        // PHASE 1 FIX: Force garbage collection if available
        #if DEBUG
        print("📊 Memory cleanup stats - StepStrokes: \(stepStrokes.count), Buffer size: \(strokeBuffer.count)")
        #endif
    }
    
    // MARK: - Haptic Feedback Setup
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine setup failed: \(error)")
        }
    }
    
    // MARK: - Audio Feedback Setup
    private func setupAudioFeedback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - REAL-TIME UI OPTIMIZATION: Non-Blocking Incremental Analysis
    func analyzeStrokeInProgress(_ points: [CGPoint], pressure: [CGFloat] = [], velocity: [CGFloat] = []) async {
        print("🎨 [CANVAS COORDINATOR] ========================================")
        print("🎨 [CANVAS COORDINATOR] Starting stroke analysis for \(points.count) points")
        
        // MEMORY OPTIMIZATION: Check memory pressure before analysis
        if memoryPressureLevel >= 2 {
            print("⚠️ [CANVAS COORDINATOR] Skipping stroke analysis due to high memory pressure (level: \(memoryPressureLevel))")
            return
        }
        
        // CRITICAL FIX: Increased throttling to reduce excessive event dispatching (50ms intervals)
        let now = Date()
        guard now.timeIntervalSince(lastStrokeAnalysisTime) >= 0.05 else { 
            print("⏱️ [CANVAS COORDINATOR] Throttling analysis - too soon since last analysis")
            // Accumulate points for next frame
            pendingAnalysisPoints.append(contentsOf: points)
            return 
        }
        lastStrokeAnalysisTime = now
        
        // INDUSTRY STANDARD: Process accumulated points from multiple frames
        let allNewPoints = pendingAnalysisPoints + points
        pendingAnalysisPoints.removeAll(keepingCapacity: true)
        
        // REAL-TIME: Cancel previous analysis if still running
        currentAnalysisTask?.cancel()
        
        // INDUSTRY STANDARD: Non-blocking incremental analysis
        currentAnalysisTask = Task {
            await performIncrementalAnalysis(allNewPoints, pressure: pressure, velocity: velocity)
        }
        
        // PHASE 2: Increment analysis count with predictive limit
        consecutiveAnalysisCount += 1
        let maxAnalysisCount = calculateMaxAnalysisCount(memoryUsage: currentMemoryMB)
        if consecutiveAnalysisCount > maxAnalysisCount {
            performScheduledMemoryCleanup()
            return
        }
        
        // PHASE 2: Dynamic cleanup interval based on memory prediction
        if now.timeIntervalSince(lastMemoryCleanupTime) >= adaptiveCleanupInterval {
            performScheduledMemoryCleanup()
        }
        
        // PHASE 1 FIX: Use circular buffer for memory efficiency
        for point in points {
            strokeBuffer.append(point)
        }
        
        // Get current buffer contents
        let currentBufferPoints = strokeBuffer.toArray()
        
        // Only analyze if we have enough points
        guard currentBufferPoints.count >= Config.minStrokePoints else { return }
        
        // Create current stroke for analysis
        let currentStroke = DrawingStroke(
            points: currentBufferPoints,
            timestamp: Date(),
            pressure: pressure.isEmpty ? Array(repeating: 1.0, count: currentBufferPoints.count) : pressure,
            velocity: velocity.isEmpty ? Array(repeating: 1.0, count: currentBufferPoints.count) : velocity
        )
        
        // Get current drawing guide
        guard let currentGuide = drawingEngine.getCurrentGuide() else { 
            print("⚠️ [CANVAS COORDINATOR] No current guide available for analysis")
            return 
        }
        
        print("🎯 [CANVAS COORDINATOR] Analyzing stroke against guide: \(currentGuide.shapes.first?.type.rawValue ?? "unknown")")
        
        // ENHANCED: Use DTW-enabled analyzer for better accuracy
        let feedback = await strokeAnalyzer.analyzeStroke(currentStroke, against: currentGuide)
        
        print("📊 [CANVAS COORDINATOR] Analysis complete:")
        print("   📈 Accuracy: \(String(format: "%.3f", feedback.accuracy))")
        print("   ✅ Is correct: \(feedback.isCorrect)")
        print("   💬 Suggestions: \(feedback.suggestions.count)")
        
        // Update UI on main thread
        DispatchQueue.main.async {
            self.currentStroke = currentStroke
            self.strokeFeedback = feedback
            self.currentAccuracy = feedback.accuracy
            self.updateVisualFeedback(feedback)
            self.updateStepProgress()
            print("🔄 [CANVAS COORDINATOR] UI updated with new feedback")
        }
    }
    
    // INDUSTRY STANDARD: Incremental analysis with yield points for UI responsiveness
    private func performIncrementalAnalysis(_ points: [CGPoint], pressure: [CGFloat], velocity: [CGFloat]) async {
        // REAL-TIME: Early exit if task was cancelled
        if Task.isCancelled { return }
        
        // INDUSTRY STANDARD: Memory prediction in background
        let currentMemoryMB = getCurrentMemoryUsageMB()
        
        memoryPredictor.recordUsage(currentMemoryMB, strokeCount: stepStrokes.count, operationType: .strokeAnalysis)
        
        // REAL-TIME: Check for memory pressure asynchronously
        if let prediction = memoryPredictor.getCurrentPrediction(),
           preemptiveCleanupManager.shouldPerformCleanup(prediction: prediction) {
            performPredictiveCleanup(prediction: prediction)
        }
        
        // INDUSTRY STANDARD: Yield to UI thread after memory checks
        if Task.isCancelled { return }
        await Task.yield()
        
        // REAL-TIME: Add points to buffer incrementally
        await MainActor.run {
            for point in points {
                strokeBuffer.append(point)
            }
        }
        
        // INDUSTRY STANDARD: Get buffer contents without blocking main thread
        let currentBufferPoints = await MainActor.run {
            return strokeBuffer.toArray()
        }
        
        // REAL-TIME: Early exit if insufficient points
        guard currentBufferPoints.count >= Config.minStrokePoints else { return }
        if Task.isCancelled { return }
        
        // INDUSTRY STANDARD: Create stroke data in background
        let currentStroke = await Task.detached(priority: .userInitiated) {
            return DrawingStroke(
                points: currentBufferPoints,
                timestamp: Date(),
                pressure: pressure.isEmpty ? Array(repeating: 1.0, count: currentBufferPoints.count) : pressure,
                velocity: velocity.isEmpty ? Array(repeating: 1.0, count: currentBufferPoints.count) : velocity
            )
        }.value
        
        // REAL-TIME: Get guide on main thread
        let currentGuide = await MainActor.run {
            return drawingEngine.getCurrentGuide()
        }
        
        guard let guide = currentGuide else { return }
        if Task.isCancelled { return }
        
        // INDUSTRY STANDARD: Perform DTW analysis with yield points
        let feedback = await performDTWAnalysisWithYields(currentStroke, against: guide)
        
        if Task.isCancelled { return }
        
        // REAL-TIME: Update UI on main thread
        await MainActor.run {
            self.currentStroke = currentStroke
            self.strokeFeedback = feedback
            self.currentAccuracy = feedback.accuracy
            self.updateVisualFeedback(feedback)
            self.updateStepProgress()
        }
    }
    
    // INDUSTRY STANDARD: DTW analysis with yield points for UI responsiveness
    private func performDTWAnalysisWithYields(_ stroke: DrawingStroke, against guide: DrawingGuide) async -> StrokeFeedback {
        return await Task.detached(priority: .userInitiated) {
            // REAL-TIME: Create incremental DTW analyzer
            return await IncrementalDTWAnalyzer.analyze(stroke, against: guide)
        }.value
    }
    
    // MARK: - Stroke Completion Analysis
    func analyzeCompletedStroke(_ stroke: PKStroke) async {
        print("📊 [TUTORIAL] Analyzing completed stroke with \(stroke.path.count) points")
        
        // Extract stroke data
        let points = extractPointsFromStroke(stroke)
        let pressure = extractPressureFromStroke(stroke)
        let velocity = extractVelocityFromStroke(stroke)
        
        print("✅ [TUTORIAL] Extracted stroke data - Points: \(points.count), Pressure: \(pressure.count), Velocity: \(velocity.count)")
        
        let drawingStroke = DrawingStroke(
            points: points,
            timestamp: Date(),
            pressure: pressure,
            velocity: velocity
        )
        
        // Add to step strokes (NO LIMITS during normal drawing - users can draw as much as they want)
        stepStrokes.append(drawingStroke)
        
        print("📝 [TUTORIAL] Added stroke to step collection (total: \(stepStrokes.count))")
        
        // Get current guide
        guard let currentGuide = drawingEngine.getCurrentGuide() else { 
            print("❌ [TUTORIAL] No current guide available for stroke analysis")
            return 
        }
        
        print("📋 [TUTORIAL] Current guide found for analysis")
        
        // ENHANCED: Analyze completed stroke with DTW support
        let feedback = await strokeAnalyzer.analyzeStroke(drawingStroke, against: currentGuide)
        print("📈 [TUTORIAL] Stroke analysis complete - Accuracy: \(feedback.accuracy), Correct: \(feedback.isCorrect)")
        
        // Update UI and provide feedback
        DispatchQueue.main.async {
            self.strokeFeedback = feedback
            self.currentAccuracy = feedback.accuracy
            print("✅ [TUTORIAL] Updated UI with stroke feedback")
            self.provideFeedback(for: feedback)
            print("🎯 [TUTORIAL] Provided feedback to user")
            Task {
                await self.checkStepCompletion()
            }
            print("🔍 [TUTORIAL] Checked step completion")
        }
        
        // Clear stroke buffer for next stroke  
        strokeBuffer = CircularBuffer<CGPoint>(size: 150) // REDUCED from 200 to 150
        print("🧹 [TUTORIAL] Cleared stroke buffer for next stroke")
    }
    
    // MARK: - PHASE 1 FIX: Scheduled Memory Cleanup
    private func performScheduledMemoryCleanup() {
        // Reset consecutive analysis counter
        consecutiveAnalysisCount = 0
        lastMemoryCleanupTime = Date()
        
        // Only trim step strokes during scheduled cleanup (not during normal drawing)
        if stepStrokes.count > 1000 {
            stepStrokes = Array(stepStrokes.suffix(800)) // Keep 80% of strokes during cleanup
        }
        
        // Recreate stroke buffer with smaller size during cleanup
        strokeBuffer = CircularBuffer<CGPoint>(size: 100)
        
        // Cleanup active strokes array
        if activeStrokes.count > 10 {
            activeStrokes = Array(activeStrokes.suffix(5))
        }
        
        print("🧹 PHASE 1 Scheduled memory cleanup performed")
    }
    
    // MARK: - Visual Feedback Management
    private func updateVisualFeedback(_ feedback: StrokeFeedback) {
        print("👁️ [VISUAL FEEDBACK] Updating visual feedback:")
        print("   ✅ Is correct: \(feedback.isCorrect)")
        print("   📊 Accuracy: \(String(format: "%.3f", feedback.accuracy))")
        
        showVisualFeedback = !feedback.isCorrect
        
        print("👁️ [VISUAL FEEDBACK] Show visual feedback: \(showVisualFeedback)")
        
        // ENHANCED: Update DTW-specific feedback
        updateDTWFeedback(feedback)
        
        // Auto-hide feedback after duration
        feedbackTimer?.invalidate()
        if showVisualFeedback {
            print("⏰ [VISUAL FEEDBACK] Setting auto-hide timer for \(Config.feedbackDuration) seconds")
            feedbackTimer = Timer.scheduledTimer(withTimeInterval: Config.feedbackDuration, repeats: false) { _ in
                DispatchQueue.main.async {
                    print("👁️ [VISUAL FEEDBACK] Auto-hiding feedback")
                    self.showVisualFeedback = false
                    self.showDTWInsights = false
                }
            }
        }
    }
    
    // MARK: - Enhanced DTW Feedback Management
    private func updateDTWFeedback(_ feedback: StrokeFeedback) {
        print("🎯 [DTW FEEDBACK] Updating DTW-specific feedback:")
        
        // Update DTW-specific metrics from enhanced feedback
        if let dtwDistance = feedback.dtwDistance {
            dtwAccuracy = 1.0 - min(dtwDistance, 1.0) // Convert distance to accuracy
            print("   📊 DTW Distance: \(String(format: "%.3f", dtwDistance))")
        } else {
            dtwAccuracy = feedback.accuracy
            print("   📊 Using standard accuracy: \(String(format: "%.3f", feedback.accuracy))")
        }
        
        temporalAccuracy = feedback.temporalAccuracy ?? 0.0
        velocityConsistency = feedback.velocityConsistency ?? 0.0
        confidenceScore = feedback.confidenceScore ?? 0.0
        
        print("   ⏱️ Temporal Accuracy: \(String(format: "%.3f", temporalAccuracy))")
        print("   🚀 Velocity Consistency: \(String(format: "%.3f", velocityConsistency))")
        print("   🎯 Confidence Score: \(String(format: "%.3f", confidenceScore))")
        
        // Generate user-friendly DTW feedback message
        generateDTWFeedbackMessage(feedback)
        
        // Show DTW insights if we have enhanced data
        showDTWInsights = feedback.dtwDistance != nil || feedback.temporalAccuracy != nil
    }
    
    private func generateDTWFeedbackMessage(_ feedback: StrokeFeedback) {
        print("💬 [DTW FEEDBACK] Generating user-friendly message for accuracy: \(String(format: "%.3f", dtwAccuracy))")
        
        if dtwAccuracy >= 0.9 {
            dtwFeedbackMessage = "🎯 Perfect path following!"
            dtwFeedbackColor = .green
            print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Green)")
        } else if dtwAccuracy >= 0.7 {
            dtwFeedbackMessage = "✨ Great stroke accuracy"
            dtwFeedbackColor = .blue
            print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Blue)")
        } else if dtwAccuracy >= 0.5 {
            if temporalAccuracy < 0.6 {
                dtwFeedbackMessage = "⏱️ Try a steadier pace"
                dtwFeedbackColor = .orange
                print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Orange - Temporal)")
            } else if velocityConsistency < 0.6 {
                dtwFeedbackMessage = "🖋️ Focus on smooth strokes"
                dtwFeedbackColor = .orange
                print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Orange - Velocity)")
            } else {
                dtwFeedbackMessage = "📍 Follow the guide more closely"
                dtwFeedbackColor = .orange
                print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Orange - General)")
            }
        } else {
            dtwFeedbackMessage = "💡 Try again - you've got this!"
            dtwFeedbackColor = .red
            print("💬 [DTW FEEDBACK] Message: \(dtwFeedbackMessage) (Red)")
        }
    }
    
    // MARK: - Step Progress Management
    private func updateStepProgress() {
        let targetAccuracy = Config.accuracyThreshold
        let progress = min(currentAccuracy / targetAccuracy, 1.0)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            stepProgress = progress
        }
    }
    
    private func checkStepCompletion() async {
        guard let currentGuide = drawingEngine.getCurrentGuide() else { return }
        
        // Calculate overall step accuracy with enhanced analyzer
        var stepAccuracies: [Double] = []
        for stroke in stepStrokes {
            let accuracy = await strokeAnalyzer.analyzeStroke(stroke, against: currentGuide).accuracy
            stepAccuracies.append(accuracy)
        }
        
        let overallAccuracy = stepAccuracies.isEmpty ? 0.0 : stepAccuracies.reduce(0, +) / Double(stepAccuracies.count)
        
        if overallAccuracy >= Config.accuracyThreshold && !isStepComplete {
            completeCurrentStep()
        }
    }
    
    private func completeCurrentStep() {
        isStepComplete = true
        
        // Celebration feedback
        provideSuccessFeedback()
        
        // Show celebration animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showCelebration = true
        }
        
        // Auto-hide celebration and prepare for next step
        DispatchQueue.main.asyncAfter(deadline: .now() + Config.celebrationDelay) {
            withAnimation {
                self.showCelebration = false
                self.prepareForNextStep()
            }
        }
    }
    
    // MARK: - Step Navigation
    func nextStep() {
        guard drawingEngine.currentStep < drawingEngine.currentGuides.count - 1 else { return }
        
        drawingEngine.nextStep()
        prepareForNextStep()
    }
    
    func previousStep() {
        guard drawingEngine.currentStep > 0 else { return }
        
        drawingEngine.previousStep()
        prepareForNextStep()
    }
    
    private func prepareForNextStep() {
        // Reset step state
        stepStrokes.removeAll()
        stepStartTime = Date()
        isStepComplete = false
        
        // Reset progress indicators
        withAnimation {
            stepProgress = 0.0
            currentAccuracy = 0.0
        }
        
        // Clear visual feedback
        showVisualFeedback = false
        feedbackTimer?.invalidate()
    }
    
    // MARK: - Feedback Systems
    private func provideFeedback(for feedback: StrokeFeedback) {
        if feedback.isCorrect {
            providePositiveFeedback()
        } else {
            provideCorrectionFeedback(feedback)
        }
    }
    
    private func providePositiveFeedback() {
        // Haptic feedback
        provideHapticFeedback(type: .success)
        
        // Audio feedback
        playAudioFeedback(type: .success)
    }
    
    private func provideCorrectionFeedback(_ feedback: StrokeFeedback) {
        // Provide gentle correction feedback
        provideHapticFeedback(type: .warning)
        
        // Audio feedback
        playAudioFeedback(type: .guidance)
    }
    
    private func provideSuccessFeedback() {
        // Strong positive feedback for step completion
        provideHapticFeedback(type: .celebration)
        playAudioFeedback(type: .celebration)
    }
    
    // MARK: - Haptic Feedback Implementation
    private func provideHapticFeedback(type: HapticFeedbackType) {
        guard let hapticEngine = hapticEngine else { return }
        
        do {
            let pattern = createHapticPattern(for: type)
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic feedback failed: \(error)")
        }
    }
    
    private func createHapticPattern(for type: HapticFeedbackType) -> CHHapticPattern {
        var events: [CHHapticEvent] = []
        
        switch type {
        case .success:
            // Single gentle pulse
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            )
            events.append(event)
            
        case .warning:
            // Double gentle pulse
            for i in 0..<2 {
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: TimeInterval(i) * 0.1
                )
                events.append(event)
            }
            
        case .celebration:
            // Triple ascending pulse
            for i in 0..<3 {
                let intensity = 0.6 + (Float(i) * 0.2)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: TimeInterval(i) * 0.15
                )
                events.append(event)
            }
        }
        
        do {
            return try CHHapticPattern(events: events, parameters: [])
        } catch {
            print("Haptic pattern creation failed: \(error)")
            // Return empty pattern as fallback
            return try! CHHapticPattern(events: [], parameters: [])
        }
    }
    
    // MARK: - Audio Feedback Implementation
    private func playAudioFeedback(type: AudioFeedbackType) {
        // In a production app, you would use actual audio files
        // For now, we'll use system sounds
        switch type {
        case .success:
            AudioServicesPlaySystemSound(1057) // Pop sound
        case .guidance:
            AudioServicesPlaySystemSound(1106) // Gentle tick
        case .celebration:
            AudioServicesPlaySystemSound(1016) // Achievement sound
        }
    }
    
    // MARK: - Stroke Data Extraction
    private func extractPointsFromStroke(_ stroke: PKStroke) -> [CGPoint] {
        return stroke.path.map { $0.location }
    }
    
    private func extractPressureFromStroke(_ stroke: PKStroke) -> [CGFloat] {
        return stroke.path.map { $0.force }
    }
    
    private func extractVelocityFromStroke(_ stroke: PKStroke) -> [CGFloat] {
        let points = stroke.path
        var velocities: [CGFloat] = []
        
        for i in 1..<points.count {
            let timeDelta = points[i].timeOffset - points[i-1].timeOffset
            let distance = sqrt(
                pow(points[i].location.x - points[i-1].location.x, 2) +
                pow(points[i].location.y - points[i-1].location.y, 2)
            )
            let velocity = timeDelta > 0 ? distance / CGFloat(timeDelta) : 0
            velocities.append(velocity)
        }
        
        if !velocities.isEmpty {
            velocities.insert(velocities.first!, at: 0) // First point gets same velocity as second
        }
        
        return velocities
    }
    
    // MARK: - DTW Performance Monitoring
    func setAnalysisPerformanceCallback(_ callback: @escaping (Double) -> Void) {
        self.performanceCallback = callback
    }
    
    // MARK: - Public Methods
    func clearStrokeBuffer() {
        strokeBuffer = CircularBuffer<CGPoint>(size: 150) // REDUCED from 200 to 150
        consecutiveAnalysisCount = 0 // PHASE 1 FIX: Reset analysis counter
    }
    
    // MARK: - Cleanup
    deinit {
        feedbackTimer?.invalidate()
        hapticEngine?.stop()
        
        // PHASE 1 FIX: Cleanup memory pressure observer
        if let observer = memoryPressureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Analytics and Memory Prediction Methods
    
    /// Get memory analytics report
    func getMemoryAnalyticsReport() -> MemoryAnalytics.MemoryReport {
        return memoryAnalytics.getMemoryReport()
    }
    
    /// Get current memory prediction
    func getCurrentMemoryPrediction() -> MemoryPredictor.MemoryPrediction? {
        return memoryPredictor.getCurrentPrediction()
    }
}

// MARK: - Supporting Enums
enum HapticFeedbackType {
    case success
    case warning
    case celebration
}

enum AudioFeedbackType {
    case success
    case guidance
    case celebration
}

// MARK: - Audio Services Import
import AudioToolbox

// MARK: - PHASE 1 FIX: Memory-Efficient CircularBuffer Implementation
struct CircularBuffer<T> {
    private var buffer: [T?]
    private var head = 0
    private var tail = 0
    private var capacity: Int
    private var isFull = false
    
    init(size: Int) {
        // PHASE 1 FIX: Limit maximum buffer size to prevent memory issues
        let safeSize = min(size, 200) // Never exceed 200 elements
        capacity = max(safeSize, 10) // Minimum 10 elements for functionality
        buffer = [T?](repeating: nil, count: capacity)
    }
    
    mutating func append(_ element: T) {
        buffer[tail] = element
        if isFull {
            head = (head + 1) % capacity
        }
        tail = (tail + 1) % capacity
        isFull = tail == head
    }
    
    func toArray() -> [T] {
        if isFull {
            let firstPart = Array(buffer[head..<capacity]).compactMap { $0 }
            let secondPart = Array(buffer[0..<tail]).compactMap { $0 }
            return firstPart + secondPart
        } else {
            return Array(buffer[head..<tail]).compactMap { $0 }
        }
    }
    
    var isEmpty: Bool {
        return !isFull && head == tail
    }
    
    var count: Int {
        if isFull {
            return capacity
        } else if tail >= head {
            return tail - head
        } else {
            return capacity - head + tail
        }
    }
}

// MARK: - PHASE 2: Advanced Memory Prediction and Pre-emptive Cleanup Classes

/// PHASE 2: Advanced memory usage prediction using ML-like algorithms
class MemoryPredictor {
    private var usageHistory: [MemoryUsageSample] = []
    private let maxHistorySize = 50
    private var lastPrediction: MemoryPrediction?
    
    struct MemoryUsageSample {
        let timestamp: Date
        let memoryUsageMB: Double
        let strokeCount: Int
        let operationType: OperationType
        let deviceThermalState: ProcessInfo.ThermalState
        
        enum OperationType {
            case strokeAnalysis, dtwCalculation, realTimeUpdate, cleanup
        }
    }
    
    struct MemoryPrediction {
        let predictedUsageMB: Double
        let confidenceLevel: Double
        let recommendedAction: RecommendedAction
        let timeToAction: TimeInterval
        
        enum RecommendedAction {
            case none, lightCleanup, aggressiveCleanup, suspendOperations
        }
    }
    
    func recordUsage(_ memoryUsageMB: Double, strokeCount: Int, operationType: MemoryUsageSample.OperationType) {
        let sample = MemoryUsageSample(
            timestamp: Date(),
            memoryUsageMB: memoryUsageMB,
            strokeCount: strokeCount,
            operationType: operationType,
            deviceThermalState: ProcessInfo.processInfo.thermalState
        )
        
        usageHistory.append(sample)
        
        // Maintain circular buffer
        if usageHistory.count > maxHistorySize {
            usageHistory.removeFirst(usageHistory.count - maxHistorySize)
        }
        
        // Update prediction
        lastPrediction = generatePrediction()
    }
    
    func getCurrentPrediction() -> MemoryPrediction? {
        return lastPrediction
    }
    
    private func generatePrediction() -> MemoryPrediction {
        guard usageHistory.count >= 3 else {
            return MemoryPrediction(
                predictedUsageMB: 50.0,
                confidenceLevel: 0.3,
                recommendedAction: .none,
                timeToAction: 60.0
            )
        }
        
        // PHASE 2: Advanced trend analysis
        let recentSamples = Array(usageHistory.suffix(10))
        let memoryTrend = calculateMemoryTrend(recentSamples)
        let deviceState = ProcessInfo.processInfo.thermalState
        
        // Predict memory usage for next 30 seconds
        let currentUsage = recentSamples.last?.memoryUsageMB ?? 50.0
        let predictedUsage = currentUsage + (memoryTrend * 30.0) // 30 seconds ahead
        
        // Calculate confidence based on trend consistency
        let confidence = calculateConfidence(recentSamples)
        
        // Determine recommended action
        let recommendedAction = determineRecommendedAction(
            currentUsage: currentUsage,
            predictedUsage: predictedUsage,
            deviceState: deviceState,
            confidence: confidence
        )
        
        // Calculate time to action
        let timeToAction = calculateTimeToAction(
            currentUsage: currentUsage,
            trend: memoryTrend,
            action: recommendedAction
        )
        
        return MemoryPrediction(
            predictedUsageMB: predictedUsage,
            confidenceLevel: confidence,
            recommendedAction: recommendedAction,
            timeToAction: timeToAction
        )
    }
    
    private func calculateMemoryTrend(_ samples: [MemoryUsageSample]) -> Double {
        guard samples.count >= 2 else { return 0.0 }
        
        let timeWeights = Array(1...samples.count).map { Double($0) }
        let totalWeight = timeWeights.reduce(0, +)
        
        var weightedChange = 0.0
        for i in 1..<samples.count {
            let change = samples[i].memoryUsageMB - samples[i-1].memoryUsageMB
            let timeDiff = samples[i].timestamp.timeIntervalSince(samples[i-1].timestamp)
            let rate = timeDiff > 0 ? change / timeDiff : 0.0
            
            weightedChange += rate * timeWeights[i] / totalWeight
        }
        
        return weightedChange
    }
    
    private func calculateConfidence(_ samples: [MemoryUsageSample]) -> Double {
        guard samples.count >= 3 else { return 0.3 }
        
        // Calculate consistency of trend
        var changes: [Double] = []
        for i in 1..<samples.count {
            let change = samples[i].memoryUsageMB - samples[i-1].memoryUsageMB
            changes.append(change)
        }
        
        let avgChange = changes.reduce(0, +) / Double(changes.count)
        let variance = changes.map { pow($0 - avgChange, 2) }.reduce(0, +) / Double(changes.count)
        let consistency = max(0.0, 1.0 - sqrt(variance) / max(abs(avgChange), 1.0))
        
        return min(0.95, max(0.1, consistency))
    }
    
    private func determineRecommendedAction(
        currentUsage: Double,
        predictedUsage: Double,
        deviceState: ProcessInfo.ThermalState,
        confidence: Double
    ) -> MemoryPrediction.RecommendedAction {
        // PHASE 2: Advanced action determination with device state consideration
        let thermalPenalty = deviceState == .critical ? 40.0 : (deviceState == .serious ? 20.0 : 0.0)
        let adjustedPrediction = predictedUsage + thermalPenalty
        
        if adjustedPrediction > 200.0 || currentUsage > 150.0 {
            return .suspendOperations
        } else if adjustedPrediction > 120.0 || (confidence > 0.7 && adjustedPrediction > 90.0) {
            return .aggressiveCleanup
        } else if adjustedPrediction > 80.0 || currentUsage > 70.0 {
            return .lightCleanup
        } else {
            return .none
        }
    }
    
    private func calculateTimeToAction(
        currentUsage: Double,
        trend: Double,
        action: MemoryPrediction.RecommendedAction
    ) -> TimeInterval {
        guard trend > 0.001 else { return 300.0 } // 5 minutes if no growth trend
        
        let threshold = switch action {
        case .suspendOperations: 180.0
        case .aggressiveCleanup: 100.0
        case .lightCleanup: 70.0
        case .none: 50.0
        }
        
        let timeToThreshold = (threshold - currentUsage) / trend
        return max(5.0, min(300.0, timeToThreshold)) // Between 5 seconds and 5 minutes
    }
}

/// PHASE 2: Pre-emptive cleanup manager that acts on memory predictions
class PreemptiveCleanupManager {
    private var lastCleanupTime = Date()
    private var cleanupHistory: [CleanupEvent] = []
    private let maxCleanupHistory = 20
    
    struct CleanupEvent {
        let timestamp: Date
        let type: CleanupType
        let memoryBefore: Double
        let memoryAfter: Double
        let success: Bool
        
        enum CleanupType {
            case light, aggressive, emergency
        }
    }
    
    func shouldPerformCleanup(prediction: MemoryPredictor.MemoryPrediction?) -> Bool {
        guard let prediction = prediction else { return false }
        
        let timeSinceLastCleanup = Date().timeIntervalSince(lastCleanupTime)
        let minimumInterval: TimeInterval = switch prediction.recommendedAction {
        case .suspendOperations: 0.0 // Immediate
        case .aggressiveCleanup: 5.0 // 5 seconds
        case .lightCleanup: 15.0 // 15 seconds
        case .none: 60.0 // 1 minute
        }
        
        return timeSinceLastCleanup >= minimumInterval
    }
}

/// PHASE 2: Memory usage analytics for performance insights
class MemoryAnalytics {
    private var metrics: [MemoryMetric] = []
    private let maxMetrics = 100
    
    struct MemoryMetric {
        let timestamp: Date
        let memoryUsageMB: Double
        let operation: String
        let duration: TimeInterval
        let success: Bool
    }
    
    struct MemoryReport {
        let averageMemoryUsage: Double
        let peakMemoryUsage: Double
        let memoryEfficiency: Double
        let operationSuccessRate: Double
        let recommendedOptimizations: [String]
    }
    
    func recordOperation(
        operation: String,
        memoryBefore: Double,
        memoryAfter: Double,
        duration: TimeInterval,
        success: Bool
    ) {
        let metric = MemoryMetric(
            timestamp: Date(),
            memoryUsageMB: memoryAfter,
            operation: operation,
            duration: duration,
            success: success
        )
        
        metrics.append(metric)
        
        if metrics.count > maxMetrics {
            metrics.removeFirst(metrics.count - maxMetrics)
        }
    }
    
    func getMemoryReport() -> MemoryReport {
        guard !metrics.isEmpty else {
            return MemoryReport(
                averageMemoryUsage: 0.0,
                peakMemoryUsage: 0.0,
                memoryEfficiency: 0.5,
                operationSuccessRate: 0.5,
                recommendedOptimizations: ["Insufficient data for analysis"]
            )
        }
        
        let averageUsage = metrics.reduce(0.0) { $0 + $1.memoryUsageMB } / Double(metrics.count)
        let peakUsage = metrics.map { $0.memoryUsageMB }.max() ?? 0.0
        let successRate = Double(metrics.filter { $0.success }.count) / Double(metrics.count)
        
        // Calculate memory efficiency
        let recentMetrics = Array(metrics.suffix(20))
        let efficiency = calculateMemoryEfficiency(recentMetrics)
        
        // Generate optimization recommendations
        let optimizations = generateOptimizationRecommendations(
            averageUsage: averageUsage,
            peakUsage: peakUsage,
            successRate: successRate,
            efficiency: efficiency
        )
        
        return MemoryReport(
            averageMemoryUsage: averageUsage,
            peakMemoryUsage: peakUsage,
            memoryEfficiency: efficiency,
            operationSuccessRate: successRate,
            recommendedOptimizations: optimizations
        )
    }
    
    private func calculateMemoryEfficiency(_ recentMetrics: [MemoryMetric]) -> Double {
        guard recentMetrics.count >= 2 else { return 0.5 }
        
        // Efficiency based on memory stability and operation success
        let memoryVariance = calculateMemoryVariance(recentMetrics)
        let successRate = Double(recentMetrics.filter { $0.success }.count) / Double(recentMetrics.count)
        let avgDuration = recentMetrics.reduce(0.0) { $0 + $1.duration } / Double(recentMetrics.count)
        
        let stabilityScore = max(0.0, 1.0 - (memoryVariance / 50.0)) // Normalize variance
        let performanceScore = min(1.0, max(0.0, 1.0 - (avgDuration / 1.0))) // 1 second = poor
        
        return (stabilityScore * 0.4 + successRate * 0.4 + performanceScore * 0.2)
    }
    
    private func calculateMemoryVariance(_ metrics: [MemoryMetric]) -> Double {
        let values = metrics.map { $0.memoryUsageMB }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    private func generateOptimizationRecommendations(
        averageUsage: Double,
        peakUsage: Double,
        successRate: Double,
        efficiency: Double
    ) -> [String] {
        var recommendations: [String] = []
        
        if averageUsage > 100.0 {
            recommendations.append("Consider reducing buffer sizes for high memory usage")
        }
        
        if peakUsage > 200.0 {
            recommendations.append("Implement more aggressive peak memory control")
        }
        
        if successRate < 0.8 {
            recommendations.append("Improve error handling and fallback mechanisms")
        }
        
        if efficiency < 0.6 {
            recommendations.append("Optimize operation duration and memory stability")
        }
        
        if recommendations.isEmpty {
            recommendations.append("Memory usage is optimized")
        }
        
        return recommendations
    }
}

// MARK: - INDUSTRY STANDARD: Incremental DTW Analyzer for Real-Time Processing

/// High-performance incremental DTW analyzer that yields to UI thread
actor IncrementalDTWAnalyzer {
    
    /// INDUSTRY STANDARD: Analyze stroke with UI-friendly yield points
    static func analyze(_ stroke: DrawingStroke, against guide: DrawingGuide) async -> StrokeFeedback {
        
        // REAL-TIME: Early exit for simple cases
        if stroke.points.count < 10 {
            return await quickGeometricAnalysis(stroke, against: guide)
        }
        
        // INDUSTRY STANDARD: Break large analysis into chunks
        let chunkSize = calculateOptimalChunkSize(for: stroke.points.count)
        let chunks = stroke.points.chunked(into: chunkSize)
        
        var accumulatedDistance = 0.0
        var accumulatedAlignment: [(Int, Int)] = []
        var processedPoints = 0
        
        // REAL-TIME: Process each chunk with yield points
        for (chunkIndex, chunk) in chunks.enumerated() {
            // INDUSTRY STANDARD: Yield every 3 chunks to maintain 60fps
            if chunkIndex % 3 == 0 {
                await Task.yield()
            }
            
            // REAL-TIME: Check for cancellation
            if Task.isCancelled {
                return createFallbackFeedback(for: stroke, accuracy: 0.5)
            }
            
            // INDUSTRY STANDARD: Incremental DTW on chunk
            let chunkResult = await processChunkWithFastDTW(
                Array(chunk), 
                referenceSegment: extractReferenceSegment(guide, for: processedPoints, chunkSize: chunkSize)
            )
            
            // REAL-TIME: Accumulate results
            accumulatedDistance += chunkResult.distance
            let adjustedAlignment = chunkResult.alignment.map { (i, j) in
                (i + processedPoints, j + processedPoints)
            }
            accumulatedAlignment.append(contentsOf: adjustedAlignment)
            
            processedPoints += chunk.count
        }
        
        // INDUSTRY STANDARD: Normalize results
        let normalizedDistance = accumulatedDistance / Double(chunks.count)
        let accuracy = max(0.0, 1.0 - normalizedDistance)
        
        // REAL-TIME: Create feedback without blocking
        return await createEnhancedFeedback(
            stroke: stroke,
            guide: guide,
            distance: normalizedDistance,
            accuracy: accuracy,
            alignment: accumulatedAlignment
        )
    }
    
    // INDUSTRY STANDARD: Calculate optimal chunk size for device performance
    private static func calculateOptimalChunkSize(for pointCount: Int) -> Int {
        let devicePerformance = ProcessInfo.processInfo.processorCount
        
        // REAL-TIME: Adaptive chunk sizing
        if devicePerformance >= 6 {
            return min(50, pointCount / 10) // High-end devices: larger chunks
        } else if devicePerformance >= 4 {
            return min(30, pointCount / 15) // Mid-range devices: medium chunks
        } else {
            return min(20, pointCount / 20) // Low-end devices: smaller chunks
        }
    }
    
    // INDUSTRY STANDARD: Fast DTW processing for chunks
    private static func processChunkWithFastDTW(_ chunk: [CGPoint], referenceSegment: [CGPoint]) async -> (distance: Double, alignment: [(Int, Int)]) {
        
        // REAL-TIME: Use simplified DTW for small chunks
        if chunk.count <= 10 || referenceSegment.count <= 10 {
            return await simpleEuclideanAlignment(chunk, referenceSegment)
        }
        
        // INDUSTRY STANDARD: Apply unified Core ML analysis
        return await Task.detached(priority: .userInitiated) {
            // Use unified analyzer for chunk analysis
            let unifiedAnalyzer = await UnifiedStrokeAnalyzer()
            let chunkStroke = DrawingStroke(points: chunk, timestamp: Date(), pressure: [], velocity: [])
            
            // Create a simple guide shape for chunk analysis
            let guideShape = GuideShape(
                type: .line,
                points: referenceSegment,
                center: CGPoint(x: referenceSegment.map { $0.x }.reduce(0, +) / CGFloat(referenceSegment.count),
                               y: referenceSegment.map { $0.y }.reduce(0, +) / CGFloat(referenceSegment.count)),
                dimensions: CGSize(width: 100, height: 100),
                rotation: 0,
                strokeWidth: 2,
                color: .blue,
                style: .solid
            )
            
            let guide = DrawingGuide(
                stepNumber: 1,
                instruction: "Chunk analysis",
                shapes: [guideShape],
                targetPoints: referenceSegment,
                tolerance: 20,
                category: .objects
            )
            
            let feedback = await unifiedAnalyzer.analyzeStroke(chunkStroke, against: guide)
            // Convert StrokeFeedback to expected return type
            return (distance: 1.0 - feedback.accuracy, alignment: [])
        }.value
    }
    
    // REAL-TIME: Quick geometric analysis for simple cases
    private static func quickGeometricAnalysis(_ stroke: DrawingStroke, against guide: DrawingGuide) async -> StrokeFeedback {
        return await Task.detached(priority: .userInitiated) {
            let unifiedAnalyzer = await UnifiedStrokeAnalyzer()
            return await unifiedAnalyzer.analyzeStroke(stroke, against: guide)
        }.value
    }
    
    // INDUSTRY STANDARD: Extract relevant reference segment for chunk
    private static func extractReferenceSegment(_ guide: DrawingGuide, for startIndex: Int, chunkSize: Int) -> [CGPoint] {
        guard let primaryPath = guide.shapes.first else { return [] }
        let referencePoints = primaryPath.points
        
        // REAL-TIME: Map stroke position to reference position
        let totalStrokePoints = guide.targetPoints.count
        let referenceRatio = Double(referencePoints.count) / Double(totalStrokePoints)
        
        let refStartIndex = Int(Double(startIndex) * referenceRatio)
        let refEndIndex = min(referencePoints.count, Int(Double(startIndex + chunkSize) * referenceRatio))
        
        return Array(referencePoints[refStartIndex..<refEndIndex])
    }
    
    // REAL-TIME: Simple alignment for small chunks
    private static func simpleEuclideanAlignment(_ chunk: [CGPoint], _ reference: [CGPoint]) async -> (distance: Double, alignment: [(Int, Int)]) {
        var totalDistance = 0.0
        var alignment: [(Int, Int)] = []
        
        let maxLen = max(chunk.count, reference.count)
        
        for i in 0..<maxLen {
            let chunkIndex = min(i * chunk.count / maxLen, chunk.count - 1)
            let refIndex = min(i * reference.count / maxLen, reference.count - 1)
            
            let distance = euclideanDistance(chunk[chunkIndex], reference[refIndex])
            totalDistance += distance
            alignment.append((chunkIndex, refIndex))
        }
        
        return (distance: totalDistance / Double(maxLen), alignment: alignment)
    }
    
    // INDUSTRY STANDARD: Create enhanced feedback asynchronously
    private static func createEnhancedFeedback(
        stroke: DrawingStroke,
        guide: DrawingGuide,
        distance: Double,
        accuracy: Double,
        alignment: [(Int, Int)]
    ) async -> StrokeFeedback {
        
        // REAL-TIME: Calculate additional metrics in background
        let temporalAccuracy = await calculateTemporalAccuracy(stroke, alignment: alignment)
        let velocityConsistency = await calculateVelocityConsistency(stroke, alignment: alignment)
        
        return StrokeFeedback(
            accuracy: accuracy,
            suggestions: generateSuggestions(for: accuracy),
            correctionPoints: [],
            isCorrect: accuracy >= 0.7,
            dtwDistance: distance,
            temporalAccuracy: temporalAccuracy,
            velocityConsistency: velocityConsistency,
            spatialAlignment: alignment,
            confidenceScore: accuracy
        )
    }
    
    // REAL-TIME: Fallback feedback for cancelled operations
    private static func createFallbackFeedback(for stroke: DrawingStroke, accuracy: Double) -> StrokeFeedback {
        return StrokeFeedback(
            accuracy: accuracy,
            suggestions: ["Analysis interrupted - try again"],
            correctionPoints: [],
            isCorrect: false
        )
    }
    
    // HELPER: Calculate temporal accuracy asynchronously
    private static func calculateTemporalAccuracy(_ stroke: DrawingStroke, alignment: [(Int, Int)]) async -> Double {
        guard !alignment.isEmpty else { return 0.0 }
        
        // Simplified temporal analysis for real-time performance
        let velocityVariance = stroke.velocity.isEmpty ? 0.5 : 
            stroke.velocity.reduce(0.0) { result, velocity in
                return result + abs(Double(velocity) - 1.0)
            } / Double(stroke.velocity.count)
        
        return max(0.0, 1.0 - velocityVariance)
    }
    
    // HELPER: Calculate velocity consistency asynchronously
    private static func calculateVelocityConsistency(_ stroke: DrawingStroke, alignment: [(Int, Int)]) async -> Double {
        guard stroke.velocity.count > 1 else { return 0.8 }
        
        // Simplified consistency analysis
        let velocitySum = stroke.velocity.reduce(0.0) { result, velocity in
            return result + Float(velocity)
        }
        let avgVelocity = velocitySum / Float(stroke.velocity.count)
        
        // Break down complex expression to avoid compiler timeout
        let varianceSum = stroke.velocity.reduce(0.0) { result, velocity in
            let diff = Double(Float(velocity) - avgVelocity)
            return result + (diff * diff)
        }
        let variance = varianceSum / Double(stroke.velocity.count)
        
        return max(0.0, 1.0 - sqrt(variance))
    }
    
    // HELPER: Generate suggestions based on accuracy
    private static func generateSuggestions(for accuracy: Double) -> [String] {
        if accuracy >= 0.9 {
            return ["Excellent! Your stroke is very accurate."]
        } else if accuracy >= 0.7 {
            return ["Good stroke! Try to follow the guide more closely."]
        } else if accuracy >= 0.5 {
            return ["Keep practicing! Focus on staying within the guide."]
        } else {
            return ["Try drawing more slowly and carefully."]
        }
    }
    
    // HELPER: Euclidean distance calculation
    private static func euclideanDistance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = Double(p1.x - p2.x)
        let dy = Double(p1.y - p2.y)
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Array Extension for Chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}