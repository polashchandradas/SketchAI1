import SwiftUI
import PencilKit
import UIKit

// MARK: - PencilKit Canvas UIViewRepresentable
struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let coordinator: DrawingCanvasCoordinator
    let drawingEngine: DrawingAlgorithmEngine
    let stepProgressionManager: StepProgressionManager
    let lesson: Lesson
    let showGuides: Bool
    let guideOpacity: Double
    let showToolPicker: Bool
    
    // Callbacks
    let onDrawingChanged: (PKDrawing) -> Void
    let onStepCompleted: (Int) -> Void
    let onLessonCompleted: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        // Configure canvas
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = UIColor.clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        
        // Set up tool picker if enabled
        if showToolPicker {
            setupToolPicker(for: canvasView, in: context)
        }
        
        // Configure initial tool
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2.0)
        
        // Setup video recording optimization
        setupVideoRecordingOptimization(for: canvasView)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // MEMORY OPTIMIZATION: Only update guides if step actually changed
        let currentStepIndex = stepProgressionManager.currentStepIndex
        if context.coordinator.lastUpdatedStep != currentStepIndex {
            context.coordinator.lastUpdatedStep = currentStepIndex
            
            // Update guide overlay using step progression manager's current step
            context.coordinator.updateGuides(
                showGuides: showGuides,
                opacity: guideOpacity,
                lesson: lesson,
                currentStep: currentStepIndex
            )
        }
        
        // Update tool picker visibility
        if let toolPicker = context.coordinator.toolPicker {
            toolPicker.setVisible(showToolPicker, forFirstResponder: uiView)
        }
    }
    
    func makeCoordinator() -> PencilKitCoordinator {
        PencilKitCoordinator(
            parent: self,
            drawingCoordinator: coordinator,
            drawingEngine: drawingEngine,
            stepProgressionManager: stepProgressionManager,
            onDrawingChanged: onDrawingChanged,
            onStepCompleted: onStepCompleted,
            onLessonCompleted: onLessonCompleted
        )
    }
    
    private func setupToolPicker(for canvasView: PKCanvasView, in context: Context) {
        // OFFICIAL APPLE PATTERN: Create individual instances (iOS 14+)
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(showToolPicker, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        
        // OFFICIAL APPLE RECOMMENDATION: Set drawing policy
        canvasView.drawingPolicy = .anyInput
        
        context.coordinator.toolPicker = toolPicker
        
        if showToolPicker {
            canvasView.becomeFirstResponder()
        }
    }
    
    // MARK: - Video Recording Optimization
    
    private func setupVideoRecordingOptimization(for canvasView: PKCanvasView) {
        // Optimize canvas for video recording
        canvasView.layer.drawsAsynchronously = true
        canvasView.layer.shouldRasterize = false // Better for dynamic content
        
        // Enable efficient compositing
        canvasView.layer.allowsEdgeAntialiasing = true
        canvasView.layer.allowsGroupOpacity = true
        
        // Set content scale factor for high-quality capture
        canvasView.contentScaleFactor = UIScreen.main.scale
    }
}

// MARK: - PencilKit Coordinator
class PencilKitCoordinator: NSObject, PKCanvasViewDelegate {
    let parent: PencilKitCanvasView
    let drawingCoordinator: DrawingCanvasCoordinator
    let drawingEngine: DrawingAlgorithmEngine
    let stepProgressionManager: StepProgressionManager
    
    // Callbacks
    let onDrawingChanged: (PKDrawing) -> Void
    let onStepCompleted: (Int) -> Void
    let onLessonCompleted: () -> Void
    
    // UI State
    var toolPicker: PKToolPicker?
    var guideLayer: CAShapeLayer?
    var lastUpdatedStep: Int = -1 // MEMORY OPTIMIZATION: Track last updated step to prevent redundant updates
    
    // Analysis state
    private var lastAnalysisTime = Date()
    private let analysisThrottle: TimeInterval = 0.2 // CRITICAL FIX: Increased to 200ms to reduce excessive event dispatching
    
    init(
        parent: PencilKitCanvasView,
        drawingCoordinator: DrawingCanvasCoordinator,
        drawingEngine: DrawingAlgorithmEngine,
        stepProgressionManager: StepProgressionManager,
        onDrawingChanged: @escaping (PKDrawing) -> Void,
        onStepCompleted: @escaping (Int) -> Void,
        onLessonCompleted: @escaping () -> Void
    ) {
        self.parent = parent
        self.drawingCoordinator = drawingCoordinator
        self.drawingEngine = drawingEngine
        self.stepProgressionManager = stepProgressionManager
        self.onDrawingChanged = onDrawingChanged
        self.onStepCompleted = onStepCompleted
        self.onLessonCompleted = onLessonCompleted
        super.init()
    }
    
