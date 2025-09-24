import Foundation
import Vision
import UIKit
import SwiftUI

// MARK: - Vision-Powered Lesson Analyzer
@MainActor
class VisionLessonAnalyzer {
    
    // MARK: - Analysis Configuration
    private struct AnalysisConfig {
        static let faceConfidenceThreshold: Float = 0.7
        static let objectConfidenceThreshold: Float = 0.6
        static let textConfidenceThreshold: Float = 0.8
        static let rectangleConfidenceThreshold: Float = 0.5
        static let maxAnalysisTime: TimeInterval = 10.0
        
        // ENHANCED: Content moderation thresholds
        static let contentModerationEnabled = true
        static let nsfwConfidenceThreshold: Float = 0.8
        static let violenceConfidenceThreshold: Float = 0.7
        static let inappropriateContentThreshold: Float = 0.6
    }
    
    // MARK: - Main Lesson Generation
    
    /// Generate a complete lesson from an image using comprehensive Vision analysis
    func generateLesson(from image: UIImage) async throws -> Lesson {
        guard let cgImage = image.cgImage else {
            throw VisionAnalysisError.invalidImage
        }
        
        // ENHANCED: Perform content moderation first
        if AnalysisConfig.contentModerationEnabled {
            let moderationResult = try await performContentModeration(cgImage)
            if moderationResult.isInappropriate {
                throw VisionAnalysisError.inappropriateContent(moderationResult.reason ?? "Inappropriate content detected")
            }
        }
        
        // Perform comprehensive analysis
        let analysisResult = try await performComprehensiveAnalysis(cgImage)
        
        // Generate lesson based on analysis
        let lesson = createLesson(from: analysisResult, sourceImage: image)
        
        return lesson
    }
    
    /// Generate multiple lesson variations from a single image
    func generateLessonVariations(from image: UIImage, count: Int) async throws -> [Lesson] {
        guard let cgImage = image.cgImage else {
            throw VisionAnalysisError.invalidImage
        }
        
        let analysisResult = try await performComprehensiveAnalysis(cgImage)
        var variations: [Lesson] = []
        
        // Generate different lesson types based on detected content
        if analysisResult.faces.count > 0 {
            variations.append(createPortraitLesson(from: analysisResult, sourceImage: image))
            variations.append(createFacialFeaturesLesson(from: analysisResult, sourceImage: image))
        }
        
        if analysisResult.objects.count > 0 {
            variations.append(createStillLifeLesson(from: analysisResult, sourceImage: image))
        }
        
        if analysisResult.rectangles.count > 0 {
            variations.append(createPerspectiveLesson(from: analysisResult, sourceImage: image))
        }
        
        if analysisResult.text.count > 0 {
            variations.append(createLetteringLesson(from: analysisResult, sourceImage: image))
        }
        
        // If no specific content detected, create general drawing lessons
        if variations.isEmpty {
            variations.append(createGeneralDrawingLesson(from: analysisResult, sourceImage: image))
        }
        
        return Array(variations.prefix(count))
    }
    
    /// Analyze image to determine lesson requirements
    func analyzeLessonRequirements(for image: UIImage) async throws -> LessonRequirements {
        guard let cgImage = image.cgImage else {
            throw VisionAnalysisError.invalidImage
        }
        
        let analysisResult = try await performComprehensiveAnalysis(cgImage)
        return determineLessonRequirements(from: analysisResult)
    }
    
    /// Generate adaptive lesson based on user performance
    func generateAdaptiveLesson(basedOn performance: UserPerformanceData, category: LessonCategory) async throws -> Lesson {
        // Create adaptive lesson content based on user's strengths and weaknesses
        let difficulty = determineAdaptiveDifficulty(from: performance)
        let focusAreas = identifyFocusAreas(from: performance)
        
        return createAdaptiveLesson(
            category: category,
            difficulty: difficulty,
            focusAreas: focusAreas,
            performance: performance
        )
    }
    
    // MARK: - Content Moderation
    
