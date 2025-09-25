import Foundation
import SwiftUI
import PencilKit
@preconcurrency import AVFoundation
import CoreGraphics
import Combine

// MARK: - Memory-Optimized Video Recording Engine
// This implementation addresses the critical memory management flaw by writing frames to disk
// instead of holding UIImage objects in memory

@MainActor
class OptimizedVideoRecordingEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordingProgress: Double = 0.0
    @Published var processingProgress: Double = 0.0
    @Published var isProcessing = false
    @Published var frameCount = 0
    @Published var estimatedFileSize: String = "0 MB"
    
    // MARK: - Memory-Optimized Frame Storage
    private var recordedFrames: [DiskBasedFrame] = []
    private var tempDirectory: URL?
    private var recordingStartTime: Date?
    private var canvasSize: CGSize = .zero
    private var frameCaptureTimes: [TimeInterval] = []
    private var lastMemoryWarning: Date?
    
    // MARK: - Configuration
    private struct Config {
        static let targetFrameRate: Int = 30
        static let captureInterval: TimeInterval = 0.1 // Capture every 100ms
        static let maxRecordingDuration: TimeInterval = 600 // 10 minutes max (increased safely)
        static let outputVideoSize = CGSize(width: 1080, height: 1920) // 9:16 TikTok format
        static let timelapseSpeedMultiplier: Float = 8.0
        
        // Memory optimization settings
        static let frameCompressionQuality: CGFloat = 0.7
        static let maxMemoryUsageMB: Int = 100 // Conservative memory limit
        static let diskCleanupDelay: TimeInterval = 300 // 5 minutes after completion
        
        // File management
        static let frameFilePrefix = "frame"
        static let frameFileExtension = "jpg"
    }
    
    // MARK: - Timer and Background Processing
    private var captureTimer: Timer?
    private var frameCounter = 0
    private var backgroundQueue = DispatchQueue(label: "video.frame.processing", qos: .utility)
    private var memoryMonitorTimer: Timer?
    
    // MARK: - Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
        startMemoryMonitoring()
    }
    
    deinit {
        // Synchronous cleanup only - can't call async/MainActor methods from deinit
        captureTimer?.invalidate()
        captureTimer = nil
        memoryMonitorTimer?.invalidate()
        memoryMonitorTimer = nil
        // Can't mutate @Published properties from deinit - they're MainActor isolated
    }
    
    // MARK: - Recording Control
    func startRecording(canvasSize: CGSize) {
        guard !isRecording else { return }
        
        // Setup temporary directory for this session
        do {
            let sessionID = UUID().uuidString
            tempDirectory = FileManager.default.temporaryDirectory
                .appendingPathComponent("SketchAI_Video_\(sessionID)")
            
            try FileManager.default.createDirectory(
                at: tempDirectory!,
                withIntermediateDirectories: true
            )
            
            print("📁 Created temp directory: \(tempDirectory!.path)")
        } catch {
            print("❌ Failed to create temp directory: \(error)")
            return
        }
        
        // Initialize recording session
        self.canvasSize = canvasSize
        recordedFrames.removeAll()
        frameCaptureTimes.removeAll()
        recordingStartTime = Date()
        frameCounter = 0
        isRecording = true
        
        // Start capture timer
        captureTimer = Timer.scheduledTimer(withTimeInterval: Config.captureInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureCurrentFrame()
            }
        }
        
        print("📹 Started optimized video recording - Canvas: \(canvasSize)")
        
        // Track analytics
        trackRecordingStart()
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        captureTimer?.invalidate()
        captureTimer = nil
        isRecording = false
        
        let duration = Date().timeIntervalSince(recordingStartTime ?? Date())
        print("📹 Stopped recording - Duration: \(duration)s, Frames: \(recordedFrames.count)")
        
        // Update final estimates
        updateStorageEstimates()
        
        // Track analytics
        trackRecordingStop(duration: duration, frameCount: recordedFrames.count)
        
        // Schedule cleanup (delayed to allow video generation)
        scheduleCleanup()
    }
    
    func pauseRecording() {
        captureTimer?.invalidate()
        captureTimer = nil
        print("⏸️ Recording paused")
    }
    
    func resumeRecording() {
        guard isRecording else { return }
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: Config.captureInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureCurrentFrame()
            }
        }
        print("▶️ Recording resumed")
    }
    
    // MARK: - Memory-Optimized Frame Capture
    private func captureCurrentFrame() {
        guard isRecording else { return }
        
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            let currentTime = Date().timeIntervalSince(recordingStartTime ?? Date())
            
            // Check max duration
            if currentTime >= Config.maxRecordingDuration {
                stopRecording()
                return
            }
            
            // Update progress
            recordingProgress = currentTime / Config.maxRecordingDuration
            frameCount = frameCounter
            
            // Store frame timestamp for later rendering
            frameCaptureTimes.append(currentTime)
            frameCounter += 1
            
            // Request frame capture from canvas
            NotificationCenter.default.post(
                name: .optimizedVideoFrameCaptureRequested,
                object: nil,
                userInfo: [
                    "timestamp": currentTime,
                    "frameIndex": frameCounter
                ]
            )
        }
    }
    
    func captureFrame(image: UIImage, timestamp: TimeInterval) {
        guard isRecording, let _ = tempDirectory else { return }
        
        // Process frame on background queue to avoid blocking UI
        let frameIndex = frameCounter
        backgroundQueue.async { [weak self] in
            Task { @MainActor in
                self?.processAndSaveFrame(image: image, timestamp: timestamp, frameIndex: frameIndex)
            }
        }
    }
    
    private func processAndSaveFrame(image: UIImage, timestamp: TimeInterval, frameIndex: Int) {
        guard let tempDirectory = tempDirectory else { return }
        
        // ENHANCED: Use autoreleasepool for immediate memory release
        autoreleasepool {
            // Generate unique file path
            let fileName = "\(Config.frameFilePrefix)_\(String(format: "%06d", frameIndex)).\(Config.frameFileExtension)"
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            // Resize image if needed (optimize for target video size)
            let optimizedImage = resizeImageForVideo(image)
            
            // Convert to JPEG data with compression
            guard let imageData = optimizedImage.jpegData(compressionQuality: Config.frameCompressionQuality) else {
                print("❌ Failed to convert frame \(frameIndex) to JPEG data")
                return
            }
            
            // Write to disk
            do {
                try imageData.write(to: fileURL)
                
                // Create disk-based frame reference
                let diskFrame = DiskBasedFrame(
                    fileURL: fileURL,
                    timestamp: timestamp,
                    frameIndex: frameIndex,
                    fileSizeBytes: imageData.count
                )
                
                // Update arrays on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.recordedFrames.append(diskFrame)
                    self?.updateStorageEstimates()
                }
                
                print("💾 Saved frame \(frameIndex) to disk (\(imageData.count) bytes)")
                
            } catch {
                print("❌ Failed to write frame \(frameIndex) to disk: \(error)")
            }
        }
    }
    
    // MARK: - Image Optimization
    private func resizeImageForVideo(_ image: UIImage) -> UIImage {
        // ENHANCED: Use autoreleasepool for immediate memory release
        return autoreleasepool {
            let targetSize = Config.outputVideoSize
            let originalSize = image.size
            
            // Calculate scale factor maintaining aspect ratio
            let widthScale = targetSize.width / originalSize.width
            let heightScale = targetSize.height / originalSize.height
            let scale = min(widthScale, heightScale)
            
            let newSize = CGSize(
                width: originalSize.width * scale,
                height: originalSize.height * scale
            )
            
            // Use UIGraphicsImageRenderer for better performance
            let renderer = UIGraphicsImageRenderer(size: newSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
    }
    
    // MARK: - Memory-Optimized Video Generation
    func generateTimelapseVideo(
        speedMultiplier: Float = Config.timelapseSpeedMultiplier,
        includeWatermark: Bool = true,
        watermarkText: String? = nil,
        completion: @escaping (Result<URL, VideoGenerationError>) -> Void
    ) {
        guard !recordedFrames.isEmpty else {
            completion(.failure(.noFramesRecorded))
            return
        }
        
        isProcessing = true
        processingProgress = 0.0
        
        Task {
            do {
                let videoURL = try await createOptimizedTimelapseVideo(
                    frames: recordedFrames,
                    speedMultiplier: speedMultiplier,
                    includeWatermark: includeWatermark,
                    watermarkText: watermarkText
                )
                
                await MainActor.run {
                    isProcessing = false
                    completion(.success(videoURL))
                }
                
                // Track successful generation
                trackVideoGeneration(success: true, frameCount: recordedFrames.count)
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    completion(.failure(.processingFailed(error)))
                }
                
                // Track failed generation
                trackVideoGeneration(success: false, frameCount: recordedFrames.count)
                
                print("❌ Video generation failed: \(error)")
            }
        }
    }
    
    private func createOptimizedTimelapseVideo(
        frames: [DiskBasedFrame],
        speedMultiplier: Float,
        includeWatermark: Bool,
        watermarkText: String?
    ) async throws -> URL {
        
        // Create output file URL
        let outputURL = createTemporaryVideoURL()
        
        // Setup AVAssetWriter
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // Optimized video settings for social media
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(Config.outputVideoSize.width),
            AVVideoHeightKey: Int(Config.outputVideoSize.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 8_000_000, // 8 Mbps for high quality
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoH264EntropyModeKey: AVVideoH264EntropyModeCABAC,
                AVVideoExpectedSourceFrameRateKey: Config.targetFrameRate
            ]
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = false
        
        // Pixel buffer adaptor for efficient conversion
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(Config.outputVideoSize.width),
                kCVPixelBufferHeightKey as String: Int(Config.outputVideoSize.height)
            ]
        )
        
        guard videoWriter.canAdd(videoInput) else {
            throw VideoGenerationError.setupFailed("Cannot add video input")
        }
        
        videoWriter.add(videoInput)
        
        // Start writing session
        guard videoWriter.startWriting() else {
            throw VideoGenerationError.setupFailed("Failed to start writing")
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Calculate frame timing
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(Float(Config.targetFrameRate) * speedMultiplier))
        var frameTime = CMTime.zero
        
        // Process frames one by one (streaming from disk)
        for (index, frame) in frames.enumerated() {
            
            // Update progress
            await MainActor.run {
                processingProgress = Double(index) / Double(frames.count)
            }
            
            // Wait for video input to be ready
            while !videoInput.isReadyForMoreMediaData {
                await Task.yield()
            }
            
            // Load image from disk (only one frame in memory at a time)
            guard let imageData = try? Data(contentsOf: frame.fileURL),
                  let frameImage = UIImage(data: imageData) else {
                print("⚠️ Skipping corrupted frame: \(frame.fileURL.lastPathComponent)")
                continue
            }
            
            // Process frame (resize, watermark if needed)
            let processedImage = await processFrameForVideo(
                frameImage,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
            
            // Convert to pixel buffer
            if let pixelBuffer = createPixelBuffer(from: processedImage, size: Config.outputVideoSize) {
                pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: frameTime)
            }
            
            frameTime = CMTimeAdd(frameTime, frameDuration)
        }
        
        // Finish writing
        videoInput.markAsFinished()
        await videoWriter.finishWriting()
        
        guard videoWriter.status == .completed else {
            if let error = videoWriter.error {
                throw VideoGenerationError.processingFailed(error)
            } else {
                throw VideoGenerationError.processingFailed(NSError(domain: "VideoGeneration", code: -1))
            }
        }
        
        print("✅ Generated optimized video: \(outputURL.path)")
        return outputURL
    }
    
    // MARK: - Video Processing Helpers
    private func processFrameForVideo(
        _ image: UIImage,
        includeWatermark: Bool,
        watermarkText: String?
    ) async -> UIImage {
        
        // Resize to target video size if needed
        let resizedImage = resizeImageForVideo(image)
        
        // Add watermark if required
        if includeWatermark {
            return await addWatermark(to: resizedImage, text: watermarkText)
        }
        
        return resizedImage
    }
    
    private func addWatermark(to image: UIImage, text: String?) async -> UIImage {
        let watermarkText = text ?? "Created with SketchAI"
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let renderer = UIGraphicsImageRenderer(size: image.size)
                let watermarkedImage = renderer.image { context in
                    // Draw original image
                    image.draw(at: .zero)
                    
                    // Setup watermark attributes
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                        .strokeColor: UIColor.black.withAlphaComponent(0.5),
                        .strokeWidth: -2
                    ]
                    
                    // Calculate watermark position (bottom right)
                    let textSize = watermarkText.size(withAttributes: attributes)
                    let margin: CGFloat = 20
                    let textRect = CGRect(
                        x: image.size.width - textSize.width - margin,
                        y: image.size.height - textSize.height - margin,
                        width: textSize.width,
                        height: textSize.height
                    )
                    
                    // Draw watermark
                    watermarkText.draw(in: textRect, withAttributes: attributes)
                }
                
                continuation.resume(returning: watermarkedImage)
            }
        }
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
    
    // MARK: - Memory Management
    private func startMemoryMonitoring() {
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMemoryUsage()
            }
        }
    }
    
    private func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        
        if memoryUsage > Config.maxMemoryUsageMB {
            handleMemoryPressure()
        }
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / 1024 / 1024 // Convert to MB
        }
        
        return 0
    }
    
    private func handleMemoryPressure() {
        let now = Date()
        
        // Throttle memory warnings
        if let lastWarning = lastMemoryWarning,
           now.timeIntervalSince(lastWarning) < 10.0 {
            return
        }
        
        lastMemoryWarning = now
        
        print("⚠️ Memory pressure detected - optimizing...")
        
        // ENHANCED: Force garbage collection with immediate cleanup
        autoreleasepool {
            // Clear any pending frames
            recordedFrames.removeAll()
            
            // Clear temporary files
            cleanupTempDirectory()
        }
        
        // Notify about memory pressure
        NotificationCenter.default.post(name: .memoryPressureDetected, object: nil)
    }
    
    // ENHANCED: Emergency cleanup for critical memory pressure
    func performEmergencyCleanup() {
        autoreleasepool {
            // Stop recording immediately
            if isRecording {
                stopRecording()
            }
            
            // Clear all recorded frames
            recordedFrames.removeAll()
            
            // Clear temporary files
            cleanupTempDirectory()
        }
        
        print("🚨 [VideoRecordingEngine] Emergency cleanup performed")
    }
    
    // MARK: - Storage Management
    private func updateStorageEstimates() {
        let totalBytes = recordedFrames.reduce(0) { $0 + $1.fileSizeBytes }
        estimatedFileSize = ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    private func createTemporaryVideoURL() -> URL {
        let fileName = "SketchAI_Timelapse_\(Date().timeIntervalSince1970).mp4"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }
    
    private func scheduleCleanup() {
        DispatchQueue.global().asyncAfter(deadline: .now() + Config.diskCleanupDelay) { [weak self] in
            Task { @MainActor in
                self?.cleanupTempDirectory()
            }
        }
    }
    
    private func cleanupTempDirectory() {
        guard let tempDirectory = tempDirectory else { return }
        
        do {
            try FileManager.default.removeItem(at: tempDirectory)
            print("🗑️ Cleaned up temp directory: \(tempDirectory.path)")
        } catch {
            print("❌ Failed to cleanup temp directory: \(error)")
        }
        
        self.tempDirectory = nil
    }
    
    private func cleanupAllResources() {
        captureTimer?.invalidate()
        memoryMonitorTimer?.invalidate()
        cleanupTempDirectory()
        cancellables.removeAll()
    }
    
    // MARK: - Notifications Setup
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryPressure()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.cleanupAllResources()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Analytics and Tracking
    private func trackRecordingStart() {
        let event = [
            "event": "video_recording_start",
            "canvas_size": "\(canvasSize.width)x\(canvasSize.height)",
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        print("📊 Recording Start: \(event)")
        // Integrate with analytics service
    }
    
    private func trackRecordingStop(duration: TimeInterval, frameCount: Int) {
        let event = [
            "event": "video_recording_stop",
            "duration": duration,
            "frame_count": frameCount,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        print("📊 Recording Stop: \(event)")
        // Integrate with analytics service
    }
    
    private func trackVideoGeneration(success: Bool, frameCount: Int) {
        let event = [
            "event": "video_generation",
            "success": success,
            "frame_count": frameCount,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        print("📊 Video Generation: \(event)")
        // Integrate with analytics service
    }
}

// MARK: - Supporting Data Structures

struct DiskBasedFrame {
    let fileURL: URL
    let timestamp: TimeInterval
    let frameIndex: Int
    let fileSizeBytes: Int
}

// MARK: - Notification Extensions
extension NSNotification.Name {
    static let optimizedVideoFrameCaptureRequested = NSNotification.Name("OptimizedVideoFrameCaptureRequested")
    static let memoryPressureDetected = NSNotification.Name("MemoryPressureDetected")
}

// MARK: - Error Types
enum VideoGenerationError: Error, LocalizedError {
    case noFramesRecorded
    case setupFailed(String)
    case processingFailed(Error)
    case insufficientDiskSpace
    case outputLocationNotAccessible
    
    var errorDescription: String? {
        switch self {
        case .noFramesRecorded:
            return "No frames were recorded for video generation"
        case .setupFailed(let message):
            return "Video setup failed: \(message)"
        case .processingFailed(let error):
            return "Video processing failed: \(error.localizedDescription)"
        case .insufficientDiskSpace:
            return "Insufficient disk space for video generation"
        case .outputLocationNotAccessible:
            return "Cannot access output location for video file"
        }
    }
}
