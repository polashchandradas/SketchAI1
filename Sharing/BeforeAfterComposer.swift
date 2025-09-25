import Foundation
import SwiftUI
import CoreGraphics
import UIKit

// MARK: - Before/After Image Composer
@MainActor
class BeforeAfterComposer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    
    // MARK: - Configuration
    private struct Config {
        static let outputSize = CGSize(width: 1080, height: 1920) // 9:16 TikTok format
        static let transitionFrames = 30 // For smooth animation
        static let sliderWidth: CGFloat = 4.0
        static let sliderColor = UIColor.white
        static let shadowOpacity: CGFloat = 0.3
    }
    
    // MARK: - Before/After Comparison Generation
    
    func createSideBySideComparison(
        beforeImage: UIImage,
        afterImage: UIImage,
        includeWatermark: Bool = true,
        watermarkText: String? = nil
    ) async -> Result<UIImage, ComposerError> {
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        return await Task.detached {
            return await self.generateSideBySideImage(
                before: beforeImage,
                after: afterImage,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    func createSliderComparison(
        beforeImage: UIImage,
        afterImage: UIImage,
        sliderPosition: CGFloat = 0.5, // 0.0 = full before, 1.0 = full after
        includeWatermark: Bool = true,
        watermarkText: String? = nil
    ) async -> Result<UIImage, ComposerError> {
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        return await Task.detached {
            return await self.generateSliderImage(
                before: beforeImage,
                after: afterImage,
                sliderPosition: sliderPosition,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    func createTransitionAnimation(
        beforeImage: UIImage,
        afterImage: UIImage,
        transitionType: TransitionType = .crossfade,
        includeWatermark: Bool = true,
        watermarkText: String? = nil
    ) async -> Result<[UIImage], ComposerError> {
        
        isProcessing = true
        processingProgress = 0.0
        
        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
        
        return await Task.detached {
            return await self.generateTransitionFrames(
                before: beforeImage,
                after: afterImage,
                transitionType: transitionType,
                includeWatermark: includeWatermark,
                watermarkText: watermarkText
            )
        }.value
    }
    
    // MARK: - Side-by-Side Implementation
    
    private func generateSideBySideImage(
        before: UIImage,
        after: UIImage,
        includeWatermark: Bool,
        watermarkText: String?
    ) -> Result<UIImage, ComposerError> {
        
        processingProgress = 0.1
        
        // Prepare images
        guard let resizedBefore = resizeImageForComparison(before, side: .left),
              let resizedAfter = resizeImageForComparison(after, side: .right) else {
            return .failure(.imageProcessingFailed)
        }
        
        processingProgress = 0.3
        
        // Create composite image
        let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
        
        let compositeImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
            
            // Draw before image (left side)
            let beforeRect = CGRect(
                x: 0,
                y: 0,
                width: Config.outputSize.width / 2,
                height: Config.outputSize.height
            )
            resizedBefore.draw(in: beforeRect)
            
            // Draw after image (right side)
            let afterRect = CGRect(
                x: Config.outputSize.width / 2,
                y: 0,
                width: Config.outputSize.width / 2,
                height: Config.outputSize.height
            )
            resizedAfter.draw(in: afterRect)
            
            // Draw center divider line
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(2.0)
            cgContext.move(to: CGPoint(x: Config.outputSize.width / 2, y: 0))
            cgContext.addLine(to: CGPoint(x: Config.outputSize.width / 2, y: Config.outputSize.height))
            cgContext.strokePath()
            
            // Add labels
            drawLabel("BEFORE", in: beforeRect, context: cgContext)
            drawLabel("AFTER", in: afterRect, context: cgContext)
        }
        
        processingProgress = 0.8
        
        // Add watermark if needed
        let finalImage = includeWatermark ? 
            addWatermark(to: compositeImage, text: watermarkText) : 
            compositeImage
        
        processingProgress = 1.0
        
        return .success(finalImage)
    }
    
    // MARK: - Slider Comparison Implementation
    
    private func generateSliderImage(
        before: UIImage,
        after: UIImage,
        sliderPosition: CGFloat,
        includeWatermark: Bool,
        watermarkText: String?
    ) -> Result<UIImage, ComposerError> {
        
        processingProgress = 0.1
        
        // Resize images to fit container
        guard let resizedBefore = resizeImageToFit(before, in: Config.outputSize),
              let resizedAfter = resizeImageToFit(after, in: Config.outputSize) else {
            return .failure(.imageProcessingFailed)
        }
        
        processingProgress = 0.3
        
        let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
        
        let sliderImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
            
            // Calculate image positioning (centered)
            let imageRect = calculateCenteredRect(for: resizedBefore.size, in: Config.outputSize)
            
            // Draw before image (full)
            resizedBefore.draw(in: imageRect)
            
            // Create clipping path for after image based on slider position
            let sliderX = imageRect.minX + (imageRect.width * sliderPosition)
            
            cgContext.saveGState()
            
            // Clip to reveal after image only on the right side of slider
            let afterClipRect = CGRect(
                x: sliderX,
                y: imageRect.minY,
                width: imageRect.maxX - sliderX,
                height: imageRect.height
            )
            cgContext.clip(to: afterClipRect)
            
            // Draw after image (clipped)
            resizedAfter.draw(in: imageRect)
            
            cgContext.restoreGState()
            
            // Draw slider line
            drawSliderLine(at: sliderX, in: imageRect, context: cgContext)
        }
        
        processingProgress = 0.8
        
        // Add watermark if needed
        let finalImage = includeWatermark ? 
            addWatermark(to: sliderImage, text: watermarkText) : 
            sliderImage
        
        processingProgress = 1.0
        
        return .success(finalImage)
    }
    
    // MARK: - Transition Animation Implementation
    
    private func generateTransitionFrames(
        before: UIImage,
        after: UIImage,
        transitionType: TransitionType,
        includeWatermark: Bool,
        watermarkText: String?
    ) -> Result<[UIImage], ComposerError> {
        
        processingProgress = 0.1
        
        // Resize images
        guard let resizedBefore = resizeImageToFit(before, in: Config.outputSize),
              let resizedAfter = resizeImageToFit(after, in: Config.outputSize) else {
            return .failure(.imageProcessingFailed)
        }
        
        var frames: [UIImage] = []
        let totalFrames = Config.transitionFrames
        
        for i in 0...totalFrames {
            let progress = CGFloat(i) / CGFloat(totalFrames)
            
            let frame = generateTransitionFrame(
                before: resizedBefore,
                after: resizedAfter,
                progress: progress,
                transitionType: transitionType
            )
            
            // Add watermark if needed
            let finalFrame = includeWatermark ? 
                addWatermark(to: frame, text: watermarkText) : 
                frame
            
            frames.append(finalFrame)
            
            // Update progress
            processingProgress = 0.1 + (0.9 * Double(i) / Double(totalFrames))
        }
        
        return .success(frames)
    }
    
    private func generateTransitionFrame(
        before: UIImage,
        after: UIImage,
        progress: CGFloat,
        transitionType: TransitionType
    ) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: Config.outputSize)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill background
            cgContext.setFillColor(UIColor.systemBackground.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: Config.outputSize))
            
            let imageRect = calculateCenteredRect(for: before.size, in: Config.outputSize)
            
            switch transitionType {
            case .crossfade:
                // Draw before image with decreasing opacity
                cgContext.setAlpha(1.0 - progress)
                before.draw(in: imageRect)
                
                // Draw after image with increasing opacity
                cgContext.setAlpha(progress)
                after.draw(in: imageRect)
                
            case .slideLeft:
                let offsetX = imageRect.width * progress
                
                // Draw before image sliding out to the left
                let beforeRect = CGRect(
                    x: imageRect.minX - offsetX,
                    y: imageRect.minY,
                    width: imageRect.width,
                    height: imageRect.height
                )
                before.draw(in: beforeRect)
                
                // Draw after image sliding in from the right
                let afterRect = CGRect(
                    x: imageRect.minX + imageRect.width - offsetX,
                    y: imageRect.minY,
                    width: imageRect.width,
                    height: imageRect.height
                )
                after.draw(in: afterRect)
                
            case .reveal:
                // Similar to slider but animated
                before.draw(in: imageRect)
                
                cgContext.saveGState()
                
                let revealWidth = imageRect.width * progress
                let revealRect = CGRect(
                    x: imageRect.minX,
                    y: imageRect.minY,
                    width: revealWidth,
                    height: imageRect.height
                )
                cgContext.clip(to: revealRect)
                
                after.draw(in: imageRect)
                
                cgContext.restoreGState()
                
                // Draw reveal line
                if progress > 0 && progress < 1 {
                    drawSliderLine(at: imageRect.minX + revealWidth, in: imageRect, context: cgContext)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resizeImageForComparison(_ image: UIImage, side: ComparisonSide) -> UIImage? {
        let targetSize = CGSize(
            width: Config.outputSize.width / 2,
            height: Config.outputSize.height
        )
        
        return resizeImageToFit(image, in: targetSize)
    }
    
    private func resizeImageToFit(_ image: UIImage, in containerSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: containerSize)
        
        return renderer.image { context in
            // Fill background
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: containerSize))
            
            // Calculate aspect fit rect
            let aspectFitRect = calculateAspectFitRect(for: image.size, in: containerSize)
            image.draw(in: aspectFitRect)
        }
    }
    
    private func calculateAspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        var rect = CGRect.zero
        
        if imageAspect > containerAspect {
            // Image is wider - fit width
            rect.size.width = containerSize.width
            rect.size.height = containerSize.width / imageAspect
            rect.origin.x = 0
            rect.origin.y = (containerSize.height - rect.size.height) / 2
        } else {
            // Image is taller - fit height
            rect.size.height = containerSize.height
            rect.size.width = containerSize.height * imageAspect
            rect.origin.y = 0
            rect.origin.x = (containerSize.width - rect.size.width) / 2
        }
        
        return rect
    }
    
    private func calculateCenteredRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        return CGRect(
            x: (containerSize.width - imageSize.width) / 2,
            y: (containerSize.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
    }
    
    private func drawSliderLine(at x: CGFloat, in rect: CGRect, context: CGContext) {
        // Draw slider line with shadow effect
        context.saveGState()
        
        // Shadow
        context.setShadow(
            offset: CGSize(width: 2, height: 0),
            blur: 4,
            color: UIColor.black.withAlphaComponent(Config.shadowOpacity).cgColor
        )
        
        // Main line
        context.setStrokeColor(Config.sliderColor.cgColor)
        context.setLineWidth(Config.sliderWidth)
        context.move(to: CGPoint(x: x, y: rect.minY))
        context.addLine(to: CGPoint(x: x, y: rect.maxY))
        context.strokePath()
        
        // Slider handle (circle)
        let handleRadius: CGFloat = 12
        let handleRect = CGRect(
            x: x - handleRadius,
            y: rect.midY - handleRadius,
            width: handleRadius * 2,
            height: handleRadius * 2
        )
        
        context.setFillColor(Config.sliderColor.cgColor)
        context.fillEllipse(in: handleRect)
        
        context.restoreGState()
    }
    
    private func drawLabel(_ text: String, in rect: CGRect, context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.minY + 20,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedText.draw(in: textRect)
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

enum TransitionType: String, CaseIterable {
    case crossfade = "Crossfade"
    case slideLeft = "Slide Left"
    case reveal = "Reveal"
    
    var displayName: String {
        return rawValue
    }
}

enum ComparisonSide {
    case left
    case right
}

enum ComposerError: Error, LocalizedError {
    case imageProcessingFailed
    case unsupportedFormat
    case insufficientMemory
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process images for comparison."
        case .unsupportedFormat:
            return "Unsupported image format."
        case .insufficientMemory:
            return "Insufficient memory to process images."
        }
    }
}
