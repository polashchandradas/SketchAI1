import Foundation
import SwiftUI
import PencilKit
import CoreGraphics
import UIKit
import AVFoundation
import Photos

// MARK: - Export Service
@MainActor
class ExportService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var currentExportStep: String = ""
    @Published var exportError: ExportError?
    
    // MARK: - Configuration
    private struct Config {
        static let highResImageSize = CGSize(width: 2048, height: 2048)
        static let storyImageSize = CGSize(width: 1080, height: 1920) // 9:16 aspect ratio
        static let watermarkFontSize: CGFloat = 24
        static let watermarkOpacity: CGFloat = 0.7
        static let watermarkMargin: CGFloat = 20
        static let imageCompressionQuality: CGFloat = 0.9
        static let videoFrameRate: Int = 30
        static let videoBitRate: Int = 5000000 // 5 Mbps
    }
    
    // MARK: - Export Methods
    
    func exportImage(
        from canvasView: PKCanvasView?,
        drawing: UserDrawing?,
        format: ExportFormat,
        includeWatermark: Bool,
        watermarkText: String = "SketchAI"
    ) async -> Result<UIImage, ExportError> {
        
        isExporting = true
        exportProgress = 0.0
        currentExportStep = "Preparing image..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentExportStep = ""
        }
        
        return await Task.detached {
            return await self.processImageExport(
                canvasView: canvasView,
                drawing: drawing,
                format: format,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    func exportTimelapse(
        from drawing: UserDrawing,
        includeWatermark: Bool,
        watermarkText: String = "SketchAI"
    ) async -> Result<URL, ExportError> {
        
        isExporting = true
        exportProgress = 0.0
        currentExportStep = "Creating timelapse video..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentExportStep = ""
        }
        
        return await Task.detached {
            return await self.processTimelapseExport(
                drawing: drawing,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    func exportBeforeAfter(
        originalImage: UIImage,
        finalImage: UIImage,
        format: ExportFormat,
        includeWatermark: Bool,
        watermarkText: String = "SketchAI"
    ) async -> Result<UIImage, ExportError> {
        
        isExporting = true
        exportProgress = 0.0
        currentExportStep = "Creating before/after comparison..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentExportStep = ""
        }
        
        return await Task.detached {
            return await self.processBeforeAfterExport(
                originalImage: originalImage,
                finalImage: finalImage,
                format: format,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    func exportStory(
        from canvasView: PKCanvasView?,
        drawing: UserDrawing?,
        includeWatermark: Bool,
        watermarkText: String = "SketchAI"
    ) async -> Result<UIImage, ExportError> {
        
        isExporting = true
        exportProgress = 0.0
        currentExportStep = "Creating story format..."
        
        defer {
            isExporting = false
            exportProgress = 0.0
            currentExportStep = ""
        }
        
        return await Task.detached {
            return await self.processStoryExport(
                canvasView: canvasView,
                drawing: drawing,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    // MARK: - Save to Photos
    
    func saveToPhotos(_ image: UIImage) async -> Result<Void, ExportError> {
        return await Task.detached {
            return await self.saveImageToPhotos(image)
        }.value
    }
    
    func saveVideoToPhotos(_ videoURL: URL) async -> Result<Void, ExportError> {
        return await Task.detached {
            return await self.saveVideoToPhotosInternal(videoURL)
        }.value
    }
    
    // MARK: - Share Sheet
    
    func createShareSheet(for image: UIImage) -> UIActivityViewController {
        let shareText = "Check out my drawing created with SketchAI! 🎨✨"
        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        return activityVC
    }
    
    func createShareSheet(for videoURL: URL) -> UIActivityViewController {
        let shareText = "Check out my drawing timelapse created with SketchAI! 🎨✨"
        let activityVC = UIActivityViewController(
            activityItems: [videoURL, shareText],
            applicationActivities: nil
        )
        return activityVC
    }
    
    // MARK: - Private Processing Methods
    
    private func processImageExport(
        canvasView: PKCanvasView?,
        drawing: UserDrawing?,
        format: ExportFormat,
        includeWatermark: Bool,
        watermarkText: String
    ) async -> Result<UIImage, ExportError> {
        
        // Step 1: Get the source image
        guard let sourceImage = await getSourceImage(canvasView: canvasView, drawing: drawing) else {
            return .failure(.noImageData)
        }
        
        await updateProgress(0.3, "Processing image...")
        
        // Step 2: Resize image based on format
        let targetSize = format == .story ? Config.storyImageSize : Config.highResImageSize
        guard let resizedImage = await resizeImage(sourceImage, to: targetSize) else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(0.6, "Applying watermark...")
        
        // Step 3: Add watermark if needed
        let finalImage = includeWatermark ? 
            await addWatermark(to: resizedImage, text: watermarkText) : 
            resizedImage
        
        guard let finalImage = finalImage else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(1.0, "Export complete!")
        
        return .success(finalImage)
    }
    
    private func processTimelapseExport(
        drawing: UserDrawing,
        includeWatermark: Bool,
        watermarkText: String
    ) async -> Result<URL, ExportError> {
        
        // Check if we have timelapse data
        guard let timelapseData = drawing.timelapseData else {
            return .failure(.noTimelapseData)
        }
        
        await updateProgress(0.2, "Processing timelapse data...")
        
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("timelapse_\(UUID().uuidString).mp4")
        
        do {
            try timelapseData.write(to: tempURL)
            await updateProgress(0.5, "Creating video...")
            
            // If watermark is needed, we'd need to process the video
            // For now, we'll return the basic timelapse
            if includeWatermark {
                // TODO: Implement video watermarking
                await updateProgress(0.8, "Adding watermark...")
            }
            
            await updateProgress(1.0, "Timelapse complete!")
            return .success(tempURL)
            
        } catch {
            return .failure(.fileWriteFailed)
        }
    }
    
    private func processBeforeAfterExport(
        originalImage: UIImage,
        finalImage: UIImage,
        format: ExportFormat,
        includeWatermark: Bool,
        watermarkText: String
    ) async -> Result<UIImage, ExportError> {
        
        await updateProgress(0.2, "Preparing images...")
        
        // Resize images to match
        let targetSize = format == .story ? Config.storyImageSize : Config.highResImageSize
        guard let resizedOriginal = await resizeImage(originalImage, to: targetSize),
              let resizedFinal = await resizeImage(finalImage, to: targetSize) else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(0.5, "Creating comparison...")
        
        // Create side-by-side comparison
        guard let comparisonImage = await createSideBySideComparison(
            before: resizedOriginal,
            after: resizedFinal
        ) else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(0.8, "Applying watermark...")
        
        // Add watermark if needed
        let finalImage = includeWatermark ? 
            await addWatermark(to: comparisonImage, text: watermarkText) : 
            comparisonImage
        
        guard let finalImage = finalImage else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(1.0, "Export complete!")
        
        return .success(finalImage)
    }
    
    private func processStoryExport(
        canvasView: PKCanvasView?,
        drawing: UserDrawing?,
        includeWatermark: Bool,
        watermarkText: String
    ) async -> Result<UIImage, ExportError> {
        
        // Get source image
        guard let sourceImage = await getSourceImage(canvasView: canvasView, drawing: drawing) else {
            return .failure(.noImageData)
        }
        
        await updateProgress(0.3, "Creating story format...")
        
        // Create story-optimized image with background and text
        guard let storyImage = await createStoryFormat(
            image: sourceImage,
            includeWatermark: includeWatermark,
            watermarkText: watermarkText
        ) else {
            return .failure(.imageProcessingFailed)
        }
        
        await updateProgress(1.0, "Story format complete!")
        
        return .success(storyImage)
    }
    
    // MARK: - Helper Methods
    
    private func getSourceImage(canvasView: PKCanvasView?, drawing: UserDrawing?) async -> UIImage? {
        if let canvasView = canvasView {
            return await getImageFromCanvas(canvasView)
        } else if let drawing = drawing {
            return UIImage(data: drawing.imageData)
        }
        return nil
    }
    
    private func getImageFromCanvas(_ canvasView: PKCanvasView) async -> UIImage? {
        return await Task.detached {
            let bounds = canvasView.bounds
            
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            return renderer.image { context in
                // Fill with white background
                UIColor.white.setFill()
                context.fill(bounds)
                
                // Draw the canvas view hierarchy (includes PencilKit drawing)
                canvasView.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
        }.value
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) async -> UIImage? {
        return await Task.detached {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }.value
    }
    
    private func addWatermark(to image: UIImage, text: String) async -> UIImage? {
        return await Task.detached {
            let renderer = UIGraphicsImageRenderer(size: image.size)
            return renderer.image { context in
                // Draw original image
                image.draw(in: CGRect(origin: .zero, size: image.size))
                
                // Add watermark
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: Config.watermarkFontSize, weight: .medium),
                    .foregroundColor: UIColor.white.withAlphaComponent(Config.watermarkOpacity),
                    .strokeColor: UIColor.black.withAlphaComponent(Config.watermarkOpacity),
                    .strokeWidth: -2
                ]
                
                let attributedString = NSAttributedString(string: text, attributes: attributes)
                let textSize = attributedString.size()
                
                let textRect = CGRect(
                    x: image.size.width - textSize.width - Config.watermarkMargin,
                    y: image.size.height - textSize.height - Config.watermarkMargin,
                    width: textSize.width,
                    height: textSize.height
                )
                
                attributedString.draw(in: textRect)
            }
        }.value
    }
    
    private func createSideBySideComparison(before: UIImage, after: UIImage) async -> UIImage? {
        return await Task.detached {
            let totalWidth = before.size.width + after.size.width
            let maxHeight = max(before.size.height, after.size.height)
            let size = CGSize(width: totalWidth, height: maxHeight)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                // Fill with white background
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                
                // Draw before image on the left
                before.draw(in: CGRect(
                    x: 0,
                    y: (maxHeight - before.size.height) / 2,
                    width: before.size.width,
                    height: before.size.height
                ))
                
                // Draw after image on the right
                after.draw(in: CGRect(
                    x: before.size.width,
                    y: (maxHeight - after.size.height) / 2,
                    width: after.size.width,
                    height: after.size.height
                ))
            }
        }.value
    }
    
    private func createStoryFormat(image: UIImage, includeWatermark: Bool, watermarkText: String) async -> UIImage? {
        return await Task.detached {
            let storySize = Config.storyImageSize
            let renderer = UIGraphicsImageRenderer(size: storySize)
            
            return renderer.image { context in
                // Fill with gradient background
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [
                        UIColor.systemBlue.cgColor,
                        UIColor.systemPurple.cgColor
                    ] as CFArray,
                    locations: [0.0, 1.0]
                )!
                
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 0, y: storySize.height),
                    options: []
                )
                
                // Calculate image size to fit in story format
                let imageAspectRatio = image.size.width / image.size.height
                let storyAspectRatio = storySize.width / storySize.height
                
                let imageSize: CGSize
                if imageAspectRatio > storyAspectRatio {
                    // Image is wider, fit by width
                    imageSize = CGSize(
                        width: storySize.width * 0.8,
                        height: storySize.width * 0.8 / imageAspectRatio
                    )
                } else {
                    // Image is taller, fit by height
                    imageSize = CGSize(
                        width: storySize.height * 0.8 * imageAspectRatio,
                        height: storySize.height * 0.8
                    )
                }
                
                let imageRect = CGRect(
                    x: (storySize.width - imageSize.width) / 2,
                    y: (storySize.height - imageSize.height) / 2,
                    width: imageSize.width,
                    height: imageSize.height
                )
                
                // Draw image with rounded corners
                let path = UIBezierPath(roundedRect: imageRect, cornerRadius: 20)
                context.cgContext.addPath(path.cgPath)
                context.cgContext.clip()
                
                image.draw(in: imageRect)
                
                // Add title text
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                    .foregroundColor: UIColor.white,
                    .strokeColor: UIColor.black,
                    .strokeWidth: -2
                ]
                
                let titleText = "My SketchAI Creation"
                let titleAttributedString = NSAttributedString(string: titleText, attributes: titleAttributes)
                let titleSize = titleAttributedString.size()
                
                let titleRect = CGRect(
                    x: (storySize.width - titleSize.width) / 2,
                    y: 100,
                    width: titleSize.width,
                    height: titleSize.height
                )
                
                titleAttributedString.draw(in: titleRect)
                
                // Add watermark if needed
                if includeWatermark {
                    let watermarkAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.8)
                    ]
                    
                    let watermarkAttributedString = NSAttributedString(string: watermarkText, attributes: watermarkAttributes)
                    let watermarkSize = watermarkAttributedString.size()
                    
                    let watermarkRect = CGRect(
                        x: (storySize.width - watermarkSize.width) / 2,
                        y: storySize.height - watermarkSize.height - 50,
                        width: watermarkSize.width,
                        height: watermarkSize.height
                    )
                    
                    watermarkAttributedString.draw(in: watermarkRect)
                }
            }
        }.value
    }
    
    private func saveImageToPhotos(_ image: UIImage) async -> Result<Void, ExportError> {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume(returning: .failure(.photoLibraryAccessDenied))
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if success {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.photoLibrarySaveFailed))
                    }
                }
            }
        }
    }
    
    private func saveVideoToPhotosInternal(_ videoURL: URL) async -> Result<Void, ExportError> {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    continuation.resume(returning: .failure(.photoLibraryAccessDenied))
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { success, error in
                    if success {
                        continuation.resume(returning: .success(()))
                    } else {
                        continuation.resume(returning: .failure(.photoLibrarySaveFailed))
                    }
                }
            }
        }
    }
    
    private func updateProgress(_ progress: Double, _ step: String) async {
        await MainActor.run {
            self.exportProgress = progress
            self.currentExportStep = step
        }
    }
}

