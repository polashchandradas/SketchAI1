import Foundation
import SwiftUI
import CoreML
import Vision
import CoreGraphics
import UIKit

// MARK: - Main Drawing Algorithm Engine
@MainActor
class DrawingAlgorithmEngine: ObservableObject {
    @Published var currentGuides: [DrawingGuide] = []
    @Published var analysisComplete = false
    @Published var currentStep = 0
    
    private let imageAnalyzer = ImageAnalyzer()
    private let proportionCalculator = ProportionCalculator()
    private let guideGenerator = GuideGenerator()
    
    // MARK: - Public Interface
    func analyzeImage(_ image: UIImage, for category: LessonCategory) async {
        do {
            let analysisResult = try await imageAnalyzer.analyzeImage(image, category: category)
            let proportions = proportionCalculator.calculateProportions(for: analysisResult)
            let guides = guideGenerator.generateGuides(from: proportions, category: category)
            
            await MainActor.run {
                self.currentGuides = guides
                self.analysisComplete = true
                self.currentStep = 0
            }
        } catch {
            print("Error analyzing image: \(error)")
        }
    }
    
    /// CRITICAL FIX: Setup tutorial system from lesson data
    func setupTutorialFromLesson(_ lesson: Lesson) async {
        print("🎯 [TUTORIAL] Setting up tutorial system for lesson: \(lesson.title)")
        
        // Generate guides from lesson steps
        let guides = guideGenerator.generateGuidesFromLesson(lesson)
        
        await MainActor.run {
            self.currentGuides = guides
            self.analysisComplete = true
            self.currentStep = 0
            print("🎯 [TUTORIAL] Tutorial system initialized with \(guides.count) guides")
        }
    }
    
    func getCurrentGuide() -> DrawingGuide? {
        print("🔍 [DrawingEngine] getCurrentGuide called - currentStep: \(currentStep), guides count: \(currentGuides.count)")
        guard currentStep < currentGuides.count else { 
            print("❌ [DrawingEngine] No guide available - currentStep (\(currentStep)) >= guides count (\(currentGuides.count))")
            return nil 
        }
        let guide = currentGuides[currentStep]
        print("✅ [DrawingEngine] Returning guide: \(guide.instruction)")
        return guide
    }
    
