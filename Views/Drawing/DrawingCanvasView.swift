import SwiftUI
import PencilKit
import Combine
import Vision
import UIKit
import PhotosUI

struct DrawingCanvasView: View {
    let lesson: Lesson
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var lessonService: LessonService
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvasView = PKCanvasView()
    @State private var isDrawing = false
    @State private var showGuides = true
    @State private var guideOpacity: Double = 0.7
    @State private var selectedTool: DrawingTool = .pencil
    @State private var showExportOptions = false
    @State private var showStepInstructions = true
    @State private var drawingStartTime = Date()
    
    // CRITICAL FEATURE ADDITIONS
    @State private var showPhotoImporter = false
    @State private var importedPhoto: UIImage?
    @State private var showRealTimeFeedback = true
    @State private var isAnalyzing = false
    @State private var showToolPicker = true
    @State private var canvasSize: CGSize = .zero
    @State private var lessonCompleted = false
    @State private var showCompletionSheet = false
    
    // Enhanced AI Drawing Integration
    @StateObject private var drawingEngine = DrawingAlgorithmEngine()
    @StateObject private var drawingCoordinator: DrawingCanvasCoordinator
    @StateObject private var stepProgressionManager: StepProgressionManager
    
    // Video Recording Integration
    @StateObject private var videoRecordingEngine = OptimizedVideoRecordingEngine()
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var recordedVideoURL: URL?
    
    // Visual Feedback States
    @State private var showVisualFeedback = false
    @State private var showCelebration = false
    @State private var currentAccuracy: Double = 0.0
    
    init(lesson: Lesson) {
        self.lesson = lesson
        // Use the same engine instance that will be created by @StateObject
        let engine = DrawingAlgorithmEngine()
        self._drawingEngine = StateObject(wrappedValue: engine)
        self._drawingCoordinator = StateObject(wrappedValue: DrawingCanvasCoordinator(drawingEngine: engine))
        self._stepProgressionManager = StateObject(wrappedValue: StepProgressionManager(lesson: lesson, drawingEngine: engine))
    }
    
    var currentLessonStep: LessonStep? {
        guard stepProgressionManager.currentStepIndex < lesson.steps.count else { return nil }
        return lesson.steps[stepProgressionManager.currentStepIndex]
    }
    
    var currentDrawingGuide: DrawingGuide? {
        return drawingEngine.getCurrentGuide()
    }
    
    var isLastStep: Bool {
        stepProgressionManager.currentStepIndex >= lesson.steps.count - 1
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Simplified Canvas Area - Following iOS 18 best practices
                    ZStack {
                        // Background imported photo (if any) - Visible for tracing
                        if let photo = importedPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .opacity(0.4) // Increased opacity for better visibility while tracing
                                .clipped()
                                .onAppear {
                                    print("🔍 [DrawingCanvas] Imported photo is being displayed, size: \(photo.size)")
                                }
                        } else {
                            Color.clear
                                .onAppear {
                                    print("🔍 [DrawingCanvas] No imported photo to display (importedPhoto is nil)")
                                }
                        }
                        
                               // Main PencilKit Canvas - Clean and focused
                               PencilKitCanvasView(
                                   canvasView: $canvasView,
                                   coordinator: drawingCoordinator,
                                   drawingEngine: drawingEngine,
                                   stepProgressionManager: stepProgressionManager,
                                   lesson: lesson,
                                   showGuides: showGuides,
                                   guideOpacity: guideOpacity,
                                   showToolPicker: showToolPicker,
                                   onDrawingChanged: handleDrawingChanged,
                                   onStepCompleted: handleStepCompleted,
                                   onLessonCompleted: handleLessonCompleted
                               )
                        
                        // Step Instruction Overlay
                        if showStepInstructions, let currentStep = currentLessonStep {
                            VStack {
                                HStack {
                                    Spacer()
                                    StepInstructionOverlay(
                                        step: currentStep,
                                        currentStepIndex: stepProgressionManager.currentStepIndex,
                                        totalSteps: lesson.steps.count,
                                        onDismiss: { showStepInstructions = false }
                                    )
                                    .padding(.top, 20)
                                    .padding(.trailing, 16)
                                }
                                Spacer()
                            }
                        }
                        
                        // Simplified Visual Feedback - Only show when relevant
                        if showRealTimeFeedback && drawingCoordinator.showVisualFeedback {
                            SimplifiedVisualFeedback(
                                accuracy: drawingCoordinator.currentAccuracy,
                                showCelebration: drawingCoordinator.showCelebration,
                                safeAreaInsets: geometry.safeAreaInsets
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Simplified Bottom Toolbar - Essential tools only with proper safe area handling
                    SimplifiedBottomToolbar(
                        selectedTool: $selectedTool,
                        showGuides: $showGuides,
                        canvasView: canvasView,
                        safeAreaInsets: geometry.safeAreaInsets,
                        onUndo: undoLastStroke,
                        onRedo: redoLastStroke,
                        onClear: clearCanvas,
                        onImportPhoto: { 
                            print("🔍 [DrawingCanvas] Import photo button tapped")
                            print("🔍 [DrawingCanvas] Setting showPhotoImporter = true")
                            showPhotoImporter = true 
                        }
                    )
                }
            }
            .navigationTitle(lesson.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        finishDrawing()
                    }
                    .fontWeight(.semibold)
                }
                
