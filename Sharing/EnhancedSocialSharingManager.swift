import Foundation
import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

// MARK: - Share Content Types (for compatibility with ViralSharingViewController)
enum ShareContentType {
    case image(UIImage)
    case video(URL)
    case beforeAfter(before: UIImage, after: UIImage)
    case timelapse(URL)
}

enum EnhancedShareResult {
    case success(platform: SocialPlatform)
    case failure(SharingError)
}
import Photos

// MARK: - Enhanced Social Sharing Manager
// Complete implementation of video generation and social media sharing

@MainActor
class EnhancedSocialSharingManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isGeneratingVideo = false
    @Published var generationProgress: Double = 0.0
    @Published var lastGeneratedVideoURL: URL?
    @Published var supportedPlatforms: [SocialPlatform] = []
    
    // MARK: - Configuration
    private struct Config {
        // Video settings optimized for social platforms
        static let tikTokVideoSize = CGSize(width: 1080, height: 1920) // 9:16
        static let instagramVideoSize = CGSize(width: 1080, height: 1080) // 1:1
        static let defaultVideoDuration: TimeInterval = 15.0 // 15 seconds max
        static let frameRate: Int32 = 30
        static let videoBitRate = 8_000_000 // 8 Mbps
        
        // Before/after transition settings
        static let transitionDuration: TimeInterval = 1.0
        static let beforeDuration: TimeInterval = 3.0
        static let afterDuration: TimeInterval = 3.0
        static let staticImageDisplayTime: TimeInterval = 2.0
    }
    
    // MARK: - Platform URLs (Disabled to prevent automated behavior)
    private struct PlatformURLs {
        static let tikTokShare = ""
        static let instagramStories = ""
        static let instagramFeed = ""
        static let appStoreBase = ""
        static let tikTokAppStore = ""
        static let instagramAppStore = ""
    }
    
    init() {
        detectSupportedPlatforms()
        setupNotifications()
    }
    
    // MARK: - Platform Detection
    private func detectSupportedPlatforms() {
        var platforms: [SocialPlatform] = []
        
        // Always supported
        platforms.append(.general)
        platforms.append(.copyLink)
        platforms.append(.saveToPhotos)
        
        // Check TikTok
        if canOpenURL(PlatformURLs.tikTokShare) {
            platforms.append(.tikTok)
        }
        
        // Check Instagram
        if canOpenURL(PlatformURLs.instagramStories) {
            platforms.append(.instagram)
        }
        
        supportedPlatforms = platforms
        print("📱 Supported platforms: \(platforms.map { $0.name })")
    }
    
    private func canOpenURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // MARK: - Video Generation Methods
    func createStaticVideoFromImage(
        _ image: UIImage,
        platform: SocialPlatform = .general,
        completion: @escaping (Result<URL, SharingError>) -> Void
    ) {
        isGeneratingVideo = true
        generationProgress = 0.0
        
        Task {
            do {
                let videoURL = try await generateStaticImageVideo(
                    image: image,
                    platform: platform
                )
                
                await MainActor.run {
                    self.isGeneratingVideo = false
                    self.lastGeneratedVideoURL = videoURL
                    completion(.success(videoURL))
                }
                
            } catch {
                await MainActor.run {
                    self.isGeneratingVideo = false
                    completion(.failure(.videoGenerationFailed(error)))
                }
            }
        }
    }
    
    func createBeforeAfterVideo(
        beforeImage: UIImage,
        afterImage: UIImage,
        platform: SocialPlatform = .general,
        completion: @escaping (Result<URL, SharingError>) -> Void
    ) {
        isGeneratingVideo = true
        generationProgress = 0.0
        
        Task {
            do {
                let videoURL = try await generateBeforeAfterVideo(
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    platform: platform
                )
                
                await MainActor.run {
                    self.isGeneratingVideo = false
                    self.lastGeneratedVideoURL = videoURL
                    completion(.success(videoURL))
                }
                
            } catch {
                await MainActor.run {
                    self.isGeneratingVideo = false
                    completion(.failure(.videoGenerationFailed(error)))
                }
            }
        }
    }
    
    func createTimelapseVideo(
        fromFrames frames: [URL],
        platform: SocialPlatform = .general,
        speedMultiplier: Float = 4.0,
        completion: @escaping (Result<URL, SharingError>) -> Void
    ) {
        isGeneratingVideo = true
        generationProgress = 0.0
        
        Task {
            do {
                let videoURL = try await generateTimelapseFromFrameURLs(
                    frameURLs: frames,
                    platform: platform,
                    speedMultiplier: speedMultiplier
                )
                
                await MainActor.run {
                    self.isGeneratingVideo = false
                    self.lastGeneratedVideoURL = videoURL
                    completion(.success(videoURL))
                }
                
            } catch {
                await MainActor.run {
                    self.isGeneratingVideo = false
                    completion(.failure(.videoGenerationFailed(error)))
                }
            }
        }
    }
    
    // MARK: - Video Generation Implementation
    private func generateStaticImageVideo(
        image: UIImage,
        platform: SocialPlatform
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(platform: platform)
        let videoSize = getOptimalVideoSize(for: platform)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings = createVideoSettings(size: videoSize)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes(size: videoSize)
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        // Resize image to video dimensions
        let resizedImage = resizeImage(image, to: videoSize)
        
        // Create frames for static video
        let frameDuration = CMTime(value: 1, timescale: Config.frameRate)
        let totalFrames = Int(Config.staticImageDisplayTime * Double(Config.frameRate))
        
        for frameIndex in 0..<totalFrames {
            // Update progress
            await MainActor.run {
                generationProgress = Double(frameIndex) / Double(totalFrames)
            }
            
            // Wait for video input to be ready
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            // Create pixel buffer
            if let pixelBuffer = createPixelBuffer(from: resizedImage, size: videoSize) {
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
            }
        }
        
        // Finish writing
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw SharingError.videoGenerationFailed(videoWriter.error ?? NSError(domain: "VideoGeneration", code: -1))
        }
        
        print("✅ Generated static video: \(outputURL.path)")
        return outputURL
    }
    
    private func generateBeforeAfterVideo(
        beforeImage: UIImage,
        afterImage: UIImage,
        platform: SocialPlatform
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(platform: platform)
        let videoSize = getOptimalVideoSize(for: platform)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings = createVideoSettings(size: videoSize)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes(size: videoSize)
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        // Resize images
        let resizedBefore = resizeImage(beforeImage, to: videoSize)
        let resizedAfter = resizeImage(afterImage, to: videoSize)
        
        // Generate transition frames
        let transitionFrames = await generateTransitionFrames(
            from: resizedBefore,
            to: resizedAfter,
            size: videoSize
        )
        
        let frameDuration = CMTime(value: 1, timescale: Config.frameRate)
        var frameTime = CMTime.zero
        
        // Add "before" frames
        let beforeFrameCount = Int(Config.beforeDuration * Double(Config.frameRate))
        for _ in 0..<beforeFrameCount {
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            if let pixelBuffer = createPixelBuffer(from: resizedBefore, size: videoSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Add transition frames
        for (index, frame) in transitionFrames.enumerated() {
            await MainActor.run {
                generationProgress = Double(index) / Double(transitionFrames.count) * 0.5 + 0.25
            }
            
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            if let pixelBuffer = createPixelBuffer(from: frame, size: videoSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Add "after" frames
        let afterFrameCount = Int(Config.afterDuration * Double(Config.frameRate))
        for _ in 0..<afterFrameCount {
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            if let pixelBuffer = createPixelBuffer(from: resizedAfter, size: videoSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish writing
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw SharingError.videoGenerationFailed(videoWriter.error ?? NSError(domain: "VideoGeneration", code: -1))
        }
        
        print("✅ Generated before/after video: \(outputURL.path)")
        return outputURL
    }
    
    private func generateTimelapseFromFrameURLs(
        frameURLs: [URL],
        platform: SocialPlatform,
        speedMultiplier: Float
    ) async throws -> URL {
        
        let outputURL = createTemporaryVideoURL(platform: platform)
        let videoSize = getOptimalVideoSize(for: platform)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings = createVideoSettings(size: videoSize)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: createPixelBufferAttributes(size: videoSize)
        )
        
        videoWriter.add(videoInput)
        videoWriter.startWriting()
        videoWriter.startSession(atSourceTime: .zero)
        
        // Calculate frame timing
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(Float(Config.frameRate) * speedMultiplier))
        var frameTime = CMTime.zero
        
        // Process each frame
        for (index, frameURL) in frameURLs.enumerated() {
            await MainActor.run {
                generationProgress = Double(index) / Double(frameURLs.count)
            }
            
            // Load image from disk
            guard let imageData = try? Data(contentsOf: frameURL),
                  let image = UIImage(data: imageData) else {
                continue
            }
            
            // Resize for video
            let resizedImage = resizeImage(image, to: videoSize)
            
            // Wait for video input
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            // Create and append pixel buffer
            if let pixelBuffer = createPixelBuffer(from: resizedImage, size: videoSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish writing
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            throw SharingError.videoGenerationFailed(videoWriter.error ?? NSError(domain: "VideoGeneration", code: -1))
        }
        
        print("✅ Generated timelapse video: \(outputURL.path)")
        return outputURL
    }
    
    // MARK: - Video Helper Methods
    private func generateTransitionFrames(
        from startImage: UIImage,
        to endImage: UIImage,
        size: CGSize
    ) async -> [UIImage] {
        
        let transitionFrameCount = Int(Config.transitionDuration * Double(Config.frameRate))
        var frames: [UIImage] = []
        
        for i in 0..<transitionFrameCount {
            let progress = Float(i) / Float(transitionFrameCount - 1)
            
            // Create transition frame using blend
            let blendedImage = blendImages(
                startImage,
                endImage,
                alpha: progress,
                size: size
            )
            
            frames.append(blendedImage)
        }
        
        return frames
    }
    
    private func blendImages(
        _ image1: UIImage,
        _ image2: UIImage,
        alpha: Float,
        size: CGSize
    ) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Draw first image
            image1.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw second image with alpha
            image2.draw(
                in: CGRect(origin: .zero, size: size),
                blendMode: .normal,
                alpha: CGFloat(alpha)
            )
        }
    }
    
    private func createVideoSettings(size: CGSize) -> [String: Any] {
        return [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: Config.videoBitRate,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoExpectedSourceFrameRateKey: Config.frameRate
            ]
        ]
    }
    
    private func createPixelBufferAttributes(size: CGSize) -> [String: Any] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
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
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private func getOptimalVideoSize(for platform: SocialPlatform) -> CGSize {
        switch platform {
        case .tikTok:
            return Config.tikTokVideoSize
        case .instagram:
            return Config.instagramVideoSize
        default:
            return Config.tikTokVideoSize // Default to TikTok format
        }
    }
    
    private func createTemporaryVideoURL(platform: SocialPlatform) -> URL {
        let fileName = "SketchAI_\(platform.name)_\(Date().timeIntervalSince1970).mp4"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Content Preparation for Async Methods
    private func prepareContentForSharing(_ content: ShareContentType, caption: String, hashtags: [String]) async throws -> URL {
        switch content {
        case .image(let image):
            // Convert image to video for sharing
            return try await generateStaticImageVideo(image: image, platform: .tikTok)
            
        case .video(let url):
            // Use existing video
            return url
            
        case .beforeAfter(let before, let after):
            // Create before/after video
            return try await generateBeforeAfterVideo(beforeImage: before, afterImage: after, platform: .tikTok)
            
        case .timelapse(let url):
            // Use existing timelapse video
            return url
        }
    }
    
    // MARK: - Cleanup Management
    func cleanupTemporaryFiles() {
        if let url = lastGeneratedVideoURL {
            do {
                try FileManager.default.removeItem(at: url)
                print("✅ Cleaned up temporary video file: \(url.lastPathComponent)")
                DispatchQueue.main.async {
                    self.lastGeneratedVideoURL = nil
                }
            } catch {
                print("⚠️ Failed to clean up temporary video file: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Platform Sharing (Async Methods for ViralSharingViewController compatibility)
    func shareToTikTok(
        content: ShareContentType,
        caption: String = "",
        hashtags: [String] = []
    ) async -> EnhancedShareResult {
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let videoURL = try await prepareContentForSharing(content, caption: caption, hashtags: hashtags)
                    shareToTikTok(videoURL: videoURL) { result in
                        switch result {
                        case .success:
                            continuation.resume(returning: EnhancedShareResult.success(platform: .tikTok))
                        case .failure(let error):
                            continuation.resume(returning: EnhancedShareResult.failure(error))
                        }
                    }
                } catch {
                    continuation.resume(returning: EnhancedShareResult.failure(SharingError.contentGenerationFailed))
                }
            }
        }
    }
    
    func shareToTikTok(videoURL: URL, completion: @escaping (Result<Void, SharingError>) -> Void) {
        shareVideoPlatform(
            videoURL: videoURL,
            platform: .tikTok,
            urlScheme: PlatformURLs.tikTokShare,
            appStoreId: PlatformURLs.tikTokAppStore,
            completion: completion
        )
    }
    
    func shareToInstagram(
        content: ShareContentType,
        caption: String = "",
        hashtags: [String] = []
    ) async -> EnhancedShareResult {
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let videoURL = try await prepareContentForSharing(content, caption: caption, hashtags: hashtags)
                    shareToInstagram(videoURL: videoURL) { result in
                        switch result {
                        case .success:
                            continuation.resume(returning: EnhancedShareResult.success(platform: .instagram))
                        case .failure(let error):
                            continuation.resume(returning: EnhancedShareResult.failure(error))
                        }
                    }
                } catch {
                    continuation.resume(returning: EnhancedShareResult.failure(SharingError.contentGenerationFailed))
                }
            }
        }
    }
    
    func shareToInstagram(videoURL: URL, completion: @escaping (Result<Void, SharingError>) -> Void) {
        shareVideoPlatform(
            videoURL: videoURL,
            platform: .instagram,
            urlScheme: PlatformURLs.instagramStories,
            appStoreId: PlatformURLs.instagramAppStore,
            completion: completion
        )
    }
    
    func shareGeneral(
        content: ShareContentType,
        sourceView: UIView,
        sourceRect: CGRect? = nil,
        caption: String = "",
        hashtags: [String] = []
    ) async -> EnhancedShareResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootViewController = window.rootViewController else {
                    continuation.resume(returning: .failure(.platformNotAvailable("Unable to access window scene")))
                    return
                }
                
                let activityItems: [Any]
                
                switch content {
                case .image(let image):
                    activityItems = [image, caption + " " + hashtags.map { "#\($0)" }.joined(separator: " ")]
                case .video(let url):
                    activityItems = [url, caption + " " + hashtags.map { "#\($0)" }.joined(separator: " ")]
                case .beforeAfter(_, let after):
                    // For before/after, share the after image with caption
                    activityItems = [after, caption + " " + hashtags.map { "#\($0)" }.joined(separator: " ")]
                case .timelapse(let url):
                    activityItems = [url, caption + " " + hashtags.map { "#\($0)" }.joined(separator: " ")]
                }
                
                let activityViewController = UIActivityViewController(
                    activityItems: activityItems,
                    applicationActivities: nil
                )
                
                // Configure for iPad
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceView = sourceView
                    popoverController.sourceRect = sourceRect ?? CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = .any
                }
                
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    if let error = error {
                        continuation.resume(returning: .failure(.dataPreparationFailed(error)))
                    } else if completed {
                        continuation.resume(returning: .success(platform: .general))
                    } else {
                        continuation.resume(returning: .failure(.userCancelled))
                    }
                }
                
                rootViewController.present(activityViewController, animated: true)
            }
        }
    }
    
    func saveToPhotos(videoURL: URL, completion: @escaping (Result<Void, SharingError>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                completion(.success(()))
                            } else {
                                completion(.failure(.saveFailed(error ?? NSError(domain: "PhotosSave", code: -1))))
                            }
                        }
                    }
                    
                case .denied, .restricted:
                    completion(.failure(.photoLibraryAccessDenied))
                    
                case .notDetermined:
                    completion(.failure(.photoLibraryAccessDenied))
                    
                @unknown default:
                    completion(.failure(.photoLibraryAccessDenied))
                }
            }
        }
    }
    
    private func shareVideoPlatform(
        videoURL: URL,
        platform: SocialPlatform,
        urlScheme: String,
        appStoreId: String,
        completion: @escaping (Result<Void, SharingError>) -> Void
    ) {
        // Copy video to pasteboard for sharing
        do {
            let videoData = try Data(contentsOf: videoURL)
            UIPasteboard.general.setData(videoData, forPasteboardType: UTType.movie.identifier)
            
            // Try to open the app
            if let url = URL(string: urlScheme), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.platformNotAvailable(platform.name)))
                    }
                }
            } else {
                // App not installed - prompt to install
                promptAppInstallation(appStoreId: appStoreId, platform: platform.name, completion: completion)
            }
            
        } catch {
            completion(.failure(.dataPreparationFailed(error)))
        }
    }
    
    private func promptAppInstallation(
        appStoreId: String,
        platform: String,
        completion: @escaping (Result<Void, SharingError>) -> Void
    ) {
        let appStoreURL = URL(string: "\(PlatformURLs.appStoreBase)\(appStoreId)")!
        
        let alert = UIAlertController(
            title: "\(platform) Not Installed",
            message: "To share to \(platform), you need to install the app first.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Install \(platform)", style: .default) { _ in
            UIApplication.shared.open(appStoreURL)
            completion(.failure(.platformNotAvailable(platform)))
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(.failure(.userCancelled))
        })
        
        // Present alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidBecomeActive() {
        detectSupportedPlatforms()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Content Generation Helpers
    
    func getDefaultCaption(for lesson: Lesson, includeAppPromo: Bool = true) -> String {
        var caption = "Just completed '\(lesson.title)' "
        
        switch lesson.difficulty {
        case .beginner:
            caption += "🌱 Perfect for beginners!"
        case .intermediate:
            caption += "📈 Building my skills!"
        case .advanced:
            caption += "🚀 Advanced level unlocked!"
        }
        
        if includeAppPromo {
            caption += "\n\nLearning to draw with AI guidance has never been easier! ✨"
        }
        
        return caption
    }
    
    func getDefaultHashtags(for category: LessonCategory) -> [String] {
        var defaultTags = ["SketchAI", "LearnToDraw", "DigitalArt", "DrawingTutorial"]
        
        switch category {
        case .faces:
            defaultTags.append(contentsOf: ["PortraitDrawing", "FaceDrawing", "ArtTutorial"])
        case .animals:
            defaultTags.append(contentsOf: ["AnimalArt", "NatureDrawing", "WildlifeArt"])
        case .objects:
            defaultTags.append(contentsOf: ["StillLife", "ObjectDrawing", "ArtPractice"])
        case .hands:
            defaultTags.append(contentsOf: ["HandDrawing", "Anatomy", "ArtStudy"])
        case .perspective:
            defaultTags.append(contentsOf: ["Perspective", "Architecture", "ArtFundamentals"])
        case .nature:
            defaultTags.append(contentsOf: ["NatureArt", "LandscapeDrawing", "BotanicalArt"])
        }
        
        return defaultTags
    }
}

