import SwiftUI
import PencilKit

// MARK: - Viral Sharing View Controller
struct ViralSharingViewController: View {
    let drawing: UserDrawing
    let originalImage: UIImage?
    let finalImage: UIImage
    let lesson: Lesson?
    
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var monetizationService: MonetizationService
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var videoRecorder = OptimizedVideoRecordingEngine()
    @StateObject private var beforeAfterComposer = BeforeAfterComposer()
    @StateObject private var socialSharingManager = EnhancedSocialSharingManager()
    
    @State private var selectedContentType: SharingContentType = .beforeAfter
    @State private var selectedTransition: TransitionType = .crossfade
    @State private var selectedPlatform: SharingPlatform = .general
    @State private var customCaption = ""
    @State private var selectedHashtags: Set<String> = []
    @State private var sliderPosition: Double = 0.5
    @State private var includeWatermark = true
    @State private var isProcessing = false
    @State private var showPreview = false
    @State private var previewContent: PreviewContent?
    @State private var showShareSheet = false
    @State private var sourceRect = CGRect.zero
    
    // NEW: Viral Template Integration
    @State private var showViralTemplates = false
    @StateObject private var viralTemplateEngine = ViralVideoTemplateEngine()
    
    // Available hashtags for selection
    private var availableHashtags: [String] {
        guard let lesson = lesson else {
            return socialSharingManager.getDefaultHashtags(for: .objects)
        }
        return socialSharingManager.getDefaultHashtags(for: lesson.category)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    HeaderSection(drawing: drawing, lesson: lesson)
                    
                    // Content Type Selection
                    ContentTypeSection(
                        selectedType: $selectedContentType,
                        hasOriginalImage: originalImage != nil,
                        onViralTemplatesSelected: {
                            showViralTemplates = true
                        }
                    )
                    
                    // Configuration Section
                    ConfigurationSection(
                        selectedType: selectedContentType,
                        selectedTransition: $selectedTransition,
                        sliderPosition: $sliderPosition,
                        originalImage: originalImage,
                        finalImage: finalImage
                    )
                    
                    // Platform Selection
                    PlatformSection(selectedPlatform: $selectedPlatform)
                    
                    // Caption and Hashtags
                    CaptionSection(
                        caption: $customCaption,
                        selectedHashtags: $selectedHashtags,
                        availableHashtags: availableHashtags,
                        lesson: lesson,
                        socialSharingManager: socialSharingManager
                    )
                    
                    // Watermark Section
                    WatermarkSection(
                        includeWatermark: $includeWatermark,
                        featureGateManager: monetizationService.featureGateManager
                    )
                    
                    // Action Buttons
                    ActionButtonsSection(
                        isProcessing: isProcessing,
                        onPreview: handlePreview,
                        onShare: handleShare
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("Share Your Art")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            if let previewContent = previewContent {
                PreviewViewController(content: previewContent, onDismiss: {
                    showPreview = false
                })
            }
        }
        .sheet(isPresented: $showViralTemplates) {
            ViralTemplateSelectionView(
                originalImage: originalImage ?? finalImage,
                finalDrawing: finalImage,
                drawingProcess: [], // TODO: Pass actual drawing process frames if available
                onVideoGenerated: { videoURL in
                    // Handle the generated viral video
                    handleViralVideoGenerated(videoURL)
                }
            )
        }
        .overlay(
            Group {
                if isProcessing {
                    ProcessingOverlay(
                        progress: getProcessingProgress(),
                        message: getProcessingMessage()
                    )
                }
            }
        )
        .onAppear {
            setupDefaultValues()
        }
        .onDisappear {
            // Cleanup temporary files when view disappears
            socialSharingManager.cleanupTemporaryFiles()
        }
    }
    
    // MARK: - Viral Template Handler
    
    private func handleViralVideoGenerated(_ videoURL: URL) {
        // Store the generated video for sharing
        Task {
            // Automatically share to the user's preferred platform or show sharing options
            await shareViralVideo(videoURL)
        }
    }
    
    private func shareViralVideo(_ videoURL: URL) async {
        let shareContent = ShareContentType.video(videoURL)
        
        // Use the existing social sharing infrastructure
        let result = await socialSharingManager.shareGeneral(
            content: shareContent,
            sourceView: UIView(), // This would need to be passed from the UI
            caption: customCaption.isEmpty ? getDefaultCaption() : customCaption,
            hashtags: Array(selectedHashtags)
        )
        
        switch result {
        case .success:
            print("✅ Viral video shared successfully")
            
        case .failure(let error):
            print("❌ Failed to share viral video: \(error)")
            // Show error to user
        }
    }
    
    private func getDefaultCaption() -> String {
        if let lesson = lesson {
            return socialSharingManager.getDefaultCaption(for: lesson, includeAppPromo: true)
        }
        return "Just created this amazing artwork! ✨ #SketchAI #LearnToDraw #DigitalArt"
    }
    
