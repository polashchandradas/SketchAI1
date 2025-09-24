import SwiftUI
import UIKit

// MARK: - Image Asset Manager
// Handles loading and caching of reference images for lessons
@MainActor
class ImageAssetManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ImageAssetManager()
    
    // MARK: - Properties
    @Published var loadedImages: [String: UIImage] = [:]
    @Published var imageLoadingStates: [String: ImageLoadingState] = [:]
    
    private let imageCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    // MARK: - Configuration
    private struct Config {
        static let cacheLimit = 50 // Maximum cached images
        static let thumbnailSize = CGSize(width: 150, height: 150)
        static let referenceImageSize = CGSize(width: 800, height: 800)
        static let placeholderColor = UIColor.systemGray3
        static let compressionQuality: CGFloat = 0.8
    }
    
    enum ImageLoadingState {
        case notLoaded
        case loading
        case loaded(UIImage)
        case failed
        case placeholder(UIImage)
    }
    
    enum ImageType {
        case thumbnail
        case reference
        
        var suffix: String {
            switch self {
            case .thumbnail: return "_thumb"
            case .reference: return "_ref"
            }
        }
        
        var size: CGSize {
            switch self {
            case .thumbnail: return Config.thumbnailSize
            case .reference: return Config.referenceImageSize
            }
        }
    }
    
    private init() {
        setupImageCache()
        preloadCommonImages()
    }
    
    // MARK: - Cache Setup
    private func setupImageCache() {
        imageCache.countLimit = Config.cacheLimit
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // ENHANCED MEMORY OPTIMIZATION: Add comprehensive memory pressure monitoring
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMemoryPressure()
            }
        }
        
        // Add app lifecycle monitoring for proactive cleanup
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppBackgrounding()
            }
        }
    }
    
    // ENHANCED MEMORY OPTIMIZATION: Handle memory pressure by clearing cache
    private func handleMemoryPressure() {
        print("🧠 [ImageAssetManager] Memory pressure detected - clearing cache")
        imageCache.removeAllObjects()
        loadedImages.removeAll()
        imageLoadingStates.removeAll()
        loadingTasks.removeAll()
    }
    
    // ENHANCED MEMORY OPTIMIZATION: Proactive cleanup on app backgrounding
    private func handleAppBackgrounding() {
        print("📱 [ImageAssetManager] App backgrounding - performing proactive cleanup")
        // Clear non-essential cached images but keep frequently used ones
        let essentialImages = ["face_basic", "cube", "cat", "perspective"]
        let keysToRemove = loadedImages.keys.filter { key in
            !essentialImages.contains { essential in
                key.contains(essential)
            }
        }
        
        for key in keysToRemove {
            imageCache.removeObject(forKey: key as NSString)
            loadedImages.removeValue(forKey: key)
            imageLoadingStates.removeValue(forKey: key)
        }
        
        print("🧹 [ImageAssetManager] Removed \(keysToRemove.count) non-essential images from cache")
    }
    
    // MARK: - Public Interface
    
    /// Load image for a lesson with automatic fallback to placeholder
    func loadImage(for imageName: String, type: ImageType = .reference) async -> UIImage {
        let fullImageName = imageName + type.suffix
        
        print("🖼️ [ImageAssetManager] Loading image: \(fullImageName)")
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: fullImageName as NSString) {
            print("✅ [ImageAssetManager] Found cached image: \(fullImageName)")
            imageLoadingStates[fullImageName] = .loaded(cachedImage)
            return cachedImage
        }
        
        // Check if already loading
        if let existingTask = loadingTasks[fullImageName] {
            print("⏳ [ImageAssetManager] Image already loading: \(fullImageName)")
            return await existingTask.value ?? createPlaceholderImage(for: imageName, type: type)
        }
        
        // Start loading
        print("🔄 [ImageAssetManager] Starting to load image: \(fullImageName)")
        imageLoadingStates[fullImageName] = .loading
        
        let loadingTask = Task<UIImage?, Never> {
            // MEMORY OPTIMIZATION: Use autorelease pool for image loading
            return await withCheckedContinuation { continuation in
                Task<Void, Never> {
                        // Try to load from bundle
                        if let bundleImage = loadFromBundle(imageName: fullImageName) {
                            print("✅ [ImageAssetManager] Loaded from bundle: \(fullImageName)")
                            continuation.resume(returning: bundleImage)
                            return
                        }
                        
                        // Try to load from documents directory (user-added images)
                        if let documentsImage = await loadFromDocuments(imageName: fullImageName) {
                            print("✅ [ImageAssetManager] Loaded from documents: \(fullImageName)")
                            continuation.resume(returning: documentsImage)
                            return
                        }
                        
                        // Try to generate procedural image for basic shapes
                        if let proceduralImage = generateProceduralImage(for: imageName, type: type) {
                            print("✅ [ImageAssetManager] Generated procedural image: \(fullImageName)")
                            continuation.resume(returning: proceduralImage)
                            return
                        }
                        
                        print("❌ [ImageAssetManager] Failed to load or generate image: \(fullImageName)")
                        continuation.resume(returning: nil)
                    }
            }
        }
        
        loadingTasks[fullImageName] = loadingTask
        
        if let image = await loadingTask.value {
            // Cache the loaded image
            imageCache.setObject(image, forKey: fullImageName as NSString)
            
            imageLoadingStates[fullImageName] = .loaded(image)
            loadedImages[fullImageName] = image
            
            loadingTasks.removeValue(forKey: fullImageName)
            print("✅ [ImageAssetManager] Successfully loaded and cached: \(fullImageName)")
            return image
        } else {
            // Create placeholder
            let placeholder = createPlaceholderImage(for: imageName, type: type)
            
            imageLoadingStates[fullImageName] = .placeholder(placeholder)
            
            loadingTasks.removeValue(forKey: fullImageName)
            print("⚠️ [ImageAssetManager] Created placeholder for: \(fullImageName)")
            return placeholder
        }
    }
    
    /// Synchronous method for SwiftUI Image views
    func getImage(for imageName: String, type: ImageType = .reference) -> UIImage {
        let fullImageName = imageName + type.suffix
        
        if let cachedImage = imageCache.object(forKey: fullImageName as NSString) {
            return cachedImage
        }
        
        if let bundleImage = loadFromBundle(imageName: fullImageName) {
            imageCache.setObject(bundleImage, forKey: fullImageName as NSString)
            return bundleImage
        }
        
        return createPlaceholderImage(for: imageName, type: type)
    }
    
    // MARK: - Loading Methods
    
    private func loadFromBundle(imageName: String) -> UIImage? {
        // Try different bundle locations
        let possiblePaths = [
            imageName,
            "ReferenceImages/\(imageName)",
            "Assets/ReferenceImages/\(imageName)",
            "Images/\(imageName)"
        ]
        
        for path in possiblePaths {
            if let image = UIImage(named: path) {
                print("✅ [ImageAssetManager] Successfully loaded image: \(path)")
                // ENHANCED: Apply downsampling for large images to reduce memory usage
                return downsampleImageIfNeeded(image, for: imageName)
            }
        }
        
        print("⚠️ [ImageAssetManager] Image not found in bundle: \(imageName)")
        return nil
    }
    
    // ENHANCED: Image downsampling based on research best practices
    private func downsampleImageIfNeeded(_ image: UIImage, for imageName: String) -> UIImage {
        let maxDimension: CGFloat = 1024 // Maximum dimension for reference images
        
        // Check if image needs downsampling
        let imageSize = image.size
        let maxSize = max(imageSize.width, imageSize.height)
        
        if maxSize <= maxDimension {
            return image // No downsampling needed
        }
        
        // Calculate new size maintaining aspect ratio
        let scale = maxDimension / maxSize
        let newSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Use UIGraphicsImageRenderer for efficient downsampling
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let downsampledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        print("📐 [ImageAssetManager] Downsampled \(imageName) from \(imageSize) to \(newSize)")
        return downsampledImage
    }
    
    private func loadFromDocuments(imageName: String) async -> UIImage? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let imageURL = documentsDirectory
            .appendingPathComponent("ReferenceImages")
            .appendingPathComponent(imageName + ".png")
        
        guard fileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }
        
        return UIImage(contentsOfFile: imageURL.path)
    }
    
    // MARK: - Procedural Image Generation
    
    private func generateProceduralImage(for imageName: String, type: ImageType) -> UIImage? {
        let baseName = imageName.replacingOccurrences(of: "_thumb", with: "").replacingOccurrences(of: "_ref", with: "")
        
        print("🎨 [ImageAssetManager] Generating procedural image for: \(baseName)")
        
        switch baseName {
        // Face category
        case "face_basic":
            print("🎨 [ImageAssetManager] Generating basic face image")
            return generateBasicFaceImage(size: type.size)
        case "face_loomis":
            print("🎨 [ImageAssetManager] Generating Loomis method image")
            return generateLoomisMethodImage(size: type.size)
        case "face_eyes":
            print("🎨 [ImageAssetManager] Generating eye study image")
            return generateEyeStudyImage(size: type.size)
            
        // Animal category
        case "animal_cat":
            print("🎨 [ImageAssetManager] Generating cat face image")
            return generateCatFaceImage(size: type.size)
        case "animal_dog":
            print("🎨 [ImageAssetManager] Generating dog portrait image")
            return generateDogPortraitImage(size: type.size)
        case "animal_bird":
            print("🎨 [ImageAssetManager] Generating bird flight image")
            return generateBirdFlightImage(size: type.size)
            
        // Object category
        case "object_cube":
            print("🎨 [ImageAssetManager] Generating cube image")
            return generateCubeImage(size: type.size)
        case "object_apple":
            print("🎨 [ImageAssetManager] Generating apple still life image")
            return generateAppleStillLifeImage(size: type.size)
            
        // Hand category
        case "hand_basic":
            print("🎨 [ImageAssetManager] Generating hand structure image")
            return generateHandStructureImage(size: type.size)
            
        // Perspective category
        case "perspective_basic":
            print("🎨 [ImageAssetManager] Generating perspective image")
            return generatePerspectiveImage(size: type.size)
            
        // Legacy fallbacks
        case "cube":
            print("🎨 [ImageAssetManager] Generating legacy cube image")
            return generateCubeImage(size: type.size)
        case "circle_basic":
            print("🎨 [ImageAssetManager] Generating legacy circle image")
            return generateCircleImage(size: type.size)
        case "perspective":
            print("🎨 [ImageAssetManager] Generating legacy perspective image")
            return generatePerspectiveImage(size: type.size)
            
        default:
            print("❌ [ImageAssetManager] No procedural generator found for: \(baseName)")
            return nil
        }
    }
    
    private func generateCubeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            // Cube drawing
            let cubeSize: CGFloat = min(size.width, size.height) * 0.6
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Front face
            let frontRect = CGRect(
                x: centerX - cubeSize/2,
                y: centerY - cubeSize/2,
                width: cubeSize,
                height: cubeSize
            )
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            context.cgContext.stroke(frontRect)
            
            // Top face (isometric)
            let topPath = UIBezierPath()
            topPath.move(to: CGPoint(x: frontRect.minX, y: frontRect.minY))
            topPath.addLine(to: CGPoint(x: frontRect.minX + cubeSize/3, y: frontRect.minY - cubeSize/3))
            topPath.addLine(to: CGPoint(x: frontRect.maxX + cubeSize/3, y: frontRect.minY - cubeSize/3))
            topPath.addLine(to: CGPoint(x: frontRect.maxX, y: frontRect.minY))
            topPath.close()
            
            UIColor.systemBlue.setStroke()
            topPath.stroke()
            
            // Right face
            let rightPath = UIBezierPath()
            rightPath.move(to: CGPoint(x: frontRect.maxX, y: frontRect.minY))
            rightPath.addLine(to: CGPoint(x: frontRect.maxX + cubeSize/3, y: frontRect.minY - cubeSize/3))
            rightPath.addLine(to: CGPoint(x: frontRect.maxX + cubeSize/3, y: frontRect.maxY - cubeSize/3))
            rightPath.addLine(to: CGPoint(x: frontRect.maxX, y: frontRect.maxY))
            rightPath.close()
            
            UIColor.systemBlue.setStroke()
            rightPath.stroke()
        }
    }
    
    private func generateBasicFaceImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            // Face oval
            let faceSize = min(size.width, size.height) * 0.7
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            let faceRect = CGRect(
                x: centerX - faceSize/2,
                y: centerY - faceSize/2,
                width: faceSize,
                height: faceSize * 1.3
            )
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Face outline
            let facePath = UIBezierPath(ovalIn: faceRect)
            facePath.stroke()
            
            // Guidelines
            context.cgContext.setLineWidth(1.0)
            UIColor.systemGray.setStroke()
            
            // Eye line
            let eyeLineY = faceRect.midY
            context.cgContext.move(to: CGPoint(x: faceRect.minX, y: eyeLineY))
            context.cgContext.addLine(to: CGPoint(x: faceRect.maxX, y: eyeLineY))
            context.cgContext.strokePath()
            
            // Nose line
            let noseLineY = faceRect.midY + faceSize * 0.2
            context.cgContext.move(to: CGPoint(x: faceRect.minX, y: noseLineY))
            context.cgContext.addLine(to: CGPoint(x: faceRect.maxX, y: noseLineY))
            context.cgContext.strokePath()
            
            // Mouth line
            let mouthLineY = faceRect.midY + faceSize * 0.35
            context.cgContext.move(to: CGPoint(x: faceRect.minX, y: mouthLineY))
            context.cgContext.addLine(to: CGPoint(x: faceRect.maxX, y: mouthLineY))
            context.cgContext.strokePath()
        }
    }
    
    private func generateCircleImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            // Circle
            let circleSize = min(size.width, size.height) * 0.8
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            let circleRect = CGRect(
                x: centerX - circleSize/2,
                y: centerY - circleSize/2,
                width: circleSize,
                height: circleSize
            )
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            let circlePath = UIBezierPath(ovalIn: circleRect)
            circlePath.stroke()
        }
    }
    
    private func generatePerspectiveImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Horizon line
            let horizonY = size.height * 0.4
            context.cgContext.move(to: CGPoint(x: 0, y: horizonY))
            context.cgContext.addLine(to: CGPoint(x: size.width, y: horizonY))
            context.cgContext.strokePath()
            
            // Vanishing point
            let vanishingPoint = CGPoint(x: size.width / 2, y: horizonY)
            
            // Rectangle in perspective
            let rectWidth: CGFloat = size.width * 0.3
            let rectHeight: CGFloat = size.height * 0.2
            let rectY = horizonY + 50
            
            let leftX = size.width / 2 - rectWidth / 2
            let rightX = size.width / 2 + rectWidth / 2
            
            // Front face
            context.cgContext.move(to: CGPoint(x: leftX, y: rectY))
            context.cgContext.addLine(to: CGPoint(x: rightX, y: rectY))
            context.cgContext.addLine(to: CGPoint(x: rightX, y: rectY + rectHeight))
            context.cgContext.addLine(to: CGPoint(x: leftX, y: rectY + rectHeight))
            context.cgContext.addLine(to: CGPoint(x: leftX, y: rectY))
            context.cgContext.strokePath()
            
            // Perspective lines
            context.cgContext.setLineWidth(1.0)
            UIColor.systemGray.setStroke()
            
            // Top lines to vanishing point
            context.cgContext.move(to: CGPoint(x: leftX, y: rectY))
            context.cgContext.addLine(to: vanishingPoint)
            context.cgContext.strokePath()
            
            context.cgContext.move(to: CGPoint(x: rightX, y: rectY))
            context.cgContext.addLine(to: vanishingPoint)
            context.cgContext.strokePath()
        }
    }
    
    // MARK: - Placeholder Creation
    
    private func createPlaceholderImage(for imageName: String, type: ImageType) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: type.size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: type.size)
            
            // Background
            Config.placeholderColor.setFill()
            context.fill(rect)
            
            // Icon based on image name
            let iconName = getIconName(for: imageName)
            let iconSize: CGFloat = min(type.size.width, type.size.height) * 0.4
            
            if let iconImage = UIImage(systemName: iconName) {
                let iconRect = CGRect(
                    x: (type.size.width - iconSize) / 2,
                    y: (type.size.height - iconSize) / 2,
                    width: iconSize,
                    height: iconSize
                )
                
                UIColor.systemBackground.setFill()
                iconImage.draw(in: iconRect)
            }
            
            // Label for type
            if type == .thumbnail {
                let label = "Thumb"
                let font = UIFont.systemFont(ofSize: 10, weight: .medium)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.systemBackground
                ]
                
                let labelSize = label.size(withAttributes: attributes)
                let labelRect = CGRect(
                    x: (type.size.width - labelSize.width) / 2,
                    y: type.size.height - labelSize.height - 5,
                    width: labelSize.width,
                    height: labelSize.height
                )
                
                label.draw(in: labelRect, withAttributes: attributes)
            }
        }
    }
    
    private func getIconName(for imageName: String) -> String {
        let baseName = imageName.replacingOccurrences(of: "_thumb", with: "").replacingOccurrences(of: "_ref", with: "")
        
        switch baseName {
        case let name where name.contains("face"):
            return "person.crop.circle"
        case let name where name.contains("eye"):
            return "eye"
        case let name where name.contains("cat"):
            return "cat"
        case let name where name.contains("dog"):
            return "dog"
        case let name where name.contains("bird"):
            return "bird"
        case let name where name.contains("hand"):
            return "hand.raised"
        case let name where name.contains("cube"):
            return "cube"
        case let name where name.contains("apple"):
            return "circle"
        case let name where name.contains("perspective"):
            return "rectangle.3.group"
        default:
            return "photo"
        }
    }
    
    // MARK: - Preloading
    
    private func preloadCommonImages() {
        Task {
            // Preload thumbnails for better performance
            let commonImages = [
                "face_basic",
                "cube",
                "cat",
                "perspective"
            ]
            
            for imageName in commonImages {
                _ = await loadImage(for: imageName, type: .thumbnail)
            }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        imageCache.removeAllObjects()
        loadedImages.removeAll()
        imageLoadingStates.removeAll()
    }
    
    func getCacheSize() -> Int {
        return imageCache.totalCostLimit
    }
    
    func getCachedImageCount() -> Int {
        return loadedImages.count
    }
    
    // MARK: - Image Utilities
    
    func saveImageToDocuments(_ image: UIImage, imageName: String) async -> Bool {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let referenceImagesDirectory = documentsDirectory.appendingPathComponent("ReferenceImages")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: referenceImagesDirectory, withIntermediateDirectories: true)
        
        let imageURL = referenceImagesDirectory.appendingPathComponent(imageName + ".png")
        
        guard let imageData = image.pngData() else {
            return false
        }
        
        do {
            try imageData.write(to: imageURL)
            return true
        } catch {
            print("Failed to save image: \(error)")
            return false
        }
    }
    
    func deleteImageFromDocuments(_ imageName: String) async -> Bool {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }
        
        let imageURL = documentsDirectory
            .appendingPathComponent("ReferenceImages")
            .appendingPathComponent(imageName + ".png")
        
        do {
            try fileManager.removeItem(at: imageURL)
            
            // Remove from cache
            imageCache.removeObject(forKey: imageName as NSString)
            await MainActor.run {
                loadedImages.removeValue(forKey: imageName)
                imageLoadingStates.removeValue(forKey: imageName)
            }
            
            return true
        } catch {
            print("Failed to delete image: \(error)")
            return false
        }
    }
    
    // MARK: - Enhanced Procedural Image Generation Methods
    
    private func generateLoomisMethodImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius = min(size.width, size.height) * 0.25
            
            // Main sphere
            let sphereRect = CGRect(
                x: centerX - radius,
                y: centerY - radius * 1.2,
                width: radius * 2,
                height: radius * 2
            )
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            let spherePath = UIBezierPath(ovalIn: sphereRect)
            spherePath.stroke()
            
            // Cross lines for facial plane
            UIColor.systemGray.setStroke()
            context.cgContext.setLineWidth(1.0)
            
            // Vertical center line
            let verticalLine = UIBezierPath()
            verticalLine.move(to: CGPoint(x: centerX, y: sphereRect.minY))
            verticalLine.addLine(to: CGPoint(x: centerX, y: sphereRect.maxY))
            verticalLine.stroke()
            
            // Horizontal center line
            let horizontalLine = UIBezierPath()
            horizontalLine.move(to: CGPoint(x: sphereRect.minX, y: centerY))
            horizontalLine.addLine(to: CGPoint(x: sphereRect.maxX, y: centerY))
            horizontalLine.stroke()
            
            // Jaw line
            let jawPath = UIBezierPath()
            jawPath.move(to: CGPoint(x: centerX - radius * 0.8, y: sphereRect.maxY))
            jawPath.addQuadCurve(
                to: CGPoint(x: centerX + radius * 0.8, y: sphereRect.maxY),
                controlPoint: CGPoint(x: centerX, y: sphereRect.maxY + radius * 0.3)
            )
            jawPath.stroke()
        }
    }
    
    private func generateEyeStudyImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let eyeWidth = size.width * 0.25
            let eyeHeight = eyeWidth * 0.6
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Left eye
            let leftEyeRect = CGRect(
                x: centerX - eyeWidth - 10,
                y: centerY - eyeHeight/2,
                width: eyeWidth,
                height: eyeHeight
            )
            
            let leftEyePath = UIBezierPath()
            leftEyePath.move(to: CGPoint(x: leftEyeRect.minX, y: leftEyeRect.midY))
            leftEyePath.addQuadCurve(
                to: CGPoint(x: leftEyeRect.maxX, y: leftEyeRect.midY),
                controlPoint: CGPoint(x: leftEyeRect.midX, y: leftEyeRect.minY)
            )
            leftEyePath.addQuadCurve(
                to: CGPoint(x: leftEyeRect.minX, y: leftEyeRect.midY),
                controlPoint: CGPoint(x: leftEyeRect.midX, y: leftEyeRect.maxY)
            )
            leftEyePath.stroke()
            
            // Right eye
            let rightEyeRect = CGRect(
                x: centerX + 10,
                y: centerY - eyeHeight/2,
                width: eyeWidth,
                height: eyeHeight
            )
            
            let rightEyePath = UIBezierPath()
            rightEyePath.move(to: CGPoint(x: rightEyeRect.minX, y: rightEyeRect.midY))
            rightEyePath.addQuadCurve(
                to: CGPoint(x: rightEyeRect.maxX, y: rightEyeRect.midY),
                controlPoint: CGPoint(x: rightEyeRect.midX, y: rightEyeRect.minY)
            )
            rightEyePath.addQuadCurve(
                to: CGPoint(x: rightEyeRect.minX, y: rightEyeRect.midY),
                controlPoint: CGPoint(x: rightEyeRect.midX, y: rightEyeRect.maxY)
            )
            rightEyePath.stroke()
            
            // Iris circles
            let irisRadius = eyeWidth * 0.2
            
            let leftIrisPath = UIBezierPath(arcCenter: CGPoint(x: leftEyeRect.midX, y: leftEyeRect.midY),
                                          radius: irisRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            leftIrisPath.stroke()
            
            let rightIrisPath = UIBezierPath(arcCenter: CGPoint(x: rightEyeRect.midX, y: rightEyeRect.midY),
                                           radius: irisRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            rightIrisPath.stroke()
        }
    }
    
    private func generateCatFaceImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let headRadius = min(size.width, size.height) * 0.3
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Head circle
            let headPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                       radius: headRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            headPath.stroke()
            
            // Ears (triangular)
            let _ = headRadius * 0.6  // Ear size calculation
            
            // Left ear
            let leftEarPath = UIBezierPath()
            leftEarPath.move(to: CGPoint(x: centerX - headRadius * 0.5, y: centerY - headRadius * 0.8))
            leftEarPath.addLine(to: CGPoint(x: centerX - headRadius * 0.8, y: centerY - headRadius * 1.3))
            leftEarPath.addLine(to: CGPoint(x: centerX - headRadius * 0.2, y: centerY - headRadius * 1.1))
            leftEarPath.close()
            leftEarPath.stroke()
            
            // Right ear
            let rightEarPath = UIBezierPath()
            rightEarPath.move(to: CGPoint(x: centerX + headRadius * 0.5, y: centerY - headRadius * 0.8))
            rightEarPath.addLine(to: CGPoint(x: centerX + headRadius * 0.8, y: centerY - headRadius * 1.3))
            rightEarPath.addLine(to: CGPoint(x: centerX + headRadius * 0.2, y: centerY - headRadius * 1.1))
            rightEarPath.close()
            rightEarPath.stroke()
            
            // Eyes
            let eyeRadius = headRadius * 0.15
            let leftEyePath = UIBezierPath(arcCenter: CGPoint(x: centerX - headRadius * 0.3, y: centerY - headRadius * 0.2),
                                          radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            leftEyePath.stroke()
            
            let rightEyePath = UIBezierPath(arcCenter: CGPoint(x: centerX + headRadius * 0.3, y: centerY - headRadius * 0.2),
                                           radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            rightEyePath.stroke()
            
            // Nose triangle
            let nosePath = UIBezierPath()
            nosePath.move(to: CGPoint(x: centerX, y: centerY))
            nosePath.addLine(to: CGPoint(x: centerX - headRadius * 0.1, y: centerY + headRadius * 0.1))
            nosePath.addLine(to: CGPoint(x: centerX + headRadius * 0.1, y: centerY + headRadius * 0.1))
            nosePath.close()
            nosePath.stroke()
            
            // Mouth
            let mouthPath = UIBezierPath()
            mouthPath.move(to: CGPoint(x: centerX, y: centerY + headRadius * 0.15))
            mouthPath.addLine(to: CGPoint(x: centerX - headRadius * 0.2, y: centerY + headRadius * 0.25))
            mouthPath.move(to: CGPoint(x: centerX, y: centerY + headRadius * 0.15))
            mouthPath.addLine(to: CGPoint(x: centerX + headRadius * 0.2, y: centerY + headRadius * 0.25))
            mouthPath.stroke()
        }
    }
    
    private func generateDogPortraitImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let headWidth = size.width * 0.4
            let headHeight = headWidth * 1.2
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Head oval
            let headRect = CGRect(
                x: centerX - headWidth/2,
                y: centerY - headHeight/2,
                width: headWidth,
                height: headHeight
            )
            
            let headPath = UIBezierPath(ovalIn: headRect)
            headPath.stroke()
            
            // Snout rectangle
            let snoutWidth = headWidth * 0.6
            let snoutHeight = headHeight * 0.3
            let snoutRect = CGRect(
                x: centerX - snoutWidth/2,
                y: centerY + headHeight * 0.1,
                width: snoutWidth,
                height: snoutHeight
            )
            
            let snoutPath = UIBezierPath(roundedRect: snoutRect, cornerRadius: snoutHeight * 0.2)
            snoutPath.stroke()
            
            // Ears (droopy)
            let leftEarPath = UIBezierPath()
            leftEarPath.move(to: CGPoint(x: headRect.minX + headWidth * 0.1, y: headRect.minY + headHeight * 0.2))
            leftEarPath.addQuadCurve(
                to: CGPoint(x: headRect.minX - headWidth * 0.2, y: headRect.midY),
                controlPoint: CGPoint(x: headRect.minX - headWidth * 0.1, y: headRect.minY + headHeight * 0.4)
            )
            leftEarPath.addQuadCurve(
                to: CGPoint(x: headRect.minX + headWidth * 0.2, y: headRect.minY + headHeight * 0.4),
                controlPoint: CGPoint(x: headRect.minX, y: headRect.midY + headHeight * 0.1)
            )
            leftEarPath.stroke()
            
            let rightEarPath = UIBezierPath()
            rightEarPath.move(to: CGPoint(x: headRect.maxX - headWidth * 0.1, y: headRect.minY + headHeight * 0.2))
            rightEarPath.addQuadCurve(
                to: CGPoint(x: headRect.maxX + headWidth * 0.2, y: headRect.midY),
                controlPoint: CGPoint(x: headRect.maxX + headWidth * 0.1, y: headRect.minY + headHeight * 0.4)
            )
            rightEarPath.addQuadCurve(
                to: CGPoint(x: headRect.maxX - headWidth * 0.2, y: headRect.minY + headHeight * 0.4),
                controlPoint: CGPoint(x: headRect.maxX, y: headRect.midY + headHeight * 0.1)
            )
            rightEarPath.stroke()
            
            // Eyes
            let eyeRadius = headWidth * 0.08
            let leftEyePath = UIBezierPath(arcCenter: CGPoint(x: centerX - headWidth * 0.2, y: centerY - headHeight * 0.15),
                                          radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            leftEyePath.stroke()
            
            let rightEyePath = UIBezierPath(arcCenter: CGPoint(x: centerX + headWidth * 0.2, y: centerY - headHeight * 0.15),
                                           radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            rightEyePath.stroke()
            
            // Nose
            let noseRadius = headWidth * 0.05
            let nosePath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: snoutRect.minY + snoutHeight * 0.3),
                                       radius: noseRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.black.setFill()
            nosePath.fill()
        }
    }
    
    private func generateBirdFlightImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let bodyWidth = size.width * 0.15
            let bodyHeight = bodyWidth * 2
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Body oval
            let bodyRect = CGRect(
                x: centerX - bodyWidth/2,
                y: centerY - bodyHeight/2,
                width: bodyWidth,
                height: bodyHeight
            )
            
            let bodyPath = UIBezierPath(ovalIn: bodyRect)
            bodyPath.stroke()
            
            // Wings in flight position
            let wingSpan = size.width * 0.6
            let wingHeight = wingSpan * 0.3
            
            // Left wing
            let leftWingPath = UIBezierPath()
            leftWingPath.move(to: CGPoint(x: bodyRect.minX, y: centerY))
            leftWingPath.addQuadCurve(
                to: CGPoint(x: centerX - wingSpan/2, y: centerY - wingHeight/2),
                controlPoint: CGPoint(x: centerX - wingSpan/3, y: centerY - wingHeight)
            )
            leftWingPath.addQuadCurve(
                to: CGPoint(x: bodyRect.minX, y: centerY + bodyHeight * 0.1),
                controlPoint: CGPoint(x: centerX - wingSpan/4, y: centerY + wingHeight/2)
            )
            leftWingPath.stroke()
            
            // Right wing
            let rightWingPath = UIBezierPath()
            rightWingPath.move(to: CGPoint(x: bodyRect.maxX, y: centerY))
            rightWingPath.addQuadCurve(
                to: CGPoint(x: centerX + wingSpan/2, y: centerY - wingHeight/2),
                controlPoint: CGPoint(x: centerX + wingSpan/3, y: centerY - wingHeight)
            )
            rightWingPath.addQuadCurve(
                to: CGPoint(x: bodyRect.maxX, y: centerY + bodyHeight * 0.1),
                controlPoint: CGPoint(x: centerX + wingSpan/4, y: centerY + wingHeight/2)
            )
            rightWingPath.stroke()
            
            // Head
            let headRadius = bodyWidth * 0.6
            let headPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: bodyRect.minY - headRadius * 0.5),
                                       radius: headRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            headPath.stroke()
            
            // Tail
            let tailPath = UIBezierPath()
            tailPath.move(to: CGPoint(x: centerX, y: bodyRect.maxY))
            tailPath.addLine(to: CGPoint(x: centerX - bodyWidth * 0.3, y: bodyRect.maxY + bodyHeight * 0.4))
            tailPath.addLine(to: CGPoint(x: centerX, y: bodyRect.maxY + bodyHeight * 0.3))
            tailPath.addLine(to: CGPoint(x: centerX + bodyWidth * 0.3, y: bodyRect.maxY + bodyHeight * 0.4))
            tailPath.stroke()
        }
    }
    
    private func generateAppleStillLifeImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let appleRadius = min(size.width, size.height) * 0.25
            
            UIColor.systemRed.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Apple body (slightly flattened circle)
            let appleRect = CGRect(
                x: centerX - appleRadius,
                y: centerY - appleRadius * 0.9,
                width: appleRadius * 2,
                height: appleRadius * 1.8
            )
            
            let applePath = UIBezierPath(ovalIn: appleRect)
            applePath.stroke()
            
            // Apple indentation at top
            UIColor.systemBrown.setStroke()
            let indentPath = UIBezierPath()
            indentPath.move(to: CGPoint(x: centerX - appleRadius * 0.3, y: appleRect.minY))
            indentPath.addQuadCurve(
                to: CGPoint(x: centerX + appleRadius * 0.3, y: appleRect.minY),
                controlPoint: CGPoint(x: centerX, y: appleRect.minY - appleRadius * 0.2)
            )
            indentPath.stroke()
            
            // Stem
            let stemPath = UIBezierPath()
            stemPath.move(to: CGPoint(x: centerX, y: appleRect.minY - appleRadius * 0.1))
            stemPath.addLine(to: CGPoint(x: centerX, y: appleRect.minY - appleRadius * 0.3))
            stemPath.stroke()
            
            // Highlight (to show 3D form)
            UIColor.systemYellow.setStroke()
            context.cgContext.setLineWidth(1.0)
            let highlightPath = UIBezierPath(arcCenter: CGPoint(x: centerX - appleRadius * 0.3, y: centerY - appleRadius * 0.3),
                                            radius: appleRadius * 0.2, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            highlightPath.stroke()
            
            // Shadow indication
            UIColor.systemGray.setStroke()
            let shadowPath = UIBezierPath()
            shadowPath.move(to: CGPoint(x: centerX - appleRadius * 1.2, y: centerY + appleRadius * 1.2))
            shadowPath.addQuadCurve(
                to: CGPoint(x: centerX + appleRadius * 1.2, y: centerY + appleRadius * 1.2),
                controlPoint: CGPoint(x: centerX, y: centerY + appleRadius * 1.4)
            )
            shadowPath.stroke()
        }
    }
    
    private func generateHandStructureImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            let palmWidth = size.width * 0.25
            let palmHeight = palmWidth * 1.3
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Palm rectangle
            let palmRect = CGRect(
                x: centerX - palmWidth/2,
                y: centerY,
                width: palmWidth,
                height: palmHeight
            )
            
            let palmPath = UIBezierPath(roundedRect: palmRect, cornerRadius: palmWidth * 0.1)
            palmPath.stroke()
            
            // Fingers (simplified as rectangles)
            let fingerWidth = palmWidth * 0.18
            let fingerSpacing = palmWidth * 0.02
            
            // Index finger
            let indexRect = CGRect(
                x: palmRect.minX + fingerSpacing,
                y: palmRect.minY - palmHeight * 0.8,
                width: fingerWidth,
                height: palmHeight * 0.8
            )
            let indexPath = UIBezierPath(roundedRect: indexRect, cornerRadius: fingerWidth * 0.3)
            indexPath.stroke()
            
            // Middle finger (longest)
            let middleRect = CGRect(
                x: palmRect.minX + fingerWidth + fingerSpacing * 2,
                y: palmRect.minY - palmHeight * 0.9,
                width: fingerWidth,
                height: palmHeight * 0.9
            )
            let middlePath = UIBezierPath(roundedRect: middleRect, cornerRadius: fingerWidth * 0.3)
            middlePath.stroke()
            
            // Ring finger
            let ringRect = CGRect(
                x: palmRect.minX + fingerWidth * 2 + fingerSpacing * 3,
                y: palmRect.minY - palmHeight * 0.75,
                width: fingerWidth,
                height: palmHeight * 0.75
            )
            let ringPath = UIBezierPath(roundedRect: ringRect, cornerRadius: fingerWidth * 0.3)
            ringPath.stroke()
            
            // Pinky finger
            let pinkyRect = CGRect(
                x: palmRect.minX + fingerWidth * 3 + fingerSpacing * 4,
                y: palmRect.minY - palmHeight * 0.6,
                width: fingerWidth,
                height: palmHeight * 0.6
            )
            let pinkyPath = UIBezierPath(roundedRect: pinkyRect, cornerRadius: fingerWidth * 0.3)
            pinkyPath.stroke()
            
            // Thumb
            let thumbWidth = fingerWidth * 1.2
            let thumbRect = CGRect(
                x: palmRect.minX - thumbWidth - fingerSpacing,
                y: palmRect.minY + palmHeight * 0.2,
                width: thumbWidth,
                height: palmHeight * 0.5
            )
            let thumbPath = UIBezierPath(roundedRect: thumbRect, cornerRadius: thumbWidth * 0.3)
            thumbPath.stroke()
            
            // Joint indicators
            UIColor.systemGray.setStroke()
            context.cgContext.setLineWidth(1.0)
            
            // Finger joints
            for fingerRect in [indexRect, middleRect, ringRect, pinkyRect] {
                let joint1Y = fingerRect.minY + fingerRect.height * 0.33
                let joint2Y = fingerRect.minY + fingerRect.height * 0.66
                
                let joint1Path = UIBezierPath()
                joint1Path.move(to: CGPoint(x: fingerRect.minX, y: joint1Y))
                joint1Path.addLine(to: CGPoint(x: fingerRect.maxX, y: joint1Y))
                joint1Path.stroke()
                
                let joint2Path = UIBezierPath()
                joint2Path.move(to: CGPoint(x: fingerRect.minX, y: joint2Y))
                joint2Path.addLine(to: CGPoint(x: fingerRect.maxX, y: joint2Y))
                joint2Path.stroke()
            }
        }
    }
    
    private func generateOnePointPerspectiveImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Background
            UIColor.systemBackground.setFill()
            context.fill(rect)
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            // Horizon line
            let horizonPath = UIBezierPath()
            horizonPath.move(to: CGPoint(x: 0, y: centerY))
            horizonPath.addLine(to: CGPoint(x: size.width, y: centerY))
            horizonPath.stroke()
            
            // Vanishing point
            UIColor.systemRed.setFill()
            let vanishingPoint = CGPoint(x: centerX, y: centerY)
            let vanishingPointPath = UIBezierPath(arcCenter: vanishingPoint, radius: 4,
                                                 startAngle: 0, endAngle: .pi * 2, clockwise: true)
            vanishingPointPath.fill()
            
            // Converging lines
            UIColor.systemGray.setStroke()
            context.cgContext.setLineWidth(1.0)
            
            let convergingPaths = [
                (CGPoint(x: size.width * 0.1, y: size.height * 0.8), vanishingPoint),
                (CGPoint(x: size.width * 0.9, y: size.height * 0.8), vanishingPoint),
                (CGPoint(x: size.width * 0.1, y: size.height * 0.2), vanishingPoint),
                (CGPoint(x: size.width * 0.9, y: size.height * 0.2), vanishingPoint),
                (CGPoint(x: 0, y: size.height * 0.9), vanishingPoint),
                (CGPoint(x: size.width, y: size.height * 0.9), vanishingPoint)
            ]
            
            for (start, end) in convergingPaths {
                let line = UIBezierPath()
                line.move(to: start)
                line.addLine(to: end)
                line.stroke()
            }
            
            // Simple cube in perspective
            UIColor.systemBlue.setStroke()
            context.cgContext.setLineWidth(2.0)
            
            let cubeSize: CGFloat = size.width * 0.15
            let cubeBottom = size.height * 0.75
            let cubeLeft = size.width * 0.3
            
            // Front face
            let frontRect = CGRect(x: cubeLeft, y: cubeBottom - cubeSize, width: cubeSize, height: cubeSize)
            let frontPath = UIBezierPath(rect: frontRect)
            frontPath.stroke()
            
            // Perspective lines to vanishing point
            let perspectivePaths = [
                (CGPoint(x: frontRect.minX, y: frontRect.minY), vanishingPoint),
                (CGPoint(x: frontRect.maxX, y: frontRect.minY), vanishingPoint),
                (CGPoint(x: frontRect.minX, y: frontRect.maxY), vanishingPoint),
                (CGPoint(x: frontRect.maxX, y: frontRect.maxY), vanishingPoint)
            ]
            
            for (start, end) in perspectivePaths {
                let line = UIBezierPath()
                line.move(to: start)
                // Only draw part of the line to show the cube edges
                let progress: CGFloat = 0.3
                let partialEnd = CGPoint(
                    x: start.x + (end.x - start.x) * progress,
                    y: start.y + (end.y - start.y) * progress
                )
                line.addLine(to: partialEnd)
                line.stroke()
            }
        }
    }
}

// MARK: - SwiftUI Integration

struct AsyncReferenceImage: View {
    let imageName: String
    let type: ImageAssetManager.ImageType
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(_ imageName: String, type: ImageAssetManager.ImageType = .reference) {
        self.imageName = imageName
        self.type = type
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(width: type.size.width, height: type.size.height)
            } else {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .frame(width: type.size.width, height: type.size.height)
            }
        }
        .task {
            let loadedImage = await ImageAssetManager.shared.loadImage(for: imageName, type: type)
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

struct CachedImage: View {
    let imageName: String
    let type: ImageAssetManager.ImageType
    
    init(_ imageName: String, type: ImageAssetManager.ImageType = .reference) {
        self.imageName = imageName
        self.type = type
    }
    
    var body: some View {
        let uiImage = ImageAssetManager.shared.getImage(for: imageName, type: type)
        
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

// MARK: - View Extensions

extension View {
    func referenceImage(_ imageName: String, type: ImageAssetManager.ImageType = .reference) -> some View {
        AsyncReferenceImage(imageName, type: type)
    }
    
    func cachedReferenceImage(_ imageName: String, type: ImageAssetManager.ImageType = .reference) -> some View {
        CachedImage(imageName, type: type)
    }
}