// MARK: - Supporting Types
enum SocialPlatform: String, CaseIterable {
    case tikTok = "tiktok"
    case instagram = "instagram"
    case general = "general"
    case copyLink = "copy_link"
    case saveToPhotos = "save_photos"
    
    var name: String {
        switch self {
        case .tikTok: return "TikTok"
        case .instagram: return "Instagram"
        case .general: return "More Apps"
        case .copyLink: return "Copy Link"
        case .saveToPhotos: return "Save to Photos"
        }
    }
    
    var icon: String {
        switch self {
        case .tikTok: return "music.note"
        case .instagram: return "camera"
        case .general: return "square.and.arrow.up"
        case .copyLink: return "link"
        case .saveToPhotos: return "photo.on.rectangle.angled"
        }
    }
}

enum SharingError: Error, LocalizedError {
    case videoGenerationFailed(Error)
    case platformNotAvailable(String)
    case photoLibraryAccessDenied
    case saveFailed(Error)
    case dataPreparationFailed(Error)
    case userCancelled
    case networkUnavailable
    case missingOriginalImage
    case contentGenerationFailed
    case videoCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .videoGenerationFailed(let error):
            return "Failed to generate video: \(error.localizedDescription)"
        case .platformNotAvailable(let platform):
            return "\(platform) is not available on this device"
        case .photoLibraryAccessDenied:
            return "Photo library access is required to save videos"
        case .saveFailed(let error):
            return "Failed to save video: \(error.localizedDescription)"
        case .dataPreparationFailed(let error):
            return "Failed to prepare data for sharing: \(error.localizedDescription)"
        case .userCancelled:
            return "Sharing was cancelled"
        case .networkUnavailable:
            return "Network connection required for sharing"
        case .missingOriginalImage:
            return "Original image is required for this sharing type"
        case .contentGenerationFailed:
            return "Failed to generate sharing content"
        case .videoCreationFailed:
            return "Failed to create video content"
        }
    }
}