                // Simplified step indicator in toolbar
                ToolbarItem(placement: .principal) {
                    if currentLessonStep != nil {
                        Button {
                            showStepInstructions = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Step \(stepProgressionManager.currentStepIndex + 1) of \(lesson.steps.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🚀 [TUTORIAL] DrawingCanvasView appeared - Starting lesson: \(lesson.title)")
            setupCanvas()
            drawingStartTime = Date()
            setupAIEngine()
            setupRealTimeFeedback()
            setupMemoryManagement()
            setupVideoRecording()
            print("✅ [TUTORIAL] Canvas setup complete")
            print("📋 [TUTORIAL] Lesson has \(lesson.steps.count) steps")
            print("🎯 [TUTORIAL] Current step: \(stepProgressionManager.currentStepIndex + 1)")
            
            // Validate reference images during development
            #if DEBUG
            validateReferenceImageAssets()
            #endif
        }
        .onChange(of: drawingCoordinator.strokeFeedback) { feedback in
            if let feedback = feedback {
                stepProgressionManager.evaluateStrokeForCurrentStep(feedback)
            }
        }
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView(canvasView: canvasView, lesson: lesson)
        }
        .sheet(isPresented: $showPhotoImporter) {
            PhotoImporterView { image in
                print("🔍 [DrawingCanvas] PhotoImporterView callback received")
                print("🔍 [DrawingCanvas] Received image with size: \(image.size)")
                print("🔍 [DrawingCanvas] Setting importedPhoto = image")
                importedPhoto = image
                print("🔍 [DrawingCanvas] importedPhoto set successfully: \(importedPhoto != nil)")
                print("🔍 [DrawingCanvas] Calling analyzeImportedPhoto")
                analyzeImportedPhoto(image)
                print("🔍 [DrawingCanvas] Photo import process completed")
            }
            .onAppear {
                print("🔍 [DrawingCanvas] PhotoImporterView sheet appeared")
            }
            .onDisappear {
                print("🔍 [DrawingCanvas] PhotoImporterView sheet disappeared")
                print("🔍 [DrawingCanvas] Current importedPhoto state: \(importedPhoto != nil)")
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
            LessonCompletionView(
                lesson: lesson,
                finalDrawing: canvasView.drawing,
                accuracy: drawingCoordinator.currentAccuracy,
                completionTime: stepProgressionManager.totalTime,
                recordedVideoURL: recordedVideoURL
            )
        }
    }
    
    // MARK: - Memory Management
    
    private func setupMemoryManagement() {
        // ENHANCED: Setup memory pressure monitoring
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Handle memory warning
        }
        
        print("🧠 [DrawingCanvasView] Memory management setup complete")
    }
    
    private func handleMemoryWarning() {
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            // Clear non-essential cached data
            // Note: Coordinator cleanup handled separately
        }
        
        print("🧹 [DrawingCanvasView] Memory warning handled with autoreleasepool")
    }
    
    private func setupCanvas() {
        print("🎨 [TUTORIAL] Setting up canvas for drawing")
        canvasView.backgroundColor = UIColor.systemBackground
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        print("✅ [TUTORIAL] Canvas configured with pen tool")
    }
    