// MARK: - Supporting Types

enum ExportFormat: String, CaseIterable {
    case image = "High-Res Image"
    case timelapse = "Time-lapse Video"
    case beforeAfter = "Before & After"
    case story = "Story Format"
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .timelapse: return "video"
        case .beforeAfter: return "rectangle.split.2x1"
        case .story: return "rectangle.portrait"
        }
    }
    
    var description: String {
        switch self {
        case .image: return "Export as a high-resolution image"
        case .timelapse: return "Create a time-lapse of your drawing process"
        case .beforeAfter: return "Show original reference and your drawing side-by-side"
        case .story: return "Vertical format perfect for Instagram Stories"
        }
    }
}

enum ExportError: LocalizedError {
    case noImageData
    case noTimelapseData
    case imageProcessingFailed
    case fileWriteFailed
    case photoLibraryAccessDenied
    case photoLibrarySaveFailed
    case videoProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noImageData:
            return "No image data available for export"
        case .noTimelapseData:
            return "No timelapse data available for export"
        case .imageProcessingFailed:
            return "Failed to process image for export"
        case .fileWriteFailed:
            return "Failed to write file to disk"
        case .photoLibraryAccessDenied:
            return "Photo library access denied"
        case .photoLibrarySaveFailed:
            return "Failed to save to photo library"
        case .videoProcessingFailed:
            return "Failed to process video for export"
        }
    }
}