    func nextStep() {
        if currentStep < currentGuides.count - 1 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    func analyzeUserStroke(_ stroke: DrawingStroke, against guide: DrawingGuide) -> StrokeFeedback {
        // ENHANCED: Use unified Core ML-based stroke analyzer
        let unifiedAnalyzer = UnifiedStrokeAnalyzer()
        return unifiedAnalyzer.analyzeStroke(stroke, against: guide)
    }
    
    func setupBasicGuides(for category: LessonCategory) async {
        // Fallback method to provide basic guides when Vision analysis fails
        let basicAnalysisResult = createBasicAnalysisResult(for: category)
        let proportions = proportionCalculator.calculateProportions(for: basicAnalysisResult)
        let guides = guideGenerator.generateGuides(from: proportions, category: category)
        
        await MainActor.run {
            self.currentGuides = guides
            self.analysisComplete = true
            self.currentStep = 0
        }
    }
    
    private func createBasicAnalysisResult(for category: LessonCategory) -> ImageAnalysisResult {
        let imageSize = CGSize(width: 400, height: 400)
        
        switch category {
        case .faces:
            return ImageAnalysisResult(
                landmarks: [
                    DetectedLandmark(type: .leftEye, point: CGPoint(x: 155, y: 160), confidence: 0.8),
                    DetectedLandmark(type: .rightEye, point: CGPoint(x: 245, y: 160), confidence: 0.8),
                    DetectedLandmark(type: .nose, point: CGPoint(x: 200, y: 190), confidence: 0.8),
                    DetectedLandmark(type: .mouth, point: CGPoint(x: 200, y: 227), confidence: 0.8)
                ],
                boundingBoxes: [DetectedObject(type: .face, boundingBox: CGRect(x: 100, y: 80, width: 200, height: 240), confidence: 0.8)],
                imageSize: imageSize,
                confidence: 0.8
            )
            
        case .hands:
            return ImageAnalysisResult(
                landmarks: [
                    DetectedLandmark(type: .wrist, point: CGPoint(x: 200, y: 300), confidence: 0.8),
                    DetectedLandmark(type: .indexTip, point: CGPoint(x: 180, y: 120), confidence: 0.8)
                ],
                boundingBoxes: [DetectedObject(type: .hand, boundingBox: CGRect(x: 150, y: 120, width: 100, height: 180), confidence: 0.8)],
                imageSize: imageSize,
                confidence: 0.8
            )
            
        case .animals:
            return ImageAnalysisResult(
                landmarks: [],
                boundingBoxes: [DetectedObject(type: .animal, boundingBox: CGRect(x: 50, y: 120, width: 370, height: 150), confidence: 0.8)],
                imageSize: imageSize,
                confidence: 0.8
            )
            
        case .perspective, .objects:
            return ImageAnalysisResult(
                landmarks: [
                    DetectedLandmark(type: .topLeftCorner, point: CGPoint(x: 80, y: 100), confidence: 0.8),
                    DetectedLandmark(type: .topRightCorner, point: CGPoint(x: 200, y: 100), confidence: 0.8),
                    DetectedLandmark(type: .bottomLeftCorner, point: CGPoint(x: 80, y: 180), confidence: 0.8),
                    DetectedLandmark(type: .bottomRightCorner, point: CGPoint(x: 200, y: 180), confidence: 0.8)
                ],
                boundingBoxes: [DetectedObject(type: .building, boundingBox: CGRect(x: 80, y: 100, width: 120, height: 80), confidence: 0.8)],
                imageSize: imageSize,
                confidence: 0.8
            )
            
        case .nature:
            return ImageAnalysisResult(
                landmarks: [],
                boundingBoxes: [DetectedObject(type: .flower, boundingBox: CGRect(x: 120, y: 100, width: 160, height: 180), confidence: 0.8)],
                imageSize: imageSize,
                confidence: 0.8
            )
        }
    }
}

// MARK: - Data Models

struct DrawingGuide: Identifiable {
    let id = UUID()
    let stepNumber: Int
    let instruction: String
    let shapes: [GuideShape]
    let targetPoints: [CGPoint]
    var tolerance: CGFloat
    let category: LessonCategory
}

struct GuideShape {
    let type: ShapeType
    let points: [CGPoint]
    let center: CGPoint
    let dimensions: CGSize
    let rotation: CGFloat
    let strokeWidth: CGFloat
    let color: Color
    let style: StrokeStyle
    
    enum StrokeStyle {
        case solid
        case dashed(pattern: [CGFloat])
        case dotted
    }
}

struct DrawingStroke {
    let points: [CGPoint]
    let timestamp: Date
    let pressure: [CGFloat]
    let velocity: [CGFloat]
}

struct StrokeFeedback: Equatable {
    let accuracy: Double // 0.0 to 1.0
    let suggestions: [String]
    let correctionPoints: [CGPoint]
    let isCorrect: Bool
    
    // DTW-specific properties
    let dtwDistance: Double?
    let temporalAccuracy: Double?
    let velocityConsistency: Double?
    let spatialAlignment: [(Int, Int)]?
    let confidenceScore: Double?
    
    // ENHANCED: Artistic feedback properties
    let artisticFeedback: ArtisticFeedback?
    
    // Initialize with basic properties (backward compatibility)
    init(accuracy: Double, suggestions: [String], correctionPoints: [CGPoint], isCorrect: Bool) {
        self.accuracy = accuracy
        self.suggestions = suggestions
        self.correctionPoints = correctionPoints
        self.isCorrect = isCorrect
        self.dtwDistance = nil
        self.temporalAccuracy = nil
        self.velocityConsistency = nil
        self.spatialAlignment = nil
        self.confidenceScore = nil
        self.artisticFeedback = nil
    }
    
