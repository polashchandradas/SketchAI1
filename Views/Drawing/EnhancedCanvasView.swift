import SwiftUI
import PencilKit
import Combine
import UIKit

// MARK: - Enhanced Canvas View with Real-time Feedback
struct EnhancedCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @ObservedObject var coordinator: DrawingCanvasCoordinator
    @ObservedObject var drawingEngine: DrawingAlgorithmEngine
    
    let lesson: Lesson
    let showGuides: Bool
    let guideOpacity: Double
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = UIColor.systemBackground
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        
        // Setup real-time stroke detection
        setupStrokeDetection(canvasView, coordinator: context.coordinator)
        
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update guide visibility and opacity
        context.coordinator.updateGuideVisibility(showGuides, opacity: guideOpacity)
    }
    
    func makeCoordinator() -> EnhancedCanvasCoordinator {
        EnhancedCanvasCoordinator(
            self,
            drawingCoordinator: coordinator,
            drawingEngine: drawingEngine
        )
    }
    
    private func setupStrokeDetection(_ canvasView: PKCanvasView, coordinator: EnhancedCanvasCoordinator) {
        // Add real-time drawing observation
        NotificationCenter.default.addObserver(
            forName: .PKCanvasViewDidBeginUsingTool,
            object: canvasView,
            queue: .main
        ) { _ in
            coordinator.didBeginDrawing()
        }
        
        NotificationCenter.default.addObserver(
            forName: .PKCanvasViewDidEndUsingTool,
            object: canvasView,
            queue: .main
        ) { _ in
            coordinator.didEndDrawing()
        }
    }
}

// MARK: - Enhanced Canvas Coordinator
class EnhancedCanvasCoordinator: NSObject, PKCanvasViewDelegate {
    let parent: EnhancedCanvasView
    let drawingCoordinator: DrawingCanvasCoordinator
    let drawingEngine: DrawingAlgorithmEngine
    
    // Real-time tracking
    private var isDrawing = false
    private var currentStrokePoints: [CGPoint] = []
    private var currentStrokePressure: [CGFloat] = []
    private var currentStrokeVelocity: [CGFloat] = []
    private var lastPointTime = Date()
    
    // Visual feedback layers
    private var guideLayer: CAShapeLayer?
    private var feedbackLayer: CAShapeLayer?
    private var progressLayer: CAShapeLayer?
    
    // Performance optimization
    private let updateThrottle: TimeInterval = 0.016 // 60 FPS
    private var lastUpdateTime = Date()
    
    init(_ parent: EnhancedCanvasView, drawingCoordinator: DrawingCanvasCoordinator, drawingEngine: DrawingAlgorithmEngine) {
        self.parent = parent
        self.drawingCoordinator = drawingCoordinator
        self.drawingEngine = drawingEngine
        super.init()
        
        setupLayerObservation()
    }
    
    // MARK: - PKCanvasViewDelegate
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Handle completed stroke
        guard !canvasView.drawing.strokes.isEmpty else { return }
        
        let latestStroke = canvasView.drawing.strokes.last!
        Task {
            await drawingCoordinator.analyzeCompletedStroke(latestStroke)
        }
        