    private func nextStep() {
        print("➡️ [TUTORIAL] Attempting to progress to next step")
        if stepProgressionManager.progressToNextStep() {
            print("✅ [TUTORIAL] Successfully progressed to next step")
            // Step progression handled by manager
        } else if isLastStep {
            print("🏆 [TUTORIAL] Last step completed - finishing drawing")
            finishDrawing()
        } else {
            print("⚠️ [TUTORIAL] Step progression failed")
        }
    }
    
    private func previousStep() {
        print("⬅️ [TUTORIAL] Going back to previous step")
        let success = stepProgressionManager.goToPreviousStep()
        if success {
            print("✅ [TUTORIAL] Successfully went back to previous step")
        } else {
            print("⚠️ [TUTORIAL] Failed to go back to previous step")
        }
    }
    
    private func undoLastStroke() {
        canvasView.undoManager?.undo()
    }
    
    private func redoLastStroke() {
        canvasView.undoManager?.redo()
    }
    
    private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    private func setupAIEngine() {
        print("🤖 [TUTORIAL] Setting up AI engine for lesson analysis")
        // CRITICAL FIX: Setup tutorial system from lesson data instead of image analysis
        Task<Void, Never> {
            print("🎯 [TUTORIAL] Initializing tutorial system from lesson: \(lesson.title)")
            await drawingEngine.setupTutorialFromLesson(lesson)
            print("✅ [TUTORIAL] Tutorial system setup complete")
            
            // CRITICAL FIX: Start the lesson session in step progression manager
            await MainActor.run {
                print("🚀 [TUTORIAL] Starting lesson session in step progression manager")
                stepProgressionManager.startLesson()
                print("✅ [TUTORIAL] Lesson session started successfully")
                
                // CRITICAL FIX: Initialize the first step
                if let firstStep = currentLessonStep {
                    print("📋 [TUTORIAL] First step initialized: \(firstStep.instruction)")
                    print("🎯 [TUTORIAL] Current step index: \(stepProgressionManager.currentStepIndex)")
                } else {
                    print("❌ [TUTORIAL] No first step found in lesson")
                }
            }
        }
    }
    