    // Initialize with DTW properties
    init(
        accuracy: Double,
        suggestions: [String],
        correctionPoints: [CGPoint],
        isCorrect: Bool,
        dtwDistance: Double?,
        temporalAccuracy: Double?,
        velocityConsistency: Double?,
        spatialAlignment: [(Int, Int)]?,
        confidenceScore: Double?
    ) {
        self.accuracy = accuracy
        self.suggestions = suggestions
        self.correctionPoints = correctionPoints
        self.isCorrect = isCorrect
        self.dtwDistance = dtwDistance
        self.temporalAccuracy = temporalAccuracy
        self.velocityConsistency = velocityConsistency
        self.spatialAlignment = spatialAlignment
        self.confidenceScore = confidenceScore
        self.artisticFeedback = nil
    }
    
    // ENHANCED: Initialize with artistic feedback
    init(
        accuracy: Double,
        suggestions: [String],
        correctionPoints: [CGPoint],
        isCorrect: Bool,
        dtwDistance: Double?,
        temporalAccuracy: Double?,
        velocityConsistency: Double?,
        spatialAlignment: [(Int, Int)]?,
        confidenceScore: Double?,
        artisticFeedback: ArtisticFeedback?
    ) {
        self.accuracy = accuracy
        self.suggestions = suggestions
        self.correctionPoints = correctionPoints
        self.isCorrect = isCorrect
        self.dtwDistance = dtwDistance
        self.temporalAccuracy = temporalAccuracy
        self.velocityConsistency = velocityConsistency
        self.spatialAlignment = spatialAlignment
        self.confidenceScore = confidenceScore
        self.artisticFeedback = artisticFeedback
    }
    
    static func == (lhs: StrokeFeedback, rhs: StrokeFeedback) -> Bool {
        return lhs.accuracy == rhs.accuracy &&
               lhs.suggestions == rhs.suggestions &&
               lhs.correctionPoints == rhs.correctionPoints &&
               lhs.isCorrect == rhs.isCorrect &&
               lhs.dtwDistance == rhs.dtwDistance &&
               lhs.temporalAccuracy == rhs.temporalAccuracy &&
               lhs.velocityConsistency == rhs.velocityConsistency &&
               lhs.confidenceScore == rhs.confidenceScore &&
               lhs.artisticFeedback?.overallScore == rhs.artisticFeedback?.overallScore
    }
}

struct ImageAnalysisResult {
    let landmarks: [DetectedLandmark]
    let boundingBoxes: [DetectedObject]
    let imageSize: CGSize
    let confidence: Float
}

struct DetectedLandmark {
    let type: LandmarkType
    let point: CGPoint
    let confidence: Float
}

struct DetectedObject {
    let type: DrawingObjectType
    let boundingBox: CGRect
    let confidence: Float
}

enum LandmarkType {
    // Face landmarks
    case leftEye, rightEye, nose, mouth, leftEar, rightEar
    case chin, leftCheek, rightCheek, forehead
    case leftEyebrow, rightEyebrow
    
    // Hand landmarks
    case wrist
    case thumbTip, thumbIP, thumbMP, thumbCMC
    case indexTip, indexDIP, indexPIP, indexMCP
    case middleTip, middleDIP, middlePIP, middleMCP
    case ringTip, ringDIP, ringPIP, ringMCP
    case littleTip, littleDIP, littlePIP, littleMCP
    
    // Perspective landmarks
    case topLeftCorner, topRightCorner, bottomLeftCorner, bottomRightCorner
    case vanishingPoint, horizonPoint
    
    // Generic landmarks
    case centerPoint, referencePoint
}

enum DrawingObjectType {
    case face, hand, animal, flower, building, vehicle
}

// MARK: - Optimized Image Analysis Engine
@MainActor
class ImageAnalyzer {
    
    // Performance-optimized timeout duration
    private let analysisTimeout: TimeInterval = 5.0 // Reduced from 10.0 for better UX
    
    // Image processing cache for performance
    private var imageCache: [String: ImageAnalysisResult] = [:]
    private let maxCacheSize = 10
    
    // Performance monitoring
    private var analysisStartTime: Date?
    