    // MARK: - Action Handlers
    
    private func handlePreview() {
        Task {
            isProcessing = true
            
            do {
                let content = try await generateSharingContent()
                
                await MainActor.run {
                    previewContent = content
                    showPreview = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error - could show alert
                    print("Preview generation failed: \(error)")
                }
            }
        }
    }
    
    private func handleShare() {
        Task {
            isProcessing = true
            
            do {
                let content = try await generateSharingContent()
                
                await MainActor.run {
                    isProcessing = false
                    performShare(with: content)
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    // Handle error
                    print("Share content generation failed: \(error)")
                }
            }
        }
    }
    
    private func performShare(with content: PreviewContent) {
        let caption = customCaption.isEmpty ? getDefaultCaption() : customCaption
        let hashtags = Array(selectedHashtags)
        
        Task {
            var shareResult: EnhancedShareResult
            
            switch selectedPlatform {
            case .tiktok:
                switch content {
                case .image(let image):
                    shareResult = await socialSharingManager.shareToTikTok(
                        content: .image(image),
                        caption: caption,
                        hashtags: hashtags
                    )
                case .video(let url):
                    shareResult = await socialSharingManager.shareToTikTok(
                        content: .video(url),
                        caption: caption,
                        hashtags: hashtags
                    )
                case .beforeAfter(let before, let after):
                    shareResult = await socialSharingManager.shareToTikTok(
                        content: .beforeAfter(before: before, after: after),
                        caption: caption,
                        hashtags: hashtags
                    )
                }
                
            case .instagram:
                switch content {
                case .image(let image):
                    shareResult = await socialSharingManager.shareToInstagram(
                        content: .image(image),
                        caption: caption,
                        hashtags: hashtags
                    )
                case .video(let url):
                    shareResult = await socialSharingManager.shareToInstagram(
                        content: .video(url),
                        caption: caption,
                        hashtags: hashtags
                    )
                case .beforeAfter(let before, let after):
                    shareResult = await socialSharingManager.shareToInstagram(
                        content: .beforeAfter(before: before, after: after),
                        caption: caption,
                        hashtags: hashtags
                    )
                }
                
            case .general:
                // Use the general share sheet - need to find a source view
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    
                    let sourceView = window
                    
                    switch content {
                    case .image(let image):
                        shareResult = await socialSharingManager.shareGeneral(
                            content: .image(image),
                            sourceView: sourceView,
                            caption: caption,
                            hashtags: hashtags
                        )
                    case .video(let url):
                        shareResult = await socialSharingManager.shareGeneral(
                            content: .video(url),
                            sourceView: sourceView,
                            caption: caption,
                            hashtags: hashtags
                        )
                    case .beforeAfter(let before, let after):
                        shareResult = await socialSharingManager.shareGeneral(
                            content: .beforeAfter(before: before, after: after),
                            sourceView: sourceView,
                            caption: caption,
                            hashtags: hashtags
                        )
                    }
                } else {
                    shareResult = .failure(.platformNotAvailable("Unable to find source view"))
                }
            }
            
            await MainActor.run {
                handleShareResult(shareResult)
            }
        }
    }
    
    private func handleShareResult(_ result: EnhancedShareResult) {
        switch result {
        case .success(let message):
            print("Share successful: \(message)")
            // Could show success feedback
            dismiss()
        case .failure(let error):
            print("Share failed: \(error.localizedDescription)")
            // Could show error alert
        }
    }
    
    // MARK: - Content Generation
    
    private func generateSharingContent() async throws -> PreviewContent {
        let shouldIncludeWatermark = includeWatermark && monetizationService.featureGateManager.canExportWithoutWatermark() != .allowed
        let watermarkText = monetizationService.featureGateManager.getExportWatermark()
        
        switch selectedContentType {
        case .finalImage:
            let processedImage = shouldIncludeWatermark ? 
                addWatermark(to: finalImage, text: watermarkText) : 
                finalImage
            return .image(processedImage)
            
        case .beforeAfter:
            guard let originalImage = originalImage else {
                throw ViralSharingError.missingOriginalImage
            }
            
            let result = await beforeAfterComposer.createSideBySideComparison(
                beforeImage: originalImage,
                afterImage: finalImage,
                includeWatermark: shouldIncludeWatermark,
                watermarkText: watermarkText
            )
            
            switch result {
            case .success(let image):
                return .beforeAfter(before: originalImage, after: image)
            case .failure(let error):
                throw error
            }
            
        case .slider:
            guard let originalImage = originalImage else {
                throw ViralSharingError.missingOriginalImage
            }
            
            let result = await beforeAfterComposer.createSliderComparison(
                beforeImage: originalImage,
                afterImage: finalImage,
                sliderPosition: sliderPosition,
                includeWatermark: shouldIncludeWatermark,
                watermarkText: watermarkText
            )
            
            switch result {
            case .success(let image):
                return .image(image)
            case .failure(let error):
                throw error
            }
            
        case .transition:
            guard let originalImage = originalImage else {
                throw ViralSharingError.missingOriginalImage
            }
            
            let result = await beforeAfterComposer.createTransitionAnimation(
                beforeImage: originalImage,
                afterImage: finalImage,
                transitionType: selectedTransition,
                includeWatermark: shouldIncludeWatermark,
                watermarkText: watermarkText
            )
            
            switch result {
            case .success(let frames):
                // Convert frames to video
                let videoURL = try await createVideoFromFrames(frames)
                return .video(videoURL)
            case .failure(let error):
                throw error
            }
        }
    }
    
    private func createVideoFromFrames(_ frames: [UIImage]) async throws -> URL {
        // Implementation would use VideoRecordingEngine to create video from frames
        // For now, return a placeholder URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("transition_\(UUID().uuidString).mp4")
        
        // This should be implemented using the video recording engine
        return tempURL
    }
    
    // MARK: - Helper Methods
    
    private func setupDefaultValues() {
        if let lesson = lesson {
            customCaption = socialSharingManager.getDefaultCaption(for: lesson)
            selectedHashtags = Set(socialSharingManager.getDefaultHashtags(for: lesson.category).prefix(5))
        }
        
        // Set watermark based on subscription status
        includeWatermark = monetizationService.featureGateManager.shouldApplyWatermark()
    }
    
    // getDefaultCaption method is defined earlier in the file
    
    private func getProcessingProgress() -> Double {
        // Combine progress from different processors
        let composerProgress = beforeAfterComposer.processingProgress * 0.8
        let recorderProgress = videoRecorder.processingProgress * 0.2
        return composerProgress + recorderProgress
    }
    
    private func getProcessingMessage() -> String {
        switch selectedContentType {
        case .finalImage:
            return "Preparing image..."
        case .beforeAfter, .slider:
            return "Creating comparison..."
        case .transition:
            return "Generating transition video..."
        }
    }
    
    private func addWatermark(to image: UIImage, text: String?) -> UIImage {
        let watermarkText = text ?? "Created with SketchAI"
        
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            // Add watermark text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            
            let attributedText = NSAttributedString(string: watermarkText, attributes: attributes)
            let textSize = attributedText.size()
            
            // Position watermark at bottom right with padding
            let watermarkRect = CGRect(
                x: image.size.width - textSize.width - 20,
                y: image.size.height - textSize.height - 20,
                width: textSize.width,
                height: textSize.height
            )
            
            attributedText.draw(in: watermarkRect)
        }
    }
}