    private func createReferenceImage(for category: LessonCategory) -> UIImage {
        // Create a more realistic reference image for Vision framework analysis
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Set white background
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            context.cgContext.setStrokeColor(UIColor.black.cgColor)
            context.cgContext.setFillColor(UIColor.lightGray.cgColor)
            context.cgContext.setLineWidth(3.0)
            
            switch category {
            case .faces:
                // Draw a realistic face outline that Vision can detect
                let faceRect = CGRect(x: 100, y: 80, width: 200, height: 240)
                context.cgContext.addEllipse(in: faceRect)
                context.cgContext.fillPath()
                
                // Add eyes, nose, mouth for landmark detection
                // Eyes
                let leftEyeRect = CGRect(x: 140, y: 150, width: 30, height: 20)
                let rightEyeRect = CGRect(x: 230, y: 150, width: 30, height: 20)
                context.cgContext.addEllipse(in: leftEyeRect)
                context.cgContext.addEllipse(in: rightEyeRect)
                context.cgContext.fillPath()
                
                // Nose
                let nosePath = UIBezierPath()
                nosePath.move(to: CGPoint(x: 200, y: 180))
                nosePath.addLine(to: CGPoint(x: 190, y: 200))
                nosePath.addLine(to: CGPoint(x: 210, y: 200))
                nosePath.close()
                context.cgContext.addPath(nosePath.cgPath)
                context.cgContext.fillPath()
                
                // Mouth
                let mouthRect = CGRect(x: 180, y: 220, width: 40, height: 15)
                context.cgContext.addEllipse(in: mouthRect)
                context.cgContext.fillPath()
                
            case .animals:
                // Draw a simple animal body that can be detected
                let bodyRect = CGRect(x: 50, y: 150, width: 300, height: 120)
                context.cgContext.addEllipse(in: bodyRect)
                context.cgContext.fillPath()
                
                // Add head
                let headRect = CGRect(x: 320, y: 120, width: 100, height: 100)
                context.cgContext.addEllipse(in: headRect)
                context.cgContext.fillPath()
                
            case .objects, .perspective:
                // Draw rectangles for perspective detection
                let rect1 = CGRect(x: 80, y: 100, width: 120, height: 80)
                let rect2 = CGRect(x: 220, y: 140, width: 100, height: 120)
                context.cgContext.addRect(rect1)
                context.cgContext.addRect(rect2)
                context.cgContext.fillPath()
                
            case .hands:
                // Draw a simplified hand outline
                let palmRect = CGRect(x: 150, y: 180, width: 100, height: 120)
                context.cgContext.addRect(palmRect)
                context.cgContext.fillPath()
                
                // Add simple finger rectangles
                for i in 0..<5 {
                    let fingerRect = CGRect(x: 160 + (i * 16), y: 120, width: 12, height: 60)
                    context.cgContext.addRect(fingerRect)
                }
                context.cgContext.fillPath()
                
            case .nature:
                // Draw circular shapes that can be detected as salient objects
                let circle1 = CGRect(x: 120, y: 100, width: 80, height: 80)
                let circle2 = CGRect(x: 200, y: 160, width: 120, height: 120)
                context.cgContext.addEllipse(in: circle1)
                context.cgContext.addEllipse(in: circle2)
                context.cgContext.fillPath()
            }
        }
    }
    
    private func setupFallbackAnalysis() async {
        // Provide basic fallback analysis if Vision framework fails
        print("Setting up fallback analysis for category: \(lesson.category)")
        await drawingEngine.setupBasicGuides(for: lesson.category)
    }
    
    private func validateReferenceImageAssets() {
        // Helper method to validate that reference images exist in bundle
        // This can be called during development to check asset availability
        let allLessons = LessonData.sampleLessons
        var missingImages: [String] = []
        
        for lesson in allLessons {
            if UIImage(named: lesson.referenceImageName) == nil {
                missingImages.append(lesson.referenceImageName)
            }
        }
        
        if !missingImages.isEmpty {
            print("⚠️ Warning: Missing reference image assets:")
            for imageName in missingImages {
                print("   - \(imageName)")
            }
            print("💡 Add these images to your asset catalog for optimal AI guidance")
        } else {
            print("✅ All reference images are available in asset catalog")
        }
    }
    
    private func setupRealTimeFeedback() {
        // Connect unified Core ML analysis to real-time feedback
        // Note: UnifiedStrokeAnalyzer is now used directly by the coordinator
        
        // Configure performance monitoring (remove this problematic call for now)
        // drawingCoordinator.setAnalysisPerformanceCallback { metrics in
        //     print("🔍 DTW Performance: Analysis completed")
        // }
        
        // Set up adaptive difficulty
        stepProgressionManager.setDTWPerformanceAdapter { strokeFeedback in
            adaptLessonDifficulty(based: strokeFeedback)
        }
    }
    
    // MARK: - Critical Feature Implementation Methods
    
    private func handleDrawingChanged(_ drawing: PKDrawing) {
        print("🎨 [TUTORIAL] Drawing changed - Stroke count: \(drawing.strokes.count)")
        // Real-time analysis if enabled
        if showRealTimeFeedback && !drawing.strokes.isEmpty {
            print("🔄 [TUTORIAL] Real-time feedback enabled - starting analysis")
            Task {
                await performRealTimeAnalysis(drawing)
            }
        } else {
            print("⚠️ [TUTORIAL] Real-time feedback disabled or no strokes")
        }
    }
    
    private func handleStepCompleted(_ stepIndex: Int) {
        print("🎉 [TUTORIAL] Step \(stepIndex + 1) completed!")
        withAnimation {
            showRealTimeFeedback = true
        }
        print("✅ [TUTORIAL] Real-time feedback enabled for next step")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Auto-advance to next step after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if stepProgressionManager.canProgressToNext {
                _ = stepProgressionManager.progressToNextStep()
            }
        }
    }
    
    private func handleLessonCompleted() {
        print("🏆 [TUTORIAL] Lesson completed! All steps finished.")
        lessonCompleted = true
        showCompletionSheet = true
        
        // Save completed drawing
        print("💾 [TUTORIAL] Saving completed drawing")
        saveCompletedDrawing()
        
        // Update user progress
        print("📊 [TUTORIAL] Marking lesson as completed in service")
        lessonService.markLessonCompleted(lesson.id)
        
        // Celebration haptic
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    private func performRealTimeAnalysis(_ drawing: PKDrawing) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        guard let currentGuide = drawingEngine.getCurrentGuide() else { return }
        
        // Convert PKDrawing to DrawingStroke
        let drawingStrokes = convertPKDrawingToStrokes(drawing)
        
        for stroke in drawingStrokes {
            let feedback = drawingEngine.analyzeUserStroke(stroke, against: currentGuide)
            
            await MainActor.run {
                drawingCoordinator.strokeFeedback = feedback
                drawingCoordinator.currentAccuracy = feedback.accuracy
            }
        }
    }
    
    private func analyzeCurrentDrawing() {
        Task {
            await performRealTimeAnalysis(canvasView.drawing)
        }
    }
    
    private func analyzeImportedPhoto(_ image: UIImage) {
        print("🔍 [DrawingCanvas] analyzeImportedPhoto called with image size: \(image.size)")
        Task {
            print("🔍 [DrawingCanvas] Starting Vision framework analysis...")
            // Use Vision framework to analyze imported photo
            await drawingEngine.analyzeImage(image, for: lesson.category)
            print("🔍 [DrawingCanvas] Vision framework analysis completed")
            
            // Generate custom guides based on photo analysis
            await MainActor.run {
                print("🔍 [DrawingCanvas] Updating UI state for photo-based guidance")
                // Update UI to show photo-based guidance
                showStepInstructions = true
                showGuides = true
                print("🔍 [DrawingCanvas] UI state updated - showStepInstructions: \(showStepInstructions), showGuides: \(showGuides)")
            }
        }
    }
    
    private func saveCompletedDrawing() {
        guard let imageData = canvasView.drawing.image(from: CGRect(x: 0, y: 0, width: 512, height: 512), scale: 1.0).pngData() else { return }
        
        let userDrawing = UserDrawing(
            lessonId: lesson.id,
            title: "\(lesson.title) - Completed",
            imageData: imageData,
            category: lesson.category,
            authorId: userProfileService.currentUser?.id.uuidString ?? "anonymous"
        )
        
        userProfileService.addDrawing(userDrawing)
    }
    
    private func convertPKDrawingToStrokes(_ pkDrawing: PKDrawing) -> [DrawingStroke] {
        return pkDrawing.strokes.map { pkStroke in
            let points = pkStroke.path.map { $0.location }
            let pressures = pkStroke.path.map { $0.force }
            let velocities = calculateVelocities(from: pkStroke.path)
            
            return DrawingStroke(
                points: points,
                timestamp: Date(),
                pressure: pressures,
                velocity: velocities
            )
        }
    }
    
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
    
    private func adaptLessonDifficulty(based feedback: StrokeFeedback) {
        if feedback.accuracy > 0.9 {
            stepProgressionManager.increaseDifficulty()
        } else if feedback.accuracy < 0.4 {
            stepProgressionManager.decreaseDifficulty()
        }
    }
    
    private func finishDrawing() {
        // Create drawing data
        let drawingData = canvasView.drawing.dataRepresentation()
        _ = Date().timeIntervalSince(drawingStartTime)
        
        // Create user drawing
        let userDrawing = UserDrawing(
            lessonId: lesson.id,
            title: lesson.title,
            imageData: drawingData,
            category: lesson.category
        )
        
        // Add to user profile
        userProfileService.addDrawing(userDrawing)
        
        // Mark lesson as completed
        lessonService.markLessonCompleted(lesson.id)
        
        // Show export options
        showExportOptions = true
    }
    
    // MARK: - Video Recording Methods
    
    private func setupVideoRecording() {
        // Setup notification observers for video recording
        NotificationCenter.default.addObserver(
            forName: .optimizedVideoFrameCaptureRequested,
            object: nil,
            queue: .main
        ) { notification in
            self.captureCanvasFrame(notification: notification)
        }
    }
    
    private func captureCanvasFrame(notification: Notification) {
        guard let timestamp = notification.userInfo?["timestamp"] as? TimeInterval,
              let _ = notification.userInfo?["frameIndex"] as? Int else {
            return
        }
        
        // Capture current canvas state
        let image = captureCanvasAsImage()
        
        // Send captured frame to video recording engine
        videoRecordingEngine.captureFrame(image: image, timestamp: timestamp)
    }
    
    private func captureCanvasAsImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasView.bounds.size)
        return renderer.image { context in
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: false)
        }
    }
    
    private func startVideoRecording() {
        guard !videoRecordingEngine.isRecording else { return }
        
        // Get canvas size
        let canvasSize = canvasView.bounds.size
        
        // Start recording
        videoRecordingEngine.startRecording(canvasSize: canvasSize)
        
        // Start duration timer
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
        }
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("📹 Started video recording")
    }
    
    private func stopVideoRecording() {
        guard videoRecordingEngine.isRecording else { return }
        
        // Stop recording
        videoRecordingEngine.stopRecording()
        
        // Stop duration timer
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Generate video and prepare for sharing
        generateAndPrepareVideo()
        
        print("📹 Stopped video recording - Duration: \(recordingDuration)s")
    }
    
    private func pauseVideoRecording() {
        guard videoRecordingEngine.isRecording else { return }
        videoRecordingEngine.pauseRecording()
    }
    
    private func generateAndPrepareVideo() {
        videoRecordingEngine.generateTimelapseVideo { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let videoURL):
                    print("✅ Video generated successfully: \(videoURL)")
                    self.recordedVideoURL = videoURL
                    self.handleVideoGenerated(url: videoURL)
                    
                case .failure(let error):
                    print("❌ Video generation failed: \(error)")
                    // Handle error - could show alert to user
                }
            }
        }
    }
    
    private func handleVideoGenerated(url: URL) {
        // This could trigger a sharing sheet or save to photos
        // For now, we'll just log the success
        print("🎥 Video ready for sharing: \(url.lastPathComponent)")
        
        // You could integrate with the sharing manager here:
        // sharingManager.shareVideo(url: url, platform: .tikTok)
    }
}