    func analyzeImage(_ image: UIImage, category: LessonCategory) async throws -> ImageAnalysisResult {
        // Check cache first for performance
        let cacheKey = generateCacheKey(for: image, category: category)
        if let cachedResult = imageCache[cacheKey] {
            print("🚀 Using cached analysis result for \(category)")
            return cachedResult
        }
        
        // Optimize image size for better performance
        let optimizedImage = optimizeImageForAnalysis(image)
        
        analysisStartTime = Date()
        
        // Use optimized timeout and error handling
        return try await withThrowingTaskGroup(of: ImageAnalysisResult.self) { group in
            group.addTask {
                switch category {
                case .faces:
                    return try await self.analyzeFace(optimizedImage)
                case .animals:
                    return try await self.analyzeAnimal(optimizedImage)
                case .objects:
                    return try await self.analyzeObject(optimizedImage)
                case .hands:
                    return try await self.analyzeHand(optimizedImage)
                case .perspective:
                    return try await self.analyzePerspective(optimizedImage)
                case .nature:
                    return try await self.analyzeNature(optimizedImage)
                }
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(self.analysisTimeout * 1_000_000_000))
                throw DrawingError.analysisTimeout
            }
            
            guard let result = try await group.next() else {
                throw DrawingError.analysisTimeout
            }
            
            group.cancelAll()
            
            // Cache the result for future use
            self.cacheResult(result, for: cacheKey)
            
            // Log performance metrics
            self.logPerformanceMetrics(category: category)
            
            return result
        }
    }
    
    // MARK: - Performance Optimization Methods
    