    // MARK: - PKCanvasViewDelegate
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("🎨 [TUTORIAL] Drawing changed - Stroke count: \(canvasView.drawing.strokes.count)")
        
        // Throttle analysis to prevent performance issues
        let now = Date()
        guard now.timeIntervalSince(lastAnalysisTime) >= analysisThrottle else { 
            print("⏱️ [TUTORIAL] Analysis throttled - too frequent")
            return 
        }
        lastAnalysisTime = now
        
        print("✅ [TUTORIAL] Analysis allowed - proceeding with tutorial features")
        
        // Notify parent of drawing change
        onDrawingChanged(canvasView.drawing)
        
        // Perform real-time stroke analysis
        performRealTimeStrokeAnalysis(canvasView.drawing)
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        print("🖊️ [TUTORIAL] User began drawing - tool: \(canvasView.tool)")
        // Start stroke tracking
        drawingCoordinator.clearStrokeBuffer()
        print("🧹 [TUTORIAL] Stroke buffer cleared for new drawing session")
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        print("✋ [TUTORIAL] User finished drawing stroke")
        // Complete stroke analysis
        if let lastStroke = canvasView.drawing.strokes.last {
            print("📊 [TUTORIAL] Analyzing completed stroke with \(lastStroke.path.count) points")
            Task {
                await drawingCoordinator.analyzeCompletedStroke(lastStroke)
                print("✅ [TUTORIAL] Stroke analysis completed")
            }
        } else {
            print("⚠️ [TUTORIAL] No stroke found to analyze")
        }
    }
    
    // MARK: - Real-time Analysis
    
    private func performRealTimeStrokeAnalysis(_ drawing: PKDrawing) {
        guard !drawing.strokes.isEmpty else { 
            print("⚠️ [TUTORIAL] No strokes to analyze")
            return 
        }
        
        print("🔍 [TUTORIAL] Starting real-time stroke analysis")
        
        // CRITICAL FIX: Add additional throttling to prevent excessive analysis
        let now = Date()
        guard now.timeIntervalSince(lastAnalysisTime) >= analysisThrottle else { 
            print("⏱️ [TUTORIAL] Real-time analysis throttled")
            return 
        }
        lastAnalysisTime = now
        
        // Get current guide
        guard let currentGuide = drawingEngine.getCurrentGuide() else { 
            print("❌ [TUTORIAL] No current guide available for analysis")
            return 
        }
        
        print("📋 [TUTORIAL] Current guide found: \(currentGuide.instruction)")
        
        // CRITICAL FIX: Only analyze if stroke has enough points to be meaningful
        if let latestStroke = drawing.strokes.last, latestStroke.path.count >= 5 {
            print("✅ [TUTORIAL] Stroke has sufficient points (\(latestStroke.path.count)) for analysis")
            
            let points = latestStroke.path.map { $0.location }
            let pressures = latestStroke.path.map { $0.force }
            let velocities = calculateVelocities(from: latestStroke.path)
            
            let drawingStroke = DrawingStroke(
                points: points,
                timestamp: Date(),
                pressure: pressures,
                velocity: velocities
            )
            
            print("📊 [TUTORIAL] Created DrawingStroke with \(points.count) points")
            
            // CRITICAL FIX: Perform analysis on background queue to prevent UI blocking
            Task.detached(priority: .userInitiated) {
                print("🔄 [TUTORIAL] Starting background stroke analysis")
                let feedback = await UnifiedStrokeAnalyzer().analyzeStroke(drawingStroke, against: currentGuide)
                print("📈 [TUTORIAL] Analysis result - Accuracy: \(feedback.accuracy), Correct: \(feedback.isCorrect)")
                
                // CRITICAL FIX: Update coordinator state on main thread
                await MainActor.run {
                    self.drawingCoordinator.strokeFeedback = feedback
                    self.drawingCoordinator.currentAccuracy = feedback.accuracy
                    print("✅ [TUTORIAL] Updated coordinator with feedback")
                    
                    // CRITICAL FIX: Notify step progression manager
                    self.stepProgressionManager.evaluateStrokeForCurrentStep(feedback)
                    print("🎯 [TUTORIAL] Notified step progression manager")
                    
                    // Check for step completion
                    if feedback.isCorrect && feedback.accuracy > 0.8 {
                        print("🎉 [TUTORIAL] Step completion criteria met - checking completion")
                        self.checkStepCompletion()
                    } else {
                        print("📝 [TUTORIAL] Step not yet complete - accuracy: \(feedback.accuracy)")
                    }
                }
            }
        } else {
            print("⚠️ [TUTORIAL] Stroke has insufficient points for analysis (\(drawing.strokes.last?.path.count ?? 0))")
        }
    }
    
    private func checkStepCompletion() {
        let currentStepIndex = stepProgressionManager.currentStepIndex
        print("🔍 [TUTORIAL] Checking step completion - Current step: \(currentStepIndex)")
        
        // Check if current step is complete using step progression manager
        if stepProgressionManager.canProgressToNext {
            print("🎉 [TUTORIAL] Step \(currentStepIndex) is complete!")
            onStepCompleted(currentStepIndex)
            
            // Check if lesson is complete
            if currentStepIndex >= parent.lesson.steps.count - 1 {
                print("🏆 [TUTORIAL] Lesson completed! All steps finished.")
                onLessonCompleted()
            } else {
                // Advance to next step using step progression manager
                if stepProgressionManager.progressToNextStep() {
                    print("➡️ [TUTORIAL] Advancing to step \(stepProgressionManager.currentStepIndex)")
                    drawingEngine.nextStep()
                    print("✅ [TUTORIAL] Next step loaded")
                } else {
                    print("⚠️ [TUTORIAL] Failed to progress to next step")
                }
            }
        } else {
            print("📝 [TUTORIAL] Step \(currentStepIndex) not yet complete")
        }
    }
    
    // MARK: - Guide Management
    
    func updateGuides(showGuides: Bool, opacity: Double, lesson: Lesson, currentStep: Int) {
        let currentStepIndex = stepProgressionManager.currentStepIndex
        print("📐 [TUTORIAL] Updating guides - Show: \(showGuides), Step: \(currentStepIndex), Opacity: \(opacity)")
        
        // MEMORY OPTIMIZATION: Use autorelease pool for layer operations
        autoreleasepool {
            // Remove existing guide layer
            guideLayer?.removeFromSuperlayer()
            guideLayer = nil // Explicitly set to nil to help with memory cleanup
            
            guard showGuides, currentStepIndex < lesson.steps.count else { 
                print("⚠️ [TUTORIAL] Guides disabled or invalid step")
                return 
            }
            
            let step = lesson.steps[currentStepIndex]
            print("📋 [TUTORIAL] Creating guide for step: \(step.shapeType)")
            let layer = createGuideLayer(for: step, opacity: opacity)
            
            parent.canvasView.layer.insertSublayer(layer, at: 0)
            guideLayer = layer
            print("✅ [TUTORIAL] Guide layer added to canvas")
        }
    }
    
    private func createGuideLayer(for step: LessonStep, opacity: Double) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = createGuidePath(for: step)
        
        layer.path = path.cgPath
        layer.strokeColor = UIColor.systemBlue.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 2.0
        layer.lineDashPattern = [8, 4]
        layer.opacity = Float(opacity)
        
        // Add subtle animation
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = 12
        animation.duration = 1.0
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "dash")
        
        return layer
    }
    
    private func createGuidePath(for step: LessonStep) -> UIBezierPath {
        let bounds = parent.canvasView.bounds
        let centerX = bounds.midX
        let centerY = bounds.midY
        let path = UIBezierPath()
        
        switch step.shapeType {
        case .circle:
            let radius: CGFloat = 60
            path.addArc(withCenter: CGPoint(x: centerX, y: centerY), 
                       radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            
        case .oval:
            let rect = CGRect(x: centerX - 70, y: centerY - 45, width: 140, height: 90)
            path.append(UIBezierPath(ovalIn: rect))
            
        case .rectangle:
            let rect = CGRect(x: centerX - 60, y: centerY - 40, width: 120, height: 80)
            path.append(UIBezierPath(rect: rect))
            
        case .line:
            path.move(to: CGPoint(x: centerX - 80, y: centerY))
            path.addLine(to: CGPoint(x: centerX + 80, y: centerY))
            
        case .curve:
            path.move(to: CGPoint(x: centerX - 70, y: centerY + 30))
            path.addQuadCurve(to: CGPoint(x: centerX + 70, y: centerY + 30),
                            controlPoint: CGPoint(x: centerX, y: centerY - 50))
            
        case .polygon:
            // Triangle
            path.move(to: CGPoint(x: centerX, y: centerY - 50))
            path.addLine(to: CGPoint(x: centerX - 45, y: centerY + 25))
            path.addLine(to: CGPoint(x: centerX + 45, y: centerY + 25))
            path.close()
        }
        
        return path
    }
    
    // MARK: - Helper Methods
    
    private func calculateVelocities(from path: PKStrokePath) -> [CGFloat] {
        var velocities: [CGFloat] = []
        
        for i in 1..<path.count {
            let timeDelta = path[i].timeOffset - path[i-1].timeOffset
            let distance = sqrt(
                pow(path[i].location.x - path[i-1].location.x, 2) +
                pow(path[i].location.y - path[i-1].location.y, 2)
            )
            let velocity = timeDelta > 0 ? distance / CGFloat(timeDelta) : 0
            velocities.append(velocity)
        }
        
        if !velocities.isEmpty {
            velocities.insert(velocities.first!, at: 0)
        }
        
        return velocities
    }
}