struct CanvasContainer: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let lesson: Lesson
    let currentStep: Int
    let showGuides: Bool
    let guideOpacity: Double
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = UIColor.systemBackground
        canvasView.isOpaque = false
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update guide overlay when step changes
        context.coordinator.updateGuides(for: currentStep, opacity: guideOpacity, visible: showGuides)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: CanvasContainer
        private var guideLayer: CAShapeLayer?
        
        init(_ parent: CanvasContainer) {
            self.parent = parent
        }
        
        func updateGuides(for step: Int, opacity: Double, visible: Bool) {
            guard step < parent.lesson.steps.count else { return }
            
            // Remove existing guide layer
            guideLayer?.removeFromSuperlayer()
            
            guard visible else { return }
            
            let lessonStep = parent.lesson.steps[step]
            let layer = CAShapeLayer()
            
            // Create guide path based on step
            let path = createGuidePath(for: lessonStep)
            layer.path = path.cgPath
            layer.strokeColor = UIColor.systemBlue.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 2.0
            layer.lineDashPattern = [5, 3]
            layer.opacity = Float(opacity)
            
            // Add to canvas
            parent.canvasView.layer.addSublayer(layer)
            guideLayer = layer
        }
        
        private func createGuidePath(for step: LessonStep) -> UIBezierPath {
            let path = UIBezierPath()
            let bounds = parent.canvasView.bounds
            let centerX = bounds.midX
            let centerY = bounds.midY
            
            switch step.shapeType {
            case .circle:
                path.addArc(withCenter: CGPoint(x: centerX, y: centerY), radius: 50, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            case .oval:
                path.addArc(withCenter: CGPoint(x: centerX, y: centerY), radius: 60, startAngle: 0, endAngle: .pi * 2, clockwise: true)
                path.apply(CGAffineTransform(scaleX: 1.0, y: 0.7))
            case .rectangle:
                path.append(UIBezierPath(rect: CGRect(x: centerX - 50, y: centerY - 40, width: 100, height: 80)))
            case .line:
                path.move(to: CGPoint(x: centerX - 60, y: centerY))
                path.addLine(to: CGPoint(x: centerX + 60, y: centerY))
            case .curve:
                path.move(to: CGPoint(x: centerX - 50, y: centerY + 20))
                path.addQuadCurve(to: CGPoint(x: centerX + 50, y: centerY + 20), controlPoint: CGPoint(x: centerX, y: centerY - 40))
            case .polygon:
                // Draw a triangle
                path.move(to: CGPoint(x: centerX, y: centerY - 40))
                path.addLine(to: CGPoint(x: centerX - 35, y: centerY + 20))
                path.addLine(to: CGPoint(x: centerX + 35, y: centerY + 20))
                path.close()
            }
            
            return path
        }
    }
}