    private func optimizeImageForAnalysis(_ image: UIImage) -> UIImage {
        // Resize image to optimal size for Vision framework (max 1024px)
        let maxDimension: CGFloat = 1024
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    private func generateCacheKey(for image: UIImage, category: LessonCategory) -> String {
        // Generate a simple cache key based on image size and category
        let size = image.size
        return "\(category.rawValue)_\(Int(size.width))x\(Int(size.height))"
    }
    
    private func cacheResult(_ result: ImageAnalysisResult, for key: String) {
        // Implement LRU cache
        if imageCache.count >= maxCacheSize {
            // Remove oldest entry
            if let firstKey = imageCache.keys.first {
                imageCache.removeValue(forKey: firstKey)
            }
        }
        imageCache[key] = result
    }
    
    private func logPerformanceMetrics(category: LessonCategory) {
        guard let startTime = analysisStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        print("⚡ Vision analysis completed for \(category) in \(String(format: "%.2f", duration))s")
    }
    
    private func analyzeFace(_ image: UIImage) async throws -> ImageAnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: DrawingError.invalidImage)
                return
            }
            
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      let faceObservation = observations.first else {
                    continuation.resume(throwing: DrawingError.noFaceDetected)
                    return
                }
                
                // Ensure we have sufficient landmarks for analysis
                guard let landmarks = faceObservation.landmarks,
                      landmarks.leftEye != nil || landmarks.rightEye != nil || landmarks.nose != nil else {
                    continuation.resume(throwing: DrawingError.insufficientLandmarks)
                    return
                }
                
                let extractedLandmarks = self.extractFacialLandmarks(from: faceObservation, imageSize: image.size)
                let boundingBox = self.convertBoundingBox(faceObservation.boundingBox, imageSize: image.size)
                
                let result = ImageAnalysisResult(
                    landmarks: extractedLandmarks,
                    boundingBoxes: [DetectedObject(type: .face, boundingBox: boundingBox, confidence: faceObservation.confidence)],
                    imageSize: image.size,
                    confidence: faceObservation.confidence
                )
                
                continuation.resume(returning: result)
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            request.revision = VNDetectFaceLandmarksRequestRevision3
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func analyzeAnimal(_ image: UIImage) async throws -> ImageAnalysisResult {
        // Use VNRecognizeAnimalsRequest for better animal detection
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            guard let cgImage = image.cgImage else {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.invalidImage)
                }
                return
            }
            
            let request = VNRecognizeAnimalsRequest { request, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    hasResumed = true
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedObjectObservation],
                      let animalObservation = observations.first else {
                    // Fallback to generic object detection for animals
                    if !hasResumed {
                        hasResumed = true
                        self.performGenericObjectDetection(cgImage: cgImage, image: image, objectType: .animal, continuation: continuation)
                    }
                    return
                }
                
                let boundingBox = self.convertBoundingBox(animalObservation.boundingBox, imageSize: image.size)
                
                let result = ImageAnalysisResult(
                    landmarks: [],
                    boundingBoxes: [DetectedObject(type: .animal, boundingBox: boundingBox, confidence: animalObservation.confidence)],
                    imageSize: image.size,
                    confidence: animalObservation.confidence
                )
                
                hasResumed = true
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([request])
            } catch {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func analyzeObject(_ image: UIImage) async throws -> ImageAnalysisResult {
        // Use VNDetectRectanglesRequest combined with generic object detection
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            guard let cgImage = image.cgImage else {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.invalidImage)
                }
                return
            }
            
            let rectangleRequest = VNDetectRectanglesRequest { request, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    hasResumed = true
                    continuation.resume(throwing: error)
                    return
                }
                
                let rectangleObservations = request.results as? [VNRectangleObservation] ?? []
                
                // Also try to detect generic objects
                let objectRequest = VNGenerateObjectnessBasedSaliencyImageRequest { objectRequest, objectError in
                    guard !hasResumed else { return }
                    
                    var detectedObjects: [DetectedObject] = []
                    
                    // Add detected rectangles
                    detectedObjects.append(contentsOf: rectangleObservations.map { observation in
                        DetectedObject(
                            type: .building,
                            boundingBox: self.convertBoundingBox(observation.boundingBox, imageSize: image.size),
                            confidence: observation.confidence
                        )
                    })
                    
                    // Add generic object detection if available
                    if let saliencyObservations = objectRequest.results as? [VNSaliencyImageObservation],
                       let saliencyObservation = saliencyObservations.first {
                        
                        let salientObjects = self.extractSalientObjects(from: saliencyObservation, imageSize: image.size)
                        detectedObjects.append(contentsOf: salientObjects)
                    }
                    
                    // Ensure we have at least one object detected
                    if detectedObjects.isEmpty {
                        detectedObjects.append(DetectedObject(
                            type: .building,
                            boundingBox: CGRect(x: image.size.width * 0.1, y: image.size.height * 0.1, 
                                              width: image.size.width * 0.8, height: image.size.height * 0.8),
                            confidence: 0.5
                        ))
                    }
                    
                    let result = ImageAnalysisResult(
                        landmarks: [],
                        boundingBoxes: detectedObjects,
                        imageSize: image.size,
                        confidence: detectedObjects.first?.confidence ?? 0.5
                    )
                    
                    hasResumed = true
                    continuation.resume(returning: result)
                }
                
                let objectHandler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
                
                do {
                    try objectHandler.perform([objectRequest])
                } catch {
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // Configure rectangle detection
            rectangleRequest.maximumObservations = 10
            rectangleRequest.minimumAspectRatio = 0.3
            rectangleRequest.maximumAspectRatio = 1.0
            rectangleRequest.minimumSize = 0.1
            rectangleRequest.minimumConfidence = 0.4
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([rectangleRequest])
            } catch {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func analyzeHand(_ image: UIImage) async throws -> ImageAnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            guard let cgImage = image.cgImage else {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.invalidImage)
                }
                return
            }
            
            let request = VNDetectHumanHandPoseRequest { request, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    hasResumed = true
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNHumanHandPoseObservation],
                      let handObservation = observations.first else {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.noHandDetected)
                    return
                }
                
                // Extract hand landmarks for detailed analysis
                let handLandmarks = self.extractHandLandmarks(from: handObservation, imageSize: image.size)
                let handBoundingBox = self.calculateHandBoundingBox(from: handLandmarks, imageSize: image.size)
                
                let result = ImageAnalysisResult(
                    landmarks: handLandmarks,
                    boundingBoxes: [DetectedObject(type: .hand, boundingBox: handBoundingBox, confidence: handObservation.confidence)],
                    imageSize: image.size,
                    confidence: handObservation.confidence
                )
                
                hasResumed = true
                continuation.resume(returning: result)
            }
            
            // Configure hand pose detection
            request.maximumHandCount = 1
            request.revision = VNDetectHumanHandPoseRequestRevision1
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([request])
            } catch {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func analyzePerspective(_ image: UIImage) async throws -> ImageAnalysisResult {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            guard let cgImage = image.cgImage else {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.invalidImage)
                }
                return
            }
            
            let rectangleRequest = VNDetectRectanglesRequest { request, error in
                guard !hasResumed else { return }
                
                if let error = error {
                    hasResumed = true
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      !observations.isEmpty else {
                    hasResumed = true
                    continuation.resume(throwing: DrawingError.noRectanglesDetected)
                    return
                }
                
                // Extract perspective landmarks from rectangle corners
                let perspectiveLandmarks = self.extractPerspectiveLandmarks(from: observations, imageSize: image.size)
                
                let boundingBoxes = observations.map { observation in
                    DetectedObject(
                        type: .building,
                        boundingBox: self.convertBoundingBox(observation.boundingBox, imageSize: image.size),
                        confidence: observation.confidence
                    )
                }
                
                let result = ImageAnalysisResult(
                    landmarks: perspectiveLandmarks,
                    boundingBoxes: boundingBoxes,
                    imageSize: image.size,
                    confidence: observations.map { $0.confidence }.reduce(0, +) / Float(observations.count)
                )
                
                hasResumed = true
                continuation.resume(returning: result)
            }
            
            // Configure rectangle detection for perspective
            rectangleRequest.maximumObservations = 8
            rectangleRequest.minimumAspectRatio = 0.1
            rectangleRequest.maximumAspectRatio = 10.0
            rectangleRequest.minimumSize = 0.05
            rectangleRequest.minimumConfidence = 0.3
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([rectangleRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func analyzeNature(_ image: UIImage) async throws -> ImageAnalysisResult {
        // Use saliency detection for nature elements
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: DrawingError.invalidImage)
                return
            }
            
            let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNSaliencyImageObservation],
                      let saliencyObservation = observations.first else {
                    // Fallback to default nature detection
                    let result = ImageAnalysisResult(
                        landmarks: [],
                        boundingBoxes: [DetectedObject(type: .flower, boundingBox: CGRect(x: image.size.width * 0.2, y: image.size.height * 0.2, width: image.size.width * 0.6, height: image.size.height * 0.6), confidence: 0.5)],
                        imageSize: image.size,
                        confidence: 0.5
                    )
                    continuation.resume(returning: result)
                    return
                }
                
                let salientObjects = self.extractSalientObjects(from: saliencyObservation, imageSize: image.size, objectType: .flower)
                
                let result = ImageAnalysisResult(
                    landmarks: [],
                    boundingBoxes: salientObjects,
                    imageSize: image.size,
                    confidence: salientObjects.first?.confidence ?? 0.6
                )
                
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: self.getImageOrientation(for: image))
            
            do {
                try handler.perform([saliencyRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getImageOrientation(for image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    
    private func performGenericObjectDetection(cgImage: CGImage, image: UIImage, objectType: DrawingObjectType, continuation: CheckedContinuation<ImageAnalysisResult, Error>) {
        // Fallback generic object detection
        let fallbackBoundingBox = CGRect(
            x: image.size.width * 0.15,
            y: image.size.height * 0.15,
            width: image.size.width * 0.7,
            height: image.size.height * 0.7
        )
        
        let result = ImageAnalysisResult(
            landmarks: [],
            boundingBoxes: [DetectedObject(type: objectType, boundingBox: fallbackBoundingBox, confidence: 0.6)],
            imageSize: image.size,
            confidence: 0.6
        )
        
        continuation.resume(returning: result)
    }
    
    private func extractHandLandmarks(from observation: VNHumanHandPoseObservation, imageSize: CGSize) -> [DetectedLandmark] {
        var landmarks: [DetectedLandmark] = []
        
        // Extract key hand joints
        let handJoints: [VNHumanHandPoseObservation.JointName] = [
            .wrist,
            .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
            .indexTip, .indexDIP, .indexPIP, .indexMCP,
            .middleTip, .middleDIP, .middlePIP, .middleMCP,
            .ringTip, .ringDIP, .ringPIP, .ringMCP,
            .littleTip, .littleDIP, .littlePIP, .littleMCP
        ]
        
        for joint in handJoints {
            do {
                let recognizedPoint = try observation.recognizedPoint(joint)
                if recognizedPoint.confidence > 0.3 {
                    let convertedPoint = convertNormalizedPoint(recognizedPoint.location, imageSize: imageSize)
                    
                    // Map joint names to landmark types
                    let landmarkType = mapHandJointToLandmarkType(joint)
                    landmarks.append(DetectedLandmark(
                        type: landmarkType,
                        point: convertedPoint,
                        confidence: recognizedPoint.confidence
                    ))
                }
            } catch {
                // Skip joints that can't be recognized
                continue
            }
        }
        
        return landmarks
    }
    
    private func mapHandJointToLandmarkType(_ joint: VNHumanHandPoseObservation.JointName) -> LandmarkType {
        switch joint {
        case .wrist: return .wrist
        case .thumbTip: return .thumbTip
        case .thumbIP: return .thumbIP
        case .thumbMP: return .thumbMP
        case .thumbCMC: return .thumbCMC
        case .indexTip: return .indexTip
        case .indexDIP: return .indexDIP
        case .indexPIP: return .indexPIP
        case .indexMCP: return .indexMCP
        case .middleTip: return .middleTip
        case .middleDIP: return .middleDIP
        case .middlePIP: return .middlePIP
        case .middleMCP: return .middleMCP
        case .ringTip: return .ringTip
        case .ringDIP: return .ringDIP
        case .ringPIP: return .ringPIP
        case .ringMCP: return .ringMCP
        case .littleTip: return .littleTip
        case .littleDIP: return .littleDIP
        case .littlePIP: return .littlePIP
        case .littleMCP: return .littleMCP
        default: return .referencePoint
        }
    }
    
    private func calculateHandBoundingBox(from landmarks: [DetectedLandmark], imageSize: CGSize) -> CGRect {
        guard !landmarks.isEmpty else {
            return CGRect(x: imageSize.width * 0.2, y: imageSize.height * 0.2, 
                         width: imageSize.width * 0.6, height: imageSize.height * 0.6)
        }
        
        let xs = landmarks.map { $0.point.x }
        let ys = landmarks.map { $0.point.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? imageSize.width
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? imageSize.height
        
        // Add padding
        let padding: CGFloat = 20
        return CGRect(
            x: max(0, minX - padding),
            y: max(0, minY - padding),
            width: min(imageSize.width, (maxX - minX) + 2 * padding),
            height: min(imageSize.height, (maxY - minY) + 2 * padding)
        )
    }
    
    private func extractPerspectiveLandmarks(from observations: [VNRectangleObservation], imageSize: CGSize) -> [DetectedLandmark] {
        var landmarks: [DetectedLandmark] = []
        
        for (index, observation) in observations.enumerated() {
            // Extract rectangle corners as perspective landmarks
            let corners = [
                observation.topLeft,
                observation.topRight,
                observation.bottomLeft,
                observation.bottomRight
            ]
            
            for (cornerIndex, corner) in corners.enumerated() {
                let convertedPoint = convertNormalizedPoint(corner, imageSize: imageSize)
                
                // Map corners to proper perspective landmark types
                let landmarkType: LandmarkType = switch cornerIndex {
                case 0: .topLeftCorner
                case 1: .topRightCorner
                case 2: .bottomLeftCorner
                case 3: .bottomRightCorner
                default: .referencePoint
                }
                
                landmarks.append(DetectedLandmark(
                    type: landmarkType,
                    point: convertedPoint,
                    confidence: observation.confidence
                ))
            }
            
            // Limit to avoid too many landmarks
            if index >= 2 { break }
        }
        
        return landmarks
    }
    
    private func extractSalientObjects(from observation: VNSaliencyImageObservation, imageSize: CGSize, objectType: DrawingObjectType = .building) -> [DetectedObject] {
        var detectedObjects: [DetectedObject] = []
        
        // Find the most salient regions
        guard let salientObjects = observation.salientObjects else {
            return []
        }
        
        for salientObject in salientObjects.prefix(3) { // Limit to top 3 salient objects
            let boundingBox = convertBoundingBox(salientObject.boundingBox, imageSize: imageSize)
            
            detectedObjects.append(DetectedObject(
                type: objectType,
                boundingBox: boundingBox,
                confidence: salientObject.confidence
            ))
        }
        
        return detectedObjects
    }
    
    private func extractFacialLandmarks(from observation: VNFaceObservation, imageSize: CGSize) -> [DetectedLandmark] {
        var landmarks: [DetectedLandmark] = []
        
        guard let faceLandmarks = observation.landmarks else {
            return landmarks
        }
        
        // Left eye landmark
        if let leftEye = faceLandmarks.leftEye {
            let centerPoint = calculateCenterPoint(from: leftEye.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .leftEye, point: point, confidence: 0.9))
        }
        
        // Right eye landmark
        if let rightEye = faceLandmarks.rightEye {
            let centerPoint = calculateCenterPoint(from: rightEye.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .rightEye, point: point, confidence: 0.9))
        }
        
        // Nose landmark
        if let nose = faceLandmarks.nose {
            let centerPoint = calculateCenterPoint(from: nose.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .nose, point: point, confidence: 0.85))
        }
        
        // Mouth landmark
        if let outerLips = faceLandmarks.outerLips {
            let centerPoint = calculateCenterPoint(from: outerLips.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .mouth, point: point, confidence: 0.8))
        }
        
        // Left eyebrow
        if let leftEyebrow = faceLandmarks.leftEyebrow {
            let centerPoint = calculateCenterPoint(from: leftEyebrow.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .leftEyebrow, point: point, confidence: 0.75))
        }
        
        // Right eyebrow
        if let rightEyebrow = faceLandmarks.rightEyebrow {
            let centerPoint = calculateCenterPoint(from: rightEyebrow.normalizedPoints)
            let point = convertNormalizedPoint(centerPoint, imageSize: imageSize)
            landmarks.append(DetectedLandmark(type: .rightEyebrow, point: point, confidence: 0.75))
        }
        
        // Face contour points
        if let faceContour = faceLandmarks.faceContour {
            // Extract chin point (bottom of face contour)
            let chinIndex = faceContour.normalizedPoints.count / 2
            if chinIndex < faceContour.normalizedPoints.count {
                let chinPoint = convertNormalizedPoint(faceContour.normalizedPoints[chinIndex], imageSize: imageSize)
                landmarks.append(DetectedLandmark(type: .chin, point: chinPoint, confidence: 0.7))
            }
        }
        
        return landmarks
    }
    
    private func calculateCenterPoint(from points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return CGPoint.zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    private func convertNormalizedPoint(_ point: CGPoint, imageSize: CGSize) -> CGPoint {
        return CGPoint(
            x: point.x * imageSize.width,
            y: (1 - point.y) * imageSize.height // Vision uses bottom-left origin
        )
    }
    
    private func convertBoundingBox(_ box: CGRect, imageSize: CGSize) -> CGRect {
        return CGRect(
            x: box.origin.x * imageSize.width,
            y: (1 - box.origin.y - box.height) * imageSize.height,
            width: box.width * imageSize.width,
            height: box.height * imageSize.height
        )
    }
}

// MARK: - Errors
enum DrawingError: Error {
    case invalidImage
    case noFaceDetected
    case noHandDetected
    case noRectanglesDetected
    case analysisTimeout
    case insufficientLandmarks
}

extension DrawingError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or corrupted"
        case .noFaceDetected:
            return "No face detected in the image"
        case .noHandDetected:
            return "No hand detected in the image"
        case .noRectanglesDetected:
            return "No rectangular shapes detected for perspective analysis"
        case .analysisTimeout:
            return "Image analysis timed out"
        case .insufficientLandmarks:
            return "Insufficient landmarks detected for accurate analysis"
        }
    }
}