        // Update visual feedback
        updateFeedbackLayer(canvasView)
    }
    
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        didBeginDrawing()
    }
    
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
        didEndDrawing()
    }
    
    // MARK: - Real-time Drawing Detection
    func didBeginDrawing() {
        isDrawing = true
        currentStrokePoints.removeAll()
        currentStrokePressure.removeAll()
        currentStrokeVelocity.removeAll()
        lastPointTime = Date()
        
        startRealTimeTracking()
    }
    
    func didEndDrawing() {
        isDrawing = false
        stopRealTimeTracking()
        
        // Clear current stroke data
        currentStrokePoints.removeAll()
        currentStrokePressure.removeAll()
        currentStrokeVelocity.removeAll()
    }
    
    private func startRealTimeTracking() {
        // Start monitoring touch events for real-time feedback
        Timer.scheduledTimer(withTimeInterval: updateThrottle, repeats: true) { [weak self] timer in
            guard let self = self, self.isDrawing else {
                timer.invalidate()
                return
            }
            
            self.captureCurrentStrokeData()
        }
    }
    
    private func stopRealTimeTracking() {
        // Real-time tracking will stop when isDrawing becomes false
    }
    
    private func captureCurrentStrokeData() {
        // In a real implementation, you would capture actual touch data
        // For this demo, we'll simulate stroke progression
        guard let canvasView = parent.canvasView as PKCanvasView? else { return }
        
        // Throttle updates for performance
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) >= updateThrottle else { return }
        lastUpdateTime = now
        
        // Extract current stroke data if available
        if let currentStroke = canvasView.drawing.strokes.last {
            let points = currentStroke.path.map { $0.location }
            let pressure = currentStroke.path.map { $0.force }
            let velocity = calculateVelocities(from: currentStroke.path)
            
            // Update real-time analysis
            Task {
                await drawingCoordinator.analyzeStrokeInProgress(points, pressure: pressure, velocity: velocity)
            }
        }
    }
    
    private func calculateVelocities(from strokePath: PKStrokePath) -> [CGFloat] {
        let points = Array(strokePath)
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
            velocities.insert(velocities.first!, at: 0)
        }
        
        return velocities
    }
    
    // MARK: - Visual Layer Management
    private func setupLayerObservation() {
        // Observe drawing coordinator changes for visual updates
        drawingCoordinator.$showVisualFeedback
            .sink { [weak self] showFeedback in
                self?.updateFeedbackVisibility(showFeedback)
            }
            .store(in: &cancellables)
        
        drawingCoordinator.$stepProgress
            .sink { [weak self] progress in
                self?.updateProgressIndicator(progress)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func updateGuideVisibility(_ visible: Bool, opacity: Double) {
        guard let canvasView = parent.canvasView as PKCanvasView? else { return }
        
        // Remove existing guide layer
        guideLayer?.removeFromSuperlayer()
        
        guard visible, let currentGuide = drawingEngine.getCurrentGuide() else { return }
        
        // Create new guide layer
        let layer = createGuideLayer(for: currentGuide, opacity: opacity)
        canvasView.layer.addSublayer(layer)
        guideLayer = layer
    }
    
    private func createGuideLayer(for guide: DrawingGuide, opacity: Double) -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        // Create combined path for all guide shapes
        let combinedPath = UIBezierPath()
        
        for shape in guide.shapes {
            let shapePath = createBezierPath(for: shape)
            combinedPath.append(shapePath)
        }
        
        layer.path = combinedPath.cgPath
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
        layer.add(animation, forKey: "dashAnimation")
        
        return layer
    }
    
    private func createBezierPath(for shape: GuideShape) -> UIBezierPath {
        let path = UIBezierPath()
        
        switch shape.type {
        case .circle:
            let radius = shape.dimensions.width / 2
            path.addArc(
                withCenter: shape.center,
                radius: radius,
                startAngle: 0,
                endAngle: .pi * 2,
                clockwise: true
            )
            
        case .oval:
            let rect = CGRect(
                x: shape.center.x - shape.dimensions.width / 2,
                y: shape.center.y - shape.dimensions.height / 2,
                width: shape.dimensions.width,
                height: shape.dimensions.height
            )
            path.append(UIBezierPath(ovalIn: rect))
            
        case .rectangle:
            let rect = CGRect(
                x: shape.center.x - shape.dimensions.width / 2,
                y: shape.center.y - shape.dimensions.height / 2,
                width: shape.dimensions.width,
                height: shape.dimensions.height
            )
            path.append(UIBezierPath(rect: rect))
            
        case .line:
            if shape.points.count >= 2 {
                path.move(to: shape.points[0])
                path.addLine(to: shape.points[1])
            }
            
        case .curve:
            if shape.points.count >= 3 {
                path.move(to: shape.points[0])
                path.addQuadCurve(to: shape.points[2], controlPoint: shape.points[1])
            }
            
        case .polygon:
            if !shape.points.isEmpty {
                path.move(to: shape.points[0])
                for point in shape.points.dropFirst() {
                    path.addLine(to: point)
                }
                path.close()
            }
        }
        
        return path
    }
    
    private func updateFeedbackLayer(_ canvasView: PKCanvasView) {
        // Update feedback visualization based on current stroke analysis
        guard let feedback = drawingCoordinator.strokeFeedback else { return }
        
        // Remove existing feedback layer
        feedbackLayer?.removeFromSuperlayer()
        
        // Create feedback layer if corrections are needed
        if !feedback.isCorrect && !feedback.correctionPoints.isEmpty {
            let layer = createFeedbackLayer(for: feedback.correctionPoints)
            canvasView.layer.addSublayer(layer)
            feedbackLayer = layer
        }
    }
    
    private func createFeedbackLayer(for correctionPoints: [CGPoint]) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        
        for point in correctionPoints {
            let circleRect = CGRect(x: point.x - 8, y: point.y - 8, width: 16, height: 16)
            path.append(UIBezierPath(ovalIn: circleRect))
        }
        
        layer.path = path.cgPath
        layer.strokeColor = UIColor.systemRed.cgColor
        layer.fillColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        layer.lineWidth = 2.0
        
        // Add pulsing animation
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.0
        animation.toValue = 1.2
        animation.duration = 0.8
        animation.repeatCount = .infinity
        animation.autoreverses = true
        layer.add(animation, forKey: "pulseAnimation")
        
        return layer
    }
    
    private func updateFeedbackVisibility(_ visible: Bool) {
        feedbackLayer?.isHidden = !visible
    }
    
    private func updateProgressIndicator(_ progress: Double) {
        // Update progress visualization
        progressLayer?.removeFromSuperlayer()
        
        guard let canvasView = parent.canvasView as PKCanvasView? else { return }
        
        let layer = createProgressLayer(progress: progress, canvasSize: canvasView.bounds.size)
        canvasView.layer.addSublayer(layer)
        progressLayer = layer
    }
    
    private func createProgressLayer(progress: Double, canvasSize: CGSize) -> CAShapeLayer {
        let layer = CAShapeLayer()
        
        // Create progress arc in top-right corner
        let center = CGPoint(x: canvasSize.width - 40, y: 40)
        let radius: CGFloat = 20
        
        let progressPath = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: -.pi / 2 + CGFloat(progress * 2 * .pi),
            clockwise: true
        )
        
        layer.path = progressPath.cgPath
        layer.strokeColor = UIColor.systemGreen.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 4.0
        layer.lineCap = .round
        
        return layer
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.forEach { $0.cancel() }
        guideLayer?.removeFromSuperlayer()
        feedbackLayer?.removeFromSuperlayer()
        progressLayer?.removeFromSuperlayer()
    }
}

// MARK: - Supporting Extensions
extension Notification.Name {
    static let PKCanvasViewDidBeginUsingTool = Notification.Name("PKCanvasViewDidBeginUsingTool")
    static let PKCanvasViewDidEndUsingTool = Notification.Name("PKCanvasViewDidEndUsingTool")
}

#Preview {
    struct PreviewWrapper: View {
        @State private var canvasView = PKCanvasView()
        @StateObject private var drawingEngine = DrawingAlgorithmEngine()
        @StateObject private var coordinator: DrawingCanvasCoordinator
        
        init() {
            let engine = DrawingAlgorithmEngine()
            self._coordinator = StateObject(wrappedValue: DrawingCanvasCoordinator(drawingEngine: engine))
        }
        
        var body: some View {
            EnhancedCanvasView(
                canvasView: $canvasView,
                coordinator: coordinator,
                drawingEngine: drawingEngine,
                lesson: LessonData.sampleLessons[0],
                showGuides: true,
                guideOpacity: 0.7
            )
        }
    }
    
    return PreviewWrapper()
}