struct StepInstructionCard: View {
    let step: LessonStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onDismiss: () -> Void
    let isLastStep: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(currentStep) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(step.instruction)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Progress bar
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            // Navigation buttons
            HStack {
                if currentStep > 1 {
                    Button("Previous", action: onPrevious)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(isLastStep ? "Finish" : "Next") {
                    onNext()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(16)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct BottomToolbar: View {
    @Binding var selectedTool: DrawingTool
    @Binding var showGuides: Bool
    @Binding var guideOpacity: Double
    let canvasView: PKCanvasView
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Guide controls
            HStack {
                Button {
                    showGuides.toggle()
                } label: {
                    HStack {
                        Image(systemName: showGuides ? "eye.fill" : "eye.slash.fill")
                        Text("Guides")
                    }
                    .font(.caption)
                    .foregroundColor(showGuides ? .blue : .secondary)
                }
                
                if showGuides {
                    Slider(value: $guideOpacity, in: 0.1...1.0)
                        .frame(width: 80)
                }
                
                Spacer()
            }
            
            // Main toolbar
            HStack(spacing: 20) {
                // Drawing tools
                HStack(spacing: 16) {
                    ForEach(DrawingTool.allCases, id: \.self) { tool in
                        ToolButton(
                            tool: tool,
                            isSelected: selectedTool == tool
                        ) {
                            selectedTool = tool
                            updateCanvasTool(tool)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    CanvasActionButton(icon: "arrow.uturn.backward", action: onUndo)
                    CanvasActionButton(icon: "arrow.uturn.forward", action: onRedo)
                    CanvasActionButton(icon: "trash", action: onClear, color: .red)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func updateCanvasTool(_ tool: DrawingTool) {
        switch tool {
        case .pencil:
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        case .brush:
            canvasView.tool = PKInkingTool(.marker, color: .black, width: 5)
        }
    }
    
}

struct ToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.iconName)
                    .font(.title3)
                Text(tool.name)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 60, height: 50)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
        }
    }
}

struct CanvasActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .primary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Simplified UI Components Following iOS 18 Best Practices

struct SimplifiedVisualFeedback: View {
    let accuracy: Double
    let showCelebration: Bool
    let safeAreaInsets: EdgeInsets
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                if showCelebration {
                    // Celebration animation - subtle and non-intrusive
                    VStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                            .scaleEffect(showCelebration ? 1.2 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCelebration)
                        
                        Text("Great job!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else if accuracy > 0.7 {
                    // Subtle accuracy indicator
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(Int(accuracy * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 120 + safeAreaInsets.bottom) // Above toolbar with safe area
        }
    }
}

struct SimplifiedBottomToolbar: View {
    @Binding var selectedTool: DrawingTool
    @Binding var showGuides: Bool
    let canvasView: PKCanvasView
    let safeAreaInsets: EdgeInsets
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onImportPhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Essential tools only - following iOS 18 minimalism
            HStack(spacing: 20) {
                // Drawing tools - simplified selection
                HStack(spacing: 12) {
                    ToolButton(
                        tool: .pencil,
                        isSelected: selectedTool == .pencil
                    ) {
                        selectedTool = .pencil
                        updateCanvasTool(.pencil)
                    }
                    
                    ToolButton(
                        tool: .eraser,
                        isSelected: selectedTool == .eraser
                    ) {
                        selectedTool = .eraser
                        updateCanvasTool(.eraser)
                    }
                }
                
                Spacer()
                
                // Essential actions
                HStack(spacing: 16) {
                    Button(action: onUndo) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: onClear) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: onImportPhoto) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            // Guide toggle - subtle and accessible
            HStack {
                Button {
                    showGuides.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showGuides ? "eye.fill" : "eye.slash.fill")
                        Text("Guides")
                    }
                    .font(.caption)
                    .foregroundColor(showGuides ? .blue : .secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8 + safeAreaInsets.bottom) // Add safe area bottom padding
            .background(.ultraThinMaterial)
        }
    }
    
    private func updateCanvasTool(_ tool: DrawingTool) {
        switch tool {
        case .pencil:
            canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        case .brush:
            canvasView.tool = PKInkingTool(.marker, color: .black, width: 5)
        }
    }
}

// MARK: - Step Instruction Overlay
struct StepInstructionOverlay: View {
    let step: LessonStep
    let currentStepIndex: Int
    let totalSteps: Int
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(currentStepIndex + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(step.instruction)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(maxWidth: 280)
    }
}

#Preview {
    DrawingCanvasView(lesson: LessonData.sampleLessons[0])
        .environmentObject(UserProfileService(persistenceService: PersistenceService()))
        .environmentObject(LessonService(persistenceService: PersistenceService()))
}