// MARK: - Supporting Types

enum SharingContentType: String, CaseIterable {
    case finalImage = "Final Drawing"
    case beforeAfter = "Before & After"
    case slider = "Slider Comparison"
    case transition = "Transition Video"
    
    var icon: String {
        switch self {
        case .finalImage: return "photo"
        case .beforeAfter: return "rectangle.split.2x1"
        case .slider: return "slider.horizontal.3"
        case .transition: return "play.rectangle"
        }
    }
    
    var description: String {
        switch self {
        case .finalImage: return "Share just your final artwork"
        case .beforeAfter: return "Side-by-side comparison"
        case .slider: return "Interactive reveal slider"
        case .transition: return "Animated transition video"
        }
    }
}

enum SharingPlatform: String, CaseIterable {
    case tiktok = "TikTok"
    case instagram = "Instagram"
    case general = "More Options"
    
    var icon: String {
        switch self {
        case .tiktok: return "camera"
        case .instagram: return "camera.circle"
        case .general: return "square.and.arrow.up"
        }
    }
    
    var color: Color {
        switch self {
        case .tiktok: return .black
        case .instagram: return .pink
        case .general: return .blue
        }
    }
}

enum PreviewContent {
    case image(UIImage)
    case video(URL)
    case beforeAfter(before: UIImage, after: UIImage)
}

enum ViralSharingError: Error, LocalizedError {
    case missingOriginalImage
    case contentGenerationFailed
    case videoCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingOriginalImage:
            return "Original image is required for this sharing type"
        case .contentGenerationFailed:
            return "Failed to generate sharing content"
        case .videoCreationFailed:
            return "Failed to create video"
        }
    }
}

// MARK: - Preview
#Preview {
    ViralSharingViewController(
        drawing: UserDrawing(
            lessonId: nil,
            title: "Test Drawing",
            imageData: Data(),
            category: .faces
        ),
        originalImage: UIImage(systemName: "photo"),
        finalImage: UIImage(systemName: "photo")!,
        lesson: LessonData.sampleLessons[0]
    )
    .environmentObject(UserProfileService(persistenceService: PersistenceService()))
    .environmentObject(MonetizationService())
}

