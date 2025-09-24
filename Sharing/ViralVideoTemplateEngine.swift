import Foundation
import SwiftUI
@preconcurrency import AVFoundation
import CoreGraphics
import UIKit

// MARK: - Viral Video Template Engine
// Implementation of Classic Reveal, Progress Glow-Up, and Meme Format templates
// Integrates with existing BeforeAfterComposer and video generation infrastructure

@MainActor
class ViralVideoTemplateEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentTemplate: ViralTemplate?
    
    // MARK: - Configuration
    private struct Config {
        // Video dimensions optimized for TikTok/Instagram
        static let outputSize = CGSize(width: 1080, height: 1920) // 9:16 aspect ratio
        static let frameRate: Int32 = 30
        static let videoBitRate = 8_000_000 // 8 Mbps for high quality
        
        // Template-specific timing (based on viral video research)
        struct ClassicReveal {
            static let hookDuration: TimeInterval = 2.0      // Show original photo
            static let problemSolutionDuration: TimeInterval = 2.0  // AI guides appear
            static let processDuration: TimeInterval = 4.0   // Sped-up drawing
            static let revealDuration: TimeInterval = 2.0    // Final comparison
            static let totalDuration: TimeInterval = 10.0
        }
        
        struct ProgressGlowUp {
            static let introText: TimeInterval = 2.0         // "Talent is a pursued interest"
            static let beforeState: TimeInterval = 3.0       // Clumsy attempt
            static let processState: TimeInterval = 7.0      // SketchAI process
            static let afterState: TimeInterval = 3.0        // Final result
            static let totalDuration: TimeInterval = 15.0
        }
        
        struct MemeFormat {
            static let memeClipDuration: TimeInterval = 3.0  // Frustrated character
            static let transitionDuration: TimeInterval = 1.0 // Sharp transition
            static let solutionDuration: TimeInterval = 8.0  // SketchAI screen recording
            static let totalDuration: TimeInterval = 12.0
        }
        
        // Text styling
        static let primaryFont = "Helvetica-Bold"
        static let secondaryFont = "Helvetica"
        static let textShadowOpacity: CGFloat = 0.8
    }
    
    // MARK: - Template Generation Methods
    
    /// Creates a Classic Reveal video (10 seconds) - Hook → Problem/Solution → Process → Reveal
    func generateClassicRevealVideo(
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage] = [],
        includeWatermark: Bool = false,
        watermarkText: String? = nil
    ) async -> Result<URL, ViralTemplateError> {
        
        isProcessing = true
        processingProgress = 0.0
        currentTemplate = .classicReveal
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.currentTemplate = nil
            }
        }
        
        return await Task.detached {
            do {
                let videoURL = try await self.createClassicRevealVideo(
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText
                )
                return .success(videoURL)
            } catch {
                return .failure(.generationFailed(error))
            }
        }.value
    }
    
    /// Creates a Progress Glow-Up video (15 seconds) - "Talent is a pursued interest" format
    func generateProgressGlowUpVideo(
        clumsyAttempt: UIImage,
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage] = [],
        includeWatermark: Bool = false,
        watermarkText: String? = nil
    ) async -> Result<URL, ViralTemplateError> {
        
        isProcessing = true
        processingProgress = 0.0
        currentTemplate = .progressGlowUp
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.currentTemplate = nil
            }
        }
        
        return await Task.detached {
            do {
                let videoURL = try await self.createProgressGlowUpVideo(
                    clumsyAttempt: clumsyAttempt,
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText
                )
                return .success(videoURL)
            } catch {
                return .failure(.generationFailed(error))
            }
        }.value
    }
    
    /// Creates a Meme Format video (12 seconds) - Frustrated meme → SketchAI solution
    func generateMemeFormatVideo(
        memeImage: UIImage,
        memeText: String,
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage] = [],
        includeWatermark: Bool = false,
        watermarkText: String? = nil
    ) async -> Result<URL, ViralTemplateError> {
        
        isProcessing = true
        processingProgress = 0.0
        currentTemplate = .memeFormat
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.currentTemplate = nil
            }
        }
        
        return await Task.detached {
            do {
                let videoURL = try await self.createMemeFormatVideo(
                    memeImage: memeImage,
                    memeText: memeText,
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText
                )
                return .success(videoURL)
            } catch {
                return .failure(.generationFailed(error))
            }
        }.value
    }
    
    // MARK: - Classic Reveal Implementation
    private func createClassicRevealVideo(
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage],
        includeWatermark: Bool,
        watermarkText: String?
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(template: .classicReveal)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings = createVideoSettings()
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes()
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: Config.frameRate)
        var frameTime = CMTime.zero
        
        // Phase 1: Hook - Show original photo (2 seconds)
        await updateProgress(0.1)
        let hookFrames = Int(Config.ClassicReveal.hookDuration * Double(Config.frameRate))
        let hookImage = await createHookFrame(originalImage: originalImage)
        
        for _ in 0..<hookFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: hookImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 2: Problem/Solution - AI guides appear (2 seconds)
        await updateProgress(0.3)
        let solutionFrames = Int(Config.ClassicReveal.problemSolutionDuration * Double(Config.frameRate))
        let solutionImage = await createSolutionFrame(originalImage: originalImage)
        
        for _ in 0..<solutionFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: solutionImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 3: Process - Sped-up drawing (4 seconds)
        await updateProgress(0.5)
        let processFrames = Int(Config.ClassicReveal.processDuration * Double(Config.frameRate))
        let processImages = await createProcessFrames(
            from: originalImage,
            to: finalDrawing,
            drawingProcess: drawingProcess,
            frameCount: processFrames
        )
        
        for (index, processImage) in processImages.enumerated() {
            await updateProgress(0.5 + (Double(index) / Double(processImages.count)) * 0.3)
            
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: processImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 4: Reveal - Side-by-side comparison (2 seconds)
        await updateProgress(0.8)
        let revealFrames = Int(Config.ClassicReveal.revealDuration * Double(Config.frameRate))
        let revealImage = await createRevealFrame(originalImage: originalImage, finalDrawing: finalDrawing)
        
        for _ in 0..<revealFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: revealImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish video
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw ViralTemplateError.generationFailed(videoWriter.error ?? NSError(domain: "ClassicReveal", code: -1))
        }
        
        await updateProgress(1.0)
        print("✅ Generated Classic Reveal video: \(outputURL.path)")
        return outputURL
    }
    
    // MARK: - Progress Glow-Up Implementation
    private func createProgressGlowUpVideo(
        clumsyAttempt: UIImage,
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage],
        includeWatermark: Bool,
        watermarkText: String?
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(template: .progressGlowUp)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings = createVideoSettings()
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes()
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: Config.frameRate)
        var frameTime = CMTime.zero
        
        // Phase 1: Intro text - "Talent is a pursued interest" (2 seconds)
        await updateProgress(0.1)
        let introFrames = Int(Config.ProgressGlowUp.introText * Double(Config.frameRate))
        let introImage = await createIntroTextFrame()
        
        for _ in 0..<introFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: introImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 2: Before state - Show clumsy attempt (3 seconds)
        await updateProgress(0.25)
        let beforeFrames = Int(Config.ProgressGlowUp.beforeState * Double(Config.frameRate))
        let beforeImage = await createBeforeStateFrame(clumsyAttempt: clumsyAttempt)
        
        for _ in 0..<beforeFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: beforeImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 3: Process state - SketchAI transformation (7 seconds)
        await updateProgress(0.4)
        let processFrames = Int(Config.ProgressGlowUp.processState * Double(Config.frameRate))
        let processImages = await createProgressProcessFrames(
            from: originalImage,
            to: finalDrawing,
            drawingProcess: drawingProcess,
            frameCount: processFrames
        )
        
        for (index, processImage) in processImages.enumerated() {
            await updateProgress(0.4 + (Double(index) / Double(processImages.count)) * 0.4)
            
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: processImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 4: After state - Final result with celebration (3 seconds)
        await updateProgress(0.8)
        let afterFrames = Int(Config.ProgressGlowUp.afterState * Double(Config.frameRate))
        let afterImage = await createAfterStateFrame(finalDrawing: finalDrawing)
        
        for _ in 0..<afterFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: afterImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish video
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw ViralTemplateError.generationFailed(videoWriter.error ?? NSError(domain: "ProgressGlowUp", code: -1))
        }
        
        await updateProgress(1.0)
        print("✅ Generated Progress Glow-Up video: \(outputURL.path)")
        return outputURL
    }
    
    // MARK: - Meme Format Implementation
    private func createMemeFormatVideo(
        memeImage: UIImage,
        memeText: String,
        originalImage: UIImage,
        finalDrawing: UIImage,
        drawingProcess: [UIImage],
        includeWatermark: Bool,
        watermarkText: String?
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(template: .memeFormat)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let videoSettings = createVideoSettings()
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes()
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: Config.frameRate)
        var frameTime = CMTime.zero
        
        // Phase 1: Meme clip - Frustrated character (3 seconds)
        await updateProgress(0.1)
        let memeFrames = Int(Config.MemeFormat.memeClipDuration * Double(Config.frameRate))
        let memeFrame = await createMemeFrame(memeImage: memeImage, memeText: memeText)
        
        for _ in 0..<memeFrames {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: memeFrame, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 2: Sharp transition (1 second)
        await updateProgress(0.3)
        let transitionFrames = Int(Config.MemeFormat.transitionDuration * Double(Config.frameRate))
        let transitionImages = await createSharpTransition(
            from: memeFrame,
            to: originalImage,
            frameCount: transitionFrames
        )
        
        for transitionImage in transitionImages {
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: transitionImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Phase 3: Solution - SketchAI screen recording (8 seconds)
        await updateProgress(0.4)
        let solutionFrames = Int(Config.MemeFormat.solutionDuration * Double(Config.frameRate))
        let solutionImages = await createMemeProcessFrames(
            from: originalImage,
            to: finalDrawing,
            drawingProcess: drawingProcess,
            frameCount: solutionFrames
        )
        
        for (index, solutionImage) in solutionImages.enumerated() {
            await updateProgress(0.4 + (Double(index) / Double(solutionImages.count)) * 0.5)
            
            while !videoInput.isReadyForMoreMediaData { await Task.yield() }
            
            if let pixelBuffer = createPixelBuffer(from: solutionImage, size: Config.outputSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish video
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw ViralTemplateError.generationFailed(videoWriter.error ?? NSError(domain: "MemeFormat", code: -1))
        }
        
        await updateProgress(1.0)
        print("✅ Generated Meme Format video: \(outputURL.path)")
        return outputURL
    }
    
    // MARK: - Frame Generation Helpers
    
    private func createHookFrame(originalImage: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let hookImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Fill background
                    cgContext.setFillColor(UIColor.black.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                    
                    // Draw original image centered
                    let imageRect = self.calculateAspectFitRect(
                        for: originalImage.size,
                        in: Config.outputSize,
                        padding: 60
                    )
                    originalImage.draw(in: imageRect)
                    
                    // Add hook text overlay
                    self.drawText(
                        "Look at this photo...",
                        in: CGRect(x: 40, y: 100, width: Config.outputSize.width - 80, height: 80),
                        context: cgContext,
                        fontSize: 36,
                        color: .white
                    )
                }
                
                continuation.resume(returning: hookImage)
            }
        }
    }
    
    private func createSolutionFrame(originalImage: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let solutionImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Fill background
                    cgContext.setFillColor(UIColor.black.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                    
                    // Draw original image centered
                    let imageRect = self.calculateAspectFitRect(
                        for: originalImage.size,
                        in: Config.outputSize,
                        padding: 60
                    )
                    originalImage.draw(in: imageRect)
                    
                    // Add AI guides overlay (simulated)
                    self.drawSimulatedAIGuides(in: imageRect, context: cgContext)
                    
                    // Add solution text
                    self.drawText(
                        "SketchAI breaks it down!",
                        in: CGRect(x: 40, y: Config.outputSize.height - 200, width: Config.outputSize.width - 80, height: 80),
                        context: cgContext,
                        fontSize: 36,
                        color: .yellow
                    )
                }
                
                continuation.resume(returning: solutionImage)
            }
        }
    }
    
    private func createProcessFrames(
        from originalImage: UIImage,
        to finalDrawing: UIImage,
        drawingProcess: [UIImage],
        frameCount: Int
    ) async -> [UIImage] {
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var frames: [UIImage] = []
                
                // Use provided drawing process or create interpolated frames
                let sourceImages = drawingProcess.isEmpty ? 
                    self.createInterpolatedFrames(from: originalImage, to: finalDrawing, count: frameCount) :
                    drawingProcess
                
                // Distribute source images across frame count
                for i in 0..<frameCount {
                    let sourceIndex = min(i * sourceImages.count / frameCount, sourceImages.count - 1)
                    let sourceImage = sourceImages[sourceIndex]
                    
                    let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                    let frame = renderer.image { context in
                        let cgContext = context.cgContext
                        
                        // Fill background
                        cgContext.setFillColor(UIColor.black.cgColor)
                        cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                        
                        // Draw process image
                        let imageRect = self.calculateAspectFitRect(
                            for: sourceImage.size,
                            in: Config.outputSize,
                            padding: 60
                        )
                        sourceImage.draw(in: imageRect)
                        
                        // Add progress indicator
                        let progress = Float(i) / Float(frameCount - 1)
                        self.drawProgressIndicator(progress: progress, context: cgContext)
                    }
                    
                    frames.append(frame)
                }
                
                continuation.resume(returning: frames)
            }
        }
    }
    
    private func createRevealFrame(originalImage: UIImage, finalDrawing: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let revealImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Fill background
                    cgContext.setFillColor(UIColor.black.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                    
                    // Calculate side-by-side layout
                    let imageWidth = Config.outputSize.width / 2
                    let imageHeight = Config.outputSize.height * 0.6
                    let yOffset = (Config.outputSize.height - imageHeight) / 2
                    
                    // Draw original image (left)
                    let originalRect = CGRect(x: 0, y: yOffset, width: imageWidth, height: imageHeight)
                    var originalFitRect = self.calculateAspectFitRect(for: originalImage.size, in: originalRect.size)
                    originalFitRect.origin.x += originalRect.origin.x
                    originalFitRect.origin.y += originalRect.origin.y
                    originalImage.draw(in: originalFitRect)
                    
                    // Draw final drawing (right)
                    let finalRect = CGRect(x: imageWidth, y: yOffset, width: imageWidth, height: imageHeight)
                    var finalFitRect = self.calculateAspectFitRect(for: finalDrawing.size, in: finalRect.size)
                    finalFitRect.origin.x += finalRect.origin.x
                    finalFitRect.origin.y += finalRect.origin.y
                    finalDrawing.draw(in: finalFitRect)
                    
                    // Draw center divider
                    cgContext.setStrokeColor(UIColor.white.cgColor)
                    cgContext.setLineWidth(3.0)
                    cgContext.move(to: CGPoint(x: imageWidth, y: yOffset))
                    cgContext.addLine(to: CGPoint(x: imageWidth, y: yOffset + imageHeight))
                    cgContext.strokePath()
                    
                    // Add labels
                    self.drawText("BEFORE", in: CGRect(x: 20, y: yOffset - 60, width: imageWidth - 40, height: 40), context: cgContext, fontSize: 24, color: .white)
                    self.drawText("AFTER", in: CGRect(x: imageWidth + 20, y: yOffset - 60, width: imageWidth - 40, height: 40), context: cgContext, fontSize: 24, color: .white)
                    
                    // Add celebration text
                    self.drawText("I can't believe I drew this!", in: CGRect(x: 40, y: yOffset + imageHeight + 40, width: Config.outputSize.width - 80, height: 60), context: cgContext, fontSize: 32, color: .yellow)
                }
                
                continuation.resume(returning: revealImage)
            }
        }
    }
    
    private func createIntroTextFrame() async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let introImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Gradient background
                    let colors = [UIColor.purple.cgColor, UIColor.blue.cgColor]
                    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
                    cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: Config.outputSize.height), options: [])
                    
                    // Main quote
                    self.drawText(
                        "\"Talent is a\npursued interest\"",
                        in: CGRect(x: 60, y: Config.outputSize.height / 2 - 100, width: Config.outputSize.width - 120, height: 200),
                        context: cgContext,
                        fontSize: 48,
                        color: .white,
                        alignment: .center
                    )
                    
                    // Attribution
                    self.drawText(
                        "- Bob Ross",
                        in: CGRect(x: 60, y: Config.outputSize.height / 2 + 120, width: Config.outputSize.width - 120, height: 60),
                        context: cgContext,
                        fontSize: 24,
                        color: UIColor.white.withAlphaComponent(0.8),
                        alignment: .center
                    )
                }
                
                continuation.resume(returning: introImage)
            }
        }
    }
    
    private func createBeforeStateFrame(clumsyAttempt: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let beforeImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Fill background
                    cgContext.setFillColor(UIColor.systemGray6.cgColor)
                    cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                    
                    // Draw clumsy attempt
                    let imageRect = self.calculateAspectFitRect(
                        for: clumsyAttempt.size,
                        in: Config.outputSize,
                        padding: 80
                    )
                    clumsyAttempt.draw(in: imageRect)
                    
                    // Add "before" text
                    self.drawText(
                        "My first attempt... 😅",
                        in: CGRect(x: 40, y: 120, width: Config.outputSize.width - 80, height: 80),
                        context: cgContext,
                        fontSize: 36,
                        color: .systemRed
                    )
                }
                
                continuation.resume(returning: beforeImage)
            }
        }
    }
    
    private func createAfterStateFrame(finalDrawing: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                let afterImage = renderer.image { context in
                    let cgContext = context.cgContext
                    
                    // Celebration background
                    let colors = [UIColor.yellow.cgColor, UIColor.orange.cgColor]
                    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
                    cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: Config.outputSize.height), options: [])
                    
                    // Draw final drawing
                    let imageRect = self.calculateAspectFitRect(
                        for: finalDrawing.size,
                        in: Config.outputSize,
                        padding: 100
                    )
                    finalDrawing.draw(in: imageRect)
                    
                    // Add celebration elements
                    self.drawCelebrationElements(context: cgContext)
                    
                    // Add success text
                    self.drawText(
                        "With SketchAI! 🎉",
                        in: CGRect(x: 40, y: 120, width: Config.outputSize.width - 80, height: 80),
                        context: cgContext,
                        fontSize: 42,
                        color: .white
                    )
                }
                
                continuation.resume(returning: afterImage)
            }
        }
    }
    
    private func createMemeFrame(memeImage: UIImage, memeText: String) async -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
        let memeFrame = renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
            
            // Draw meme image
            let imageRect = self.calculateAspectFitRect(
                for: memeImage.size,
                in: Config.outputSize,
                padding: 60
            )
            memeImage.draw(in: imageRect)
            
            // Add meme text (top and bottom)
            let textLines = memeText.components(separatedBy: "|") // Split on | for top/bottom
            
            if textLines.count > 0 {
                self.drawMemeText(
                    textLines[0],
                    in: CGRect(x: 20, y: 60, width: Config.outputSize.width - 40, height: 120),
                    context: cgContext,
                    position: .top
                )
            }
            
            if textLines.count > 1 {
                self.drawMemeText(
                    textLines[1],
                    in: CGRect(x: 20, y: Config.outputSize.height - 180, width: Config.outputSize.width - 40, height: 120),
                    context: cgContext,
                    position: .bottom
                )
            }
        }
        
        return memeFrame
    }
    
    // MARK: - Helper Methods
    
    nonisolated private func createInterpolatedFrames(from startImage: UIImage, to endImage: UIImage, count: Int) -> [UIImage] {
        var frames: [UIImage] = []
        
        for i in 0..<count {
            let progress = Float(i) / Float(count - 1)
            
            let renderer = UIGraphicsImageRenderer(size: startImage.size)
            let interpolatedFrame = renderer.image { _ in
                startImage.draw(at: .zero)
                endImage.draw(at: .zero, blendMode: .normal, alpha: CGFloat(progress))
            }
            
            frames.append(interpolatedFrame)
        }
        
        return frames
    }
    
    nonisolated private func calculateAspectFitRect(for imageSize: CGSize, in containerSize: CGSize, padding: CGFloat = 0) -> CGRect {
        let availableSize = CGSize(
            width: containerSize.width - padding * 2,
            height: containerSize.height - padding * 2
        )
        
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = availableSize.width / availableSize.height
        
        var rect = CGRect.zero
        
        if imageAspect > containerAspect {
            // Image is wider - fit width
            rect.size.width = availableSize.width
            rect.size.height = availableSize.width / imageAspect
        } else {
            // Image is taller - fit height
            rect.size.height = availableSize.height
            rect.size.width = availableSize.height * imageAspect
        }
        
        // Center the rect
        rect.origin.x = (containerSize.width - rect.size.width) / 2
        rect.origin.y = (containerSize.height - rect.size.height) / 2
        
        return rect
    }
    
    nonisolated private func drawText(
        _ text: String,
        in rect: CGRect,
        context: CGContext,
        fontSize: CGFloat,
        color: UIColor,
        alignment: NSTextAlignment = .center
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: color,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    nonisolated private func drawMemeText(_ text: String, in rect: CGRect, context: CGContext, position: MemeTextPosition) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Impact", size: 48) ?? UIFont.systemFont(ofSize: 48, weight: .black),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text.uppercased(), attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    nonisolated private func drawSimulatedAIGuides(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        // Draw construction lines (simulated AI guides)
        context.setStrokeColor(UIColor.cyan.cgColor)
        context.setLineWidth(2.0)
        context.setLineDash(phase: 0, lengths: [5, 5])
        
        // Horizontal guide lines
        context.move(to: CGPoint(x: rect.minX, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.strokePath()
        
        // Vertical guide lines
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.strokePath()
        
        // Diagonal guides
        context.move(to: CGPoint(x: rect.minX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        context.strokePath()
        
        context.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        context.strokePath()
        
        context.restoreGState()
    }
    
    nonisolated private func drawProgressIndicator(progress: Float, context: CGContext) {
        let barRect = CGRect(x: 40, y: Config.outputSize.height - 80, width: Config.outputSize.width - 80, height: 20)
        
        // Background
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.fill(barRect)
        
        // Progress
        let progressRect = CGRect(x: barRect.minX, y: barRect.minY, width: barRect.width * CGFloat(progress), height: barRect.height)
        context.setFillColor(UIColor.green.cgColor)
        context.fill(progressRect)
        
        // Border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.stroke(barRect)
    }
    
    nonisolated private func drawCelebrationElements(context: CGContext) {
        // Draw sparkles/stars around the image
        let sparklePositions: [(CGFloat, CGFloat)] = [
            (100, 200), (200, 150), (300, 180), (400, 120),
            (500, 200), (600, 160), (700, 140), (800, 190),
            (150, 800), (250, 850), (350, 820), (450, 880),
            (550, 840), (650, 860), (750, 810), (850, 870)
        ]
        
        context.setFillColor(UIColor.white.cgColor)
        
        for (x, y) in sparklePositions {
            let sparkleRect = CGRect(x: x - 8, y: y - 8, width: 16, height: 16)
            context.fillEllipse(in: sparkleRect)
        }
    }
    
    private func createVideoSettings() -> [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(Config.outputSize.width),
            AVVideoHeightKey: Int(Config.outputSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: Config.videoBitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoExpectedSourceFrameRateKey: Config.frameRate
            ]
        ]
    }
    
    private func createPixelBufferAttributes() -> [String: Any] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Int(Config.outputSize.width),
            kCVPixelBufferHeightKey as String: Int(Config.outputSize.height),
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
    }
    
    private func createPixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        
        return pixelBuffer
    }
    
    private func createTemporaryVideoURL(template: ViralTemplate) -> URL {
        let fileName = "SketchAI_\(template.rawValue)_\(Date().timeIntervalSince1970).mp4"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            self.processingProgress = progress
        }
    }
    
    // MARK: - Additional Frame Generation Methods (for Progress Glow-Up and Meme Format)
    
    private func createProgressProcessFrames(
        from originalImage: UIImage,
        to finalDrawing: UIImage,
        drawingProcess: [UIImage],
        frameCount: Int
    ) async -> [UIImage] {
        
        // Similar to createProcessFrames but with Progress Glow-Up specific styling
        return await createProcessFrames(
            from: originalImage,
            to: finalDrawing,
            drawingProcess: drawingProcess,
            frameCount: frameCount
        )
    }
    
    private func createMemeProcessFrames(
        from originalImage: UIImage,
        to finalDrawing: UIImage,
        drawingProcess: [UIImage],
        frameCount: Int
    ) async -> [UIImage] {
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var frames: [UIImage] = []
                
                let sourceImages = drawingProcess.isEmpty ? 
                    self.createInterpolatedFrames(from: originalImage, to: finalDrawing, count: frameCount) :
                    drawingProcess
                
                for i in 0..<frameCount {
                    let sourceIndex = min(i * sourceImages.count / frameCount, sourceImages.count - 1)
                    let sourceImage = sourceImages[sourceIndex]
                    
                    let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
                    let frame = renderer.image { context in
                        let cgContext = context.cgContext
                        
                        // Fill background (app-like interface)
                        cgContext.setFillColor(UIColor.systemGray6.cgColor)
                        cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
                        
                        // Draw mock app interface
                        self.drawMockAppInterface(context: cgContext)
                        
                        // Draw process image in "canvas" area
                        let canvasRect = CGRect(x: 40, y: 200, width: Config.outputSize.width - 80, height: Config.outputSize.height - 400)
                        var imageRect = self.calculateAspectFitRect(for: sourceImage.size, in: canvasRect.size)
                        imageRect.origin.x += canvasRect.origin.x
                        imageRect.origin.y += canvasRect.origin.y
                        sourceImage.draw(in: imageRect)
                    }
                    
                    frames.append(frame)
                }
                
                continuation.resume(returning: frames)
            }
        }
    }
    
    private func createSharpTransition(from startImage: UIImage, to endImage: UIImage, frameCount: Int) async -> [UIImage] {
        var frames: [UIImage] = []
        
        for i in 0..<frameCount {
            let progress = Float(i) / Float(frameCount - 1)
            
            let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
            let frame = renderer.image { _ in
                if progress < 0.5 {
                    // First half: start image
                    startImage.draw(at: .zero)
                } else {
                    // Second half: end image (sharp transition)
                    let imageRect = self.calculateAspectFitRect(
                        for: endImage.size,
                        in: Config.outputSize,
                        padding: 60
                    )
                    
                    UIColor.black.setFill()
                    UIRectFill(CGRect(origin: .zero, size: Config.outputSize))
                    
                    endImage.draw(in: imageRect)
                }
            }
            
            frames.append(frame)
        }
        
        return frames
    }
    
    nonisolated private func drawMockAppInterface(context: CGContext) {
        // Draw mock app header
        let headerRect = CGRect(x: 0, y: 0, width: Config.outputSize.width, height: 120)
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fill(headerRect)
        
        // App title
        drawText(
            "SketchAI",
            in: CGRect(x: 40, y: 40, width: Config.outputSize.width - 80, height: 40),
            context: context,
            fontSize: 28,
            color: .white
        )
        
        // Mock toolbar
        let toolbarRect = CGRect(x: 0, y: Config.outputSize.height - 120, width: Config.outputSize.width, height: 120)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.fill(toolbarRect)
        
        // Mock tool icons (simplified)
        let toolPositions: [CGFloat] = [100, 200, 300, 400, 500, 600, 700, 800]
        context.setFillColor(UIColor.systemGray.cgColor)
        
        for x in toolPositions {
            let toolRect = CGRect(x: x - 20, y: Config.outputSize.height - 80, width: 40, height: 40)
            context.fillEllipse(in: toolRect)
        }
    }
}