    private func performContentModeration(_ cgImage: CGImage) async throws -> ContentModerationResult {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            // Use Vision framework's classification capabilities for content moderation
            let request = VNClassifyImageRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ContentModerationResult(isInappropriate: false, reason: nil))
                    return
                }
                
                // Check for inappropriate content categories
                let inappropriateCategories = [
                    "Explicit Nudity", "Sexual Activity", "Violence", "Gore",
                    "Weapons", "Drugs", "Alcohol", "Tobacco"
                ]
                
                for observation in observations {
                    if inappropriateCategories.contains(observation.identifier) {
                        if observation.confidence >= AnalysisConfig.inappropriateContentThreshold {
                            continuation.resume(returning: ContentModerationResult(
                                isInappropriate: true,
                                reason: "Detected \(observation.identifier) with confidence \(observation.confidence)"
                            ))
                            return
                        }
                    }
                }
                
                continuation.resume(returning: ContentModerationResult(isInappropriate: false, reason: nil))
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Comprehensive Vision Analysis
    
    private func performComprehensiveAnalysis(_ cgImage: CGImage) async throws -> VisionAnalysisResult {
        // Perform all vision analyses in parallel for efficiency
        async let faceResults = detectFaces(in: cgImage)
        async let objectResults = detectObjects(in: cgImage)
        async let textResults = detectText(in: cgImage)
        async let rectangleResults = detectRectangles(in: cgImage)
        async let saliencyResults = detectSalientObjects(in: cgImage)
        
        let faces = try await faceResults
        let objects = try await objectResults
        let text = try await textResults
        let rectangles = try await rectangleResults
        let salientObjects = try await saliencyResults
        
        return VisionAnalysisResult(
            faces: faces,
            objects: objects,
            text: text,
            rectangles: rectangles,
            salientObjects: salientObjects,
            imageSize: CGSize(width: cgImage.width, height: cgImage.height)
        )
    }
    
    // MARK: - Individual Vision Analysis Methods
    
    private func detectFaces(in cgImage: CGImage) async throws -> [DetectedFace] {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let faces = observations.compactMap { observation -> DetectedFace? in
                    guard observation.confidence >= AnalysisConfig.faceConfidenceThreshold else { return nil }
                    
                    return DetectedFace(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        landmarks: self.extractFaceLandmarks(from: observation)
                    )
                }
                
                continuation.resume(returning: faces)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectObjects(in cgImage: CGImage) async throws -> [VisionDetectedObject] {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let request = VNGenerateObjectnessBasedSaliencyImageRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNSaliencyImageObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var objects: [VisionDetectedObject] = []
                for observation in observations {
                    if let salientObjects = observation.salientObjects {
                        for salientObject in salientObjects {
                            if salientObject.confidence >= AnalysisConfig.objectConfidenceThreshold {
                                objects.append(VisionDetectedObject(
                                    boundingBox: salientObject.boundingBox,
                                    confidence: salientObject.confidence,
                                    objectType: .unknown
                                ))
                            }
                        }
                    }
                }
                
                continuation.resume(returning: objects)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectText(in cgImage: CGImage) async throws -> [DetectedText] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let textElements = observations.compactMap { observation -> DetectedText? in
                    guard observation.confidence >= AnalysisConfig.textConfidenceThreshold else { return nil }
                    
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    
                    return DetectedText(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence
                    )
                }
                
                continuation.resume(returning: textElements)
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectRectangles(in cgImage: CGImage) async throws -> [DetectedRectangle] {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let request = VNDetectRectanglesRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let rectangles = observations.compactMap { observation -> DetectedRectangle? in
                    guard observation.confidence >= AnalysisConfig.rectangleConfidenceThreshold else { return nil }
                    
                    return DetectedRectangle(
                        boundingBox: observation.boundingBox,
                        confidence: observation.confidence,
                        corners: [
                            observation.topLeft,
                            observation.topRight,
                            observation.bottomRight,
                            observation.bottomLeft
                        ]
                    )
                }
                
                continuation.resume(returning: rectangles)
            }
            
            request.maximumObservations = 10
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.1
            request.minimumConfidence = AnalysisConfig.rectangleConfidenceThreshold
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectSalientObjects(in cgImage: CGImage) async throws -> [DetectedSalientObject] {
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                guard !hasResumed else { return }
                hasResumed = true
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNSaliencyImageObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var salientObjects: [DetectedSalientObject] = []
                for observation in observations {
                    if let objects = observation.salientObjects {
                        for obj in objects {
                            salientObjects.append(DetectedSalientObject(
                                boundingBox: obj.boundingBox,
                                confidence: obj.confidence
                            ))
                        }
                    }
                }
                
                continuation.resume(returning: salientObjects)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Lesson Creation Methods
    
    private func createLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        // Determine primary lesson type based on analysis
        if !analysis.faces.isEmpty {
            return createPortraitLesson(from: analysis, sourceImage: sourceImage)
        } else if !analysis.rectangles.isEmpty {
            return createPerspectiveLesson(from: analysis, sourceImage: sourceImage)
        } else if !analysis.text.isEmpty {
            return createLetteringLesson(from: analysis, sourceImage: sourceImage)
        } else if !analysis.objects.isEmpty {
            return createStillLifeLesson(from: analysis, sourceImage: sourceImage)
        } else {
            return createGeneralDrawingLesson(from: analysis, sourceImage: sourceImage)
        }
    }
    
    private func createPortraitLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        let faceCount = analysis.faces.count
        let title = faceCount == 1 ? "Portrait Drawing from Photo" : "Group Portrait from Photo"
        let description = faceCount == 1 ? 
            "Learn to draw a portrait by analyzing facial proportions and features from this photo." :
            "Practice drawing multiple faces and their relationships in this group portrait."
        
        let steps = createPortraitSteps(faceCount: faceCount)
        
        return Lesson(
            title: title,
            description: description,
            category: .faces,
            difficulty: faceCount > 1 ? .intermediate : .beginner,
            thumbnailImageName: "portrait_generated",
            referenceImageName: "portrait_generated",
            estimatedTime: 20 + (faceCount * 10),
            isPremium: false,
            steps: steps
        )
    }
    
    private func createFacialFeaturesLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        return Lesson(
            title: "Facial Features Study",
            description: "Focus on individual facial features - eyes, nose, mouth, and their proportions.",
            category: .faces,
            difficulty: .intermediate,
            thumbnailImageName: "features_generated",
            referenceImageName: "features_generated",
            estimatedTime: 25,
            isPremium: false,
            steps: createFacialFeatureSteps()
        )
    }
    
    private func createStillLifeLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        return Lesson(
            title: "Still Life from Photo",
            description: "Draw the objects in this photo, focusing on form, light, and composition.",
            category: .objects,
            difficulty: .intermediate,
            thumbnailImageName: "stilllife_generated",
            referenceImageName: "stilllife_generated",
            estimatedTime: 30,
            isPremium: false,
            steps: createStillLifeSteps()
        )
    }
    
    private func createPerspectiveLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        return Lesson(
            title: "Perspective Drawing from Photo",
            description: "Learn perspective drawing using the geometric shapes and lines detected in this photo.",
            category: .perspective,
            difficulty: .advanced,
            thumbnailImageName: "perspective_generated",
            referenceImageName: "perspective_generated",
            estimatedTime: 35,
            isPremium: true,
            steps: createPerspectiveSteps()
        )
    }
    
    private func createLetteringLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        let detectedText = analysis.text.map { $0.text }.joined(separator: " ")
        
        return Lesson(
            title: "Lettering Practice",
            description: "Practice lettering and typography based on the text found in this image: '\(detectedText)'",
            category: .objects, // Using objects as closest category
            difficulty: .intermediate,
            thumbnailImageName: "lettering_generated",
            referenceImageName: "lettering_generated",
            estimatedTime: 20,
            isPremium: false,
            steps: createLetteringSteps(text: detectedText)
        )
    }
    
    private func createGeneralDrawingLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage) -> Lesson {
        return Lesson(
            title: "General Drawing from Photo",
            description: "Practice general drawing skills using this photo as reference.",
            category: .objects,
            difficulty: .beginner,
            thumbnailImageName: "general_generated",
            referenceImageName: "general_generated",
            estimatedTime: 25,
            isPremium: false,
            steps: createGeneralDrawingSteps()
        )
    }
    
    // MARK: - Step Creation Methods
    
    private func createPortraitSteps(faceCount: Int) -> [LessonStep] {
        var steps: [LessonStep] = [
            LessonStep(stepNumber: 1, instruction: "Start with basic head shape - draw an oval", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 2, instruction: "Add facial guidelines - horizontal line for eyes", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 3, instruction: "Place the eyes along the eye line", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 4, instruction: "Add the nose shape", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 5, instruction: "Draw the mouth", guidancePoints: [], shapeType: .curve)
        ]
        
        if faceCount > 1 {
            steps.append(LessonStep(stepNumber: 6, instruction: "Repeat for additional faces, maintaining proportions", guidancePoints: [], shapeType: .oval))
        }
        
        return steps
    }
    
    private func createFacialFeatureSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Study the eye shape and iris placement", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 2, instruction: "Observe nose structure and shadows", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 3, instruction: "Analyze mouth shape and lip curves", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 4, instruction: "Add details and refine proportions", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createStillLifeSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Identify basic shapes in the objects", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 2, instruction: "Establish proportions and relationships", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 3, instruction: "Add form and volume with shading", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 4, instruction: "Refine details and textures", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createPerspectiveSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Identify the horizon line", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 2, instruction: "Locate vanishing points", guidancePoints: [], shapeType: .circle),
            LessonStep(stepNumber: 3, instruction: "Draw converging lines to vanishing points", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 4, instruction: "Add rectangular forms in perspective", guidancePoints: [], shapeType: .rectangle)
        ]
    }
    
    private func createLetteringSteps(text: String) -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Establish baseline and x-height", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 2, instruction: "Sketch letter shapes: \(text)", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 3, instruction: "Refine letter spacing and proportions", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 4, instruction: "Add final details and clean up", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createGeneralDrawingSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Observe and sketch the overall composition", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 2, instruction: "Block in major shapes and forms", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 3, instruction: "Add details and refine shapes", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 4, instruction: "Complete with shading and finishing touches", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    // MARK: - Helper Methods
    
    private func extractFaceLandmarks(from observation: VNFaceObservation) -> [FaceLandmark] {
        var landmarks: [FaceLandmark] = []
        
        if let leftEye = observation.landmarks?.leftEye {
            landmarks.append(FaceLandmark(type: .leftEye, points: leftEye.normalizedPoints))
        }
        
        if let rightEye = observation.landmarks?.rightEye {
            landmarks.append(FaceLandmark(type: .rightEye, points: rightEye.normalizedPoints))
        }
        
        if let nose = observation.landmarks?.nose {
            landmarks.append(FaceLandmark(type: .nose, points: nose.normalizedPoints))
        }
        
        if let outerLips = observation.landmarks?.outerLips {
            landmarks.append(FaceLandmark(type: .mouth, points: outerLips.normalizedPoints))
        }
        
        return landmarks
    }
    
    private func determineLessonRequirements(from analysis: VisionAnalysisResult) -> LessonRequirements {
        var category: LessonCategory = .objects
        var difficulty: DifficultyLevel = .beginner
        var estimatedTime: Int = 20
        
        // Determine category based on detected content
        if !analysis.faces.isEmpty {
            category = .faces
            difficulty = analysis.faces.count > 1 ? .intermediate : .beginner
            estimatedTime = 20 + (analysis.faces.count * 10)
        } else if !analysis.rectangles.isEmpty {
            category = .perspective
            difficulty = .advanced
            estimatedTime = 35
        } else if !analysis.objects.isEmpty {
            category = .objects
            difficulty = .intermediate
            estimatedTime = 30
        }
        
        return LessonRequirements(
            category: category,
            difficulty: difficulty,
            estimatedTime: estimatedTime,
            detectedContent: createContentSummary(from: analysis)
        )
    }
    
    private func createContentSummary(from analysis: VisionAnalysisResult) -> String {
        var summary: [String] = []
        
        if !analysis.faces.isEmpty {
            summary.append("\(analysis.faces.count) face(s)")
        }
        
        if !analysis.objects.isEmpty {
            summary.append("\(analysis.objects.count) object(s)")
        }
        
        if !analysis.text.isEmpty {
            summary.append("text elements")
        }
        
        if !analysis.rectangles.isEmpty {
            summary.append("geometric shapes")
        }
        
        return summary.isEmpty ? "general content" : summary.joined(separator: ", ")
    }
    
    private func determineAdaptiveDifficulty(from performance: UserPerformanceData) -> DifficultyLevel {
        let averageAccuracy = performance.averageAccuracy
        
        if averageAccuracy >= 0.8 {
            return .advanced
        } else if averageAccuracy >= 0.6 {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    private func identifyFocusAreas(from performance: UserPerformanceData) -> [String] {
        var focusAreas: [String] = []
        
        if performance.proportionAccuracy < 0.6 {
            focusAreas.append("proportions")
        }
        
        if performance.shapeAccuracy < 0.6 {
            focusAreas.append("basic shapes")
        }
        
        if performance.smoothnessScore < 0.6 {
            focusAreas.append("line quality")
        }
        
        return focusAreas
    }
    
    private func createAdaptiveLesson(
        category: LessonCategory,
        difficulty: DifficultyLevel,
        focusAreas: [String],
        performance: UserPerformanceData
    ) -> Lesson {
        let title = "Adaptive \(category.rawValue.capitalized) Practice"
        let description = "Personalized lesson focusing on: \(focusAreas.joined(separator: ", "))"
        
        return Lesson(
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            thumbnailImageName: "adaptive_generated",
            referenceImageName: "adaptive_generated",
            estimatedTime: 25,
            isPremium: false,
            steps: createAdaptiveSteps(focusAreas: focusAreas)
        )
    }
    
    private func createAdaptiveSteps(focusAreas: [String]) -> [LessonStep] {
        var steps: [LessonStep] = []
        var stepNumber = 1
        
        for focusArea in focusAreas {
            switch focusArea {
            case "proportions":
                steps.append(LessonStep(
                    stepNumber: stepNumber,
                    instruction: "Practice measuring proportions using your pencil",
                    guidancePoints: [],
                    shapeType: .line
                ))
                stepNumber += 1
                
            case "basic shapes":
                steps.append(LessonStep(
                    stepNumber: stepNumber,
                    instruction: "Break down complex forms into simple shapes",
                    guidancePoints: [],
                    shapeType: .rectangle
                ))
                stepNumber += 1
                
            case "line quality":
                steps.append(LessonStep(
                    stepNumber: stepNumber,
                    instruction: "Focus on smooth, confident strokes",
                    guidancePoints: [],
                    shapeType: .curve
                ))
                stepNumber += 1
                
            default:
                break
            }
        }
        
        // Add a final refinement step
        steps.append(LessonStep(
            stepNumber: stepNumber,
            instruction: "Combine all techniques in a final drawing",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
}

// MARK: - Supporting Data Structures

struct VisionAnalysisResult {
    let faces: [DetectedFace]
    let objects: [VisionDetectedObject]
    let text: [DetectedText]
    let rectangles: [DetectedRectangle]
    let salientObjects: [DetectedSalientObject]
    let imageSize: CGSize
}

// ENHANCED: Content moderation result structure
struct ContentModerationResult {
    let isInappropriate: Bool
    let reason: String?
}

struct DetectedFace {
    let boundingBox: CGRect
    let confidence: Float
    let landmarks: [FaceLandmark]
}

struct VisionDetectedObject {
    let boundingBox: CGRect
    let confidence: Float
    let objectType: VisionObjectType
}

struct DetectedText {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

struct DetectedRectangle {
    let boundingBox: CGRect
    let confidence: Float
    let corners: [CGPoint]
}

struct DetectedSalientObject {
    let boundingBox: CGRect
    let confidence: Float
}

struct FaceLandmark {
    let type: FaceLandmarkType
    let points: [CGPoint]
}

enum FaceLandmarkType {
    case leftEye, rightEye, nose, mouth, leftEyebrow, rightEyebrow
}

enum VisionObjectType {
    case unknown, person, animal, vehicle, furniture, food, plant
}

struct LessonRequirements {
    let category: LessonCategory
    let difficulty: DifficultyLevel
    let estimatedTime: Int
    let detectedContent: String
}

struct UserPerformanceData {
    let averageAccuracy: Double
    let proportionAccuracy: Double
    let shapeAccuracy: Double
    let smoothnessScore: Double
    let completedLessons: Int
    let preferredCategories: [LessonCategory]
}

// MARK: - Errors

enum VisionAnalysisError: Error, LocalizedError {
    case invalidImage
    case analysisTimeout
    case noContentDetected
    case analysisFailure(String)
    case inappropriateContent(String) // ENHANCED: Content moderation error
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The provided image is invalid or cannot be processed"
        case .analysisTimeout:
            return "Vision analysis timed out"
        case .noContentDetected:
            return "No recognizable content found in the image"
        case .analysisFailure(let message):
            return "Analysis failed: \(message)"
        case .inappropriateContent(let reason):
            return "Content moderation detected inappropriate content: \(reason)"
        }
    }
}