// MARK: - Supporting Types

enum ViralTemplate: String, CaseIterable {
    case classicReveal = "classic_reveal"
    case progressGlowUp = "progress_glow_up" 
    case memeFormat = "meme_format"
    
    var displayName: String {
        switch self {
        case .classicReveal: return "Classic Reveal"
        case .progressGlowUp: return "Progress Glow-Up"
        case .memeFormat: return "Meme Format"
        }
    }
    
    var duration: TimeInterval {
        switch self {
        case .classicReveal: return 10.0
        case .progressGlowUp: return 15.0
        case .memeFormat: return 12.0
        }
    }
    
    var description: String {
        switch self {
        case .classicReveal:
            return "10s video: Photo → AI guides → Drawing process → Before/After reveal"
        case .progressGlowUp:
            return "15s video: \"Talent is pursued interest\" → Before → SketchAI → After"
        case .memeFormat:
            return "12s video: Frustrated meme → Sharp transition → SketchAI solution"
        }
    }
}

enum MemeTextPosition {
    case top
    case bottom
}

enum ViralTemplateError: Error, LocalizedError {
    case generationFailed(Error)
    case invalidInput(String)
    case processingTimeout
    case insufficientMemory
    
    var errorDescription: String? {
        switch self {
        case .generationFailed(let error):
            return "Template generation failed: \(error.localizedDescription)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .processingTimeout:
            return "Template generation timed out"
        case .insufficientMemory:
            return "Insufficient memory for template generation"
        }
    }
}

// MARK: - Template Configuration

struct ViralTemplateConfiguration {
    let template: ViralTemplate
    let includeWatermark: Bool
    let watermarkText: String?
    let customization: TemplateCustomization?
    
    init(template: ViralTemplate, includeWatermark: Bool = false, watermarkText: String? = nil, customization: TemplateCustomization? = nil) {
        self.template = template
        self.includeWatermark = includeWatermark
        self.watermarkText = watermarkText
        self.customization = customization
    }
}

struct TemplateCustomization {
    let backgroundColor: UIColor?
    let textColor: UIColor?
    let accentColor: UIColor?
    let customText: [String: String]? // Key-value pairs for custom text overlays
    
    init(backgroundColor: UIColor? = nil, textColor: UIColor? = nil, accentColor: UIColor? = nil, customText: [String: String]? = nil) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.customText = customText
    }
}