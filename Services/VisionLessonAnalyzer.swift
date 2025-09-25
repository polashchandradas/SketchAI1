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
        // ENHANCED: AI-powered lesson generation with nuanced analysis
        let complexity = analyzeImageComplexity(analysis)
        let variations = generateContentSpecificVariations(from: analysis)
        
        // Determine primary lesson type based on sophisticated analysis
        if !analysis.faces.isEmpty {
            return createEnhancedPortraitLesson(from: analysis, sourceImage: sourceImage, complexity: complexity, variations: variations)
        } else if !analysis.rectangles.isEmpty {
            return createEnhancedPerspectiveLesson(from: analysis, sourceImage: sourceImage, complexity: complexity, variations: variations)
        } else if !analysis.text.isEmpty {
            return createEnhancedLetteringLesson(from: analysis, sourceImage: sourceImage, complexity: complexity, variations: variations)
        } else if !analysis.objects.isEmpty {
            return createEnhancedStillLifeLesson(from: analysis, sourceImage: sourceImage, complexity: complexity, variations: variations)
        } else {
            return createEnhancedGeneralDrawingLesson(from: analysis, sourceImage: sourceImage, complexity: complexity, variations: variations)
        }
    }
    
    // MARK: - Enhanced Lesson Creation with Advanced Step Generation
    
    /// Create enhanced portrait lesson with advanced step generation
    private func createEnhancedPortraitLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage, complexity: LessonComplexity, variations: [LessonVariation]) -> Lesson {
        let faceCount = analysis.faces.count
        let title = generateAdaptiveTitle(for: .faces, faceCount: faceCount, complexity: complexity)
        let description = generateAdaptiveDescription(for: .faces, faceCount: faceCount, complexity: complexity, variations: variations)
        
        // ENHANCED: Use advanced step generation
        let steps = generateAdvancedSteps(from: analysis, category: .faces)
        
        // ENHANCED: Adaptive difficulty based on analysis
        let difficulty = determineAdaptiveDifficulty(from: complexity, faceCount: faceCount)
        let estimatedTime = calculateAdaptiveTime(complexity: complexity, faceCount: faceCount)
        
        return Lesson(
            title: title,
            description: description,
            category: .faces,
            difficulty: difficulty,
            thumbnailImageName: "portrait_generated",
            referenceImageName: "portrait_generated",
            estimatedTime: estimatedTime,
            isPremium: complexity == .complex,
            steps: steps
        )
    }
    
    /// Create enhanced perspective lesson with advanced step generation
    private func createEnhancedPerspectiveLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage, complexity: LessonComplexity, variations: [LessonVariation]) -> Lesson {
        let rectangleCount = analysis.rectangles.count
        let title = generateAdaptiveTitle(for: .perspective, rectangleCount: rectangleCount, complexity: complexity)
        let description = generateAdaptiveDescription(for: .perspective, rectangleCount: rectangleCount, complexity: complexity, variations: variations)
        
        // ENHANCED: Use advanced step generation
        let steps = generateAdvancedSteps(from: analysis, category: .perspective)
        
        let difficulty = determineAdaptiveDifficulty(from: complexity, rectangleCount: rectangleCount)
        let estimatedTime = calculateAdaptiveTime(complexity: complexity, rectangleCount: rectangleCount)
        
        return Lesson(
            title: title,
            description: description,
            category: .perspective,
            difficulty: difficulty,
            thumbnailImageName: "perspective_generated",
            referenceImageName: "perspective_generated",
            estimatedTime: estimatedTime,
            isPremium: complexity == .complex,
            steps: steps
        )
    }
    
    /// Create enhanced lettering lesson with advanced step generation
    private func createEnhancedLetteringLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage, complexity: LessonComplexity, variations: [LessonVariation]) -> Lesson {
        let detectedText = analysis.text.map { $0.text }.joined(separator: " ")
        let title = generateAdaptiveTitle(for: .objects, textLength: detectedText.count, complexity: complexity)
        let description = generateAdaptiveDescription(for: .objects, textLength: detectedText.count, complexity: complexity, variations: variations)
        
        // ENHANCED: Use advanced step generation for lettering
        let steps = generateAdvancedSteps(from: analysis, category: .objects)
        
        let difficulty = determineAdaptiveDifficulty(from: complexity, textLength: detectedText.count)
        let estimatedTime = calculateAdaptiveTime(complexity: complexity, textLength: detectedText.count)
        
        return Lesson(
            title: title,
            description: description,
            category: .objects,
            difficulty: difficulty,
            thumbnailImageName: "lettering_generated",
            referenceImageName: "lettering_generated",
            estimatedTime: estimatedTime,
            isPremium: complexity == .complex,
            steps: steps
        )
    }
    
    /// Create enhanced still life lesson with advanced step generation
    private func createEnhancedStillLifeLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage, complexity: LessonComplexity, variations: [LessonVariation]) -> Lesson {
        let objectCount = analysis.objects.count
        let title = generateAdaptiveTitle(for: .objects, objectCount: objectCount, complexity: complexity)
        let description = generateAdaptiveDescription(for: .objects, objectCount: objectCount, complexity: complexity, variations: variations)
        
        // ENHANCED: Use advanced step generation
        let steps = generateAdvancedSteps(from: analysis, category: .objects)
        
        let difficulty = determineAdaptiveDifficulty(from: complexity, objectCount: objectCount)
        let estimatedTime = calculateAdaptiveTime(complexity: complexity, objectCount: objectCount)
        
        return Lesson(
            title: title,
            description: description,
            category: .objects,
            difficulty: difficulty,
            thumbnailImageName: "stilllife_generated",
            referenceImageName: "stilllife_generated",
            estimatedTime: estimatedTime,
            isPremium: complexity == .complex,
            steps: steps
        )
    }
    
    /// Create enhanced general drawing lesson with advanced step generation
    private func createEnhancedGeneralDrawingLesson(from analysis: VisionAnalysisResult, sourceImage: UIImage, complexity: LessonComplexity, variations: [LessonVariation]) -> Lesson {
        let title = generateAdaptiveTitle(for: .objects, complexity: complexity)
        let description = generateAdaptiveDescription(for: .objects, complexity: complexity, variations: variations)
        
        // ENHANCED: Use advanced step generation
        let steps = generateAdvancedSteps(from: analysis, category: .objects)
        
        let difficulty = determineAdaptiveDifficulty(from: complexity)
        let estimatedTime = calculateAdaptiveTime(complexity: complexity)
        
        return Lesson(
            title: title,
            description: description,
            category: .objects,
            difficulty: difficulty,
            thumbnailImageName: "general_generated",
            referenceImageName: "general_generated",
            estimatedTime: estimatedTime,
            isPremium: complexity == .complex,
            steps: steps
        )
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
    
    // MARK: - Enhanced Step Creation Methods with AI-Powered Analysis
    
    private func createPortraitSteps(faceCount: Int) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // ENHANCED: AI-powered step generation based on face analysis
        if faceCount == 1 {
            steps = createSinglePortraitSteps()
        } else {
            steps = createGroupPortraitSteps(faceCount: faceCount)
        }
        
        return steps
    }
    
    // MARK: - Advanced AI-Powered Step Generation
    
    /// Generate sophisticated steps based on content analysis
    private func generateAdvancedSteps(from analysis: VisionAnalysisResult, category: LessonCategory) -> [LessonStep] {
        let complexity = analyzeImageComplexity(analysis)
        let variations = generateContentSpecificVariations(from: analysis)
        
        switch category {
        case .faces:
            return generateAdvancedPortraitSteps(from: analysis, complexity: complexity, variations: variations)
        case .objects:
            return generateAdvancedObjectSteps(from: analysis, complexity: complexity, variations: variations)
        case .perspective:
            return generateAdvancedPerspectiveSteps(from: analysis, complexity: complexity, variations: variations)
        case .animals:
            return generateAdvancedAnimalSteps(from: analysis, complexity: complexity, variations: variations)
        case .hands:
            return generateAdvancedHandSteps(from: analysis, complexity: complexity, variations: variations)
        case .nature:
            return generateAdvancedNatureSteps(from: analysis, complexity: complexity, variations: variations)
        }
    }
    
    /// Generate advanced portrait steps with anatomical accuracy
    private func generateAdvancedPortraitSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Advanced head construction
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ? 
                "Begin with the Loomis method - draw a sphere for the skull, then add the jaw structure. This advanced technique provides a solid foundation for realistic proportions." :
                "Start with a circle for the basic head shape. This forms the foundation of your portrait.",
            guidancePoints: [],
            shapeType: .circle
        ))
        
        // Step 2: Sophisticated facial guidelines
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Add sophisticated facial guidelines - eye line, nose line, and mouth line. These anatomical landmarks ensure proper facial proportions and realistic placement." :
                "Add horizontal guidelines for the eyes, nose, and mouth. These help ensure proper facial proportions.",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 3: Precise eye placement
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Place the eyes using anatomical proportions - they should be one eye-width apart. Draw almond shapes with proper iris and pupil placement." :
                "Draw the eyes using almond shapes. Position them along the eye guideline with proper spacing.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 4: Anatomical nose construction
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Construct the nose using anatomical planes - bridge, nostrils, and tip. Focus on the three-dimensional structure and shadow placement." :
                "Construct the nose using a simple triangular shape. Start with basic geometry, then refine.",
            guidancePoints: [],
            shapeType: .polygon
        ))
        
        // Step 5: Dynamic mouth placement
        steps.append(LessonStep(
            stepNumber: 5,
            instruction: complexity == .complex ?
                "Place the mouth with attention to lip anatomy - upper lip, lower lip, and the philtrum. Consider the expression and mood." :
                "Add the mouth using an oval shape. Pay attention to its width relative to the eyes above.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 6: Advanced facial features
        steps.append(LessonStep(
            stepNumber: 6,
            instruction: complexity == .complex ?
                "Add sophisticated facial features - eyebrows, ears, and facial hair. Focus on the unique characteristics that make this face distinctive." :
                "Add eyebrows and refine facial features",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 7: Final refinement
        steps.append(LessonStep(
            stepNumber: 7,
            instruction: complexity == .complex ?
                "Final refinement with artistic interpretation - add shading, highlights, and personal style. This is where your artistic voice emerges." :
                "Refine the face outline by connecting the features with smooth curves. Erase construction lines.",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    /// Generate advanced object steps with form and light analysis
    private func generateAdvancedObjectSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Composition analysis
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ?
                "Analyze the composition and identify the main objects and their relationships. Consider the rule of thirds and focal points." :
                "Study the composition - identify the main objects and their relationships",
            guidancePoints: [],
            shapeType: .rectangle
        ))
        
        // Step 2: Basic geometric construction
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Start with advanced geometric construction - use ellipses for cylinders, boxes for rectangular forms, and spheres for round objects. This creates a solid foundation." :
                "Start with basic geometric shapes - circles, rectangles, and ovals",
            guidancePoints: [],
            shapeType: .circle
        ))
        
        // Step 3: Proportion and perspective
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Establish accurate proportions using sighting techniques and perspective principles. Measure relationships between objects carefully." :
                "Establish accurate proportions using sighting techniques",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 4: Three-dimensional form
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Add the three-dimensional form to each object, considering how light interacts with different surfaces and materials." :
                "Add the three-dimensional form to each object",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 5: Light and shadow analysis
        steps.append(LessonStep(
            stepNumber: 5,
            instruction: complexity == .complex ?
                "Identify and draw the light source and shadow patterns. Consider cast shadows, form shadows, and reflected light for realistic depth." :
                "Identify and draw the light source and shadows",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 6: Surface textures and materials
        steps.append(LessonStep(
            stepNumber: 6,
            instruction: complexity == .complex ?
                "Add surface textures and material properties - consider how different materials reflect light and create visual interest." :
                "Add surface textures and material properties",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 7: Final refinement
        steps.append(LessonStep(
            stepNumber: 7,
            instruction: complexity == .complex ?
                "Refine details and create depth through value changes, atmospheric perspective, and careful attention to edges and transitions." :
                "Refine details and create depth through value changes",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    /// Generate advanced perspective steps with architectural elements
    private func generateAdvancedPerspectiveSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Horizon line and eye level
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ?
                "Establish the horizon line and your eye level. Consider how this affects the viewer's perspective and the overall composition." :
                "Draw the horizon line across your canvas. This represents your eye level.",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 2: Vanishing points
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Locate the vanishing point(s) on the horizon. For complex scenes, identify one-point, two-point, or three-point perspective systems." :
                "Mark the vanishing point on the horizon line. All perspective lines will converge here.",
            guidancePoints: [],
            shapeType: .circle
        ))
        
        // Step 3: Ground plane and depth
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Draw the ground plane and establish depth using perspective guidelines. Consider how objects diminish in size as they recede." :
                "Draw the ground plane and establish depth",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 4: Basic forms in perspective
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Create the basic rectangular forms using perspective guidelines. Start with simple boxes and build complexity gradually." :
                "Draw the basic rectangular forms using perspective guidelines",
            guidancePoints: [],
            shapeType: .rectangle
        ))
        
        // Step 5: Vertical lines and height
        steps.append(LessonStep(
            stepNumber: 5,
            instruction: complexity == .complex ?
                "Add vertical lines to create height and structure. Ensure all vertical lines remain truly vertical in perspective." :
                "Add vertical lines to create height and structure",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 6: Refinement and accuracy
        steps.append(LessonStep(
            stepNumber: 6,
            instruction: complexity == .complex ?
                "Refine the perspective with accurate proportions and relationships. Double-check that all lines converge properly to their vanishing points." :
                "Refine the perspective with accurate proportions",
            guidancePoints: [],
            shapeType: .rectangle
        ))
        
        // Step 7: Details and architectural elements
        steps.append(LessonStep(
            stepNumber: 7,
            instruction: complexity == .complex ?
                "Add details and architectural elements while maintaining proper perspective. Consider windows, doors, and decorative features." :
                "Add details and architectural elements",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 8: Final shading and depth
        steps.append(LessonStep(
            stepNumber: 8,
            instruction: complexity == .complex ?
                "Final shading and atmospheric perspective for depth. Use value changes to enhance the three-dimensional illusion." :
                "Final shading and atmospheric perspective for depth",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    /// Generate advanced animal steps with anatomical focus
    private func generateAdvancedAnimalSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Basic body structure
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ?
                "Start with the main body structure using an oval. Consider the animal's natural posture and weight distribution." :
                "Start with the main body shape using an oval. This establishes the animal's core mass.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 2: Head placement and proportions
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Add the head using a circle or oval. Consider the animal's proportions relative to the body and its characteristic features." :
                "Add the head using a circle or oval. Consider the animal's proportions relative to the body.",
            guidancePoints: [],
            shapeType: .circle
        ))
        
        // Step 3: Limb construction
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Sketch the basic limb structure using simple lines and ovals for joints. Pay attention to the animal's natural stance and movement." :
                "Sketch the basic limb structure using simple lines and ovals for joints.",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 4: Facial features
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Add facial features and details like ears, eyes, and distinctive characteristics. Focus on what makes this animal unique." :
                "Add facial features and details like ears, eyes, and distinctive characteristics.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 5: Body details and texture
        steps.append(LessonStep(
            stepNumber: 5,
            instruction: complexity == .complex ?
                "Add body details and consider the animal's fur, scales, or skin texture. This brings the drawing to life." :
                "Add body details and consider the animal's fur or skin texture.",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    /// Generate advanced hand steps with anatomical accuracy
    private func generateAdvancedHandSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Palm construction
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ?
                "Start with a rectangular shape for the palm. Consider the hand's natural curve and the relationship between palm and fingers." :
                "Start with a rectangular shape for the palm. This forms the foundation of the hand.",
            guidancePoints: [],
            shapeType: .rectangle
        ))
        
        // Step 2: Finger guidelines
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Add guidelines for finger length and positioning. Fingers have specific proportional relationships and natural curves." :
                "Add guidelines for finger length and positioning. Fingers have specific proportional relationships.",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 3: Finger shapes
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Draw individual finger shapes using rectangles and ovals. Each finger has three segments with specific proportions." :
                "Draw individual finger shapes using rectangles and ovals. Each finger has three segments.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 4: Thumb placement
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Add thumb placement and consider its unique range of motion. The thumb is crucial for hand expression and gesture." :
                "Add thumb placement and consider its unique range of motion.",
            guidancePoints: [],
            shapeType: .oval
        ))
        
        // Step 5: Final refinement
        steps.append(LessonStep(
            stepNumber: 5,
            instruction: complexity == .complex ?
                "Refine the hand outline, connect the fingers smoothly, and add final details like knuckles and nail shapes." :
                "Refine the hand outline, connect the fingers smoothly, and add thumb placement.",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    /// Generate advanced nature steps with organic forms
    private func generateAdvancedNatureSteps(from analysis: VisionAnalysisResult, complexity: LessonComplexity, variations: [LessonVariation]) -> [LessonStep] {
        var steps: [LessonStep] = []
        
        // Step 1: Central structure
        steps.append(LessonStep(
            stepNumber: 1,
            instruction: complexity == .complex ?
                "Establish the central structure using a circle. Consider the natural growth patterns and the golden ratio in nature." :
                "Establish the central structure using a circle. This anchors your natural form.",
            guidancePoints: [],
            shapeType: .circle
        ))
        
        // Step 2: Golden ratio proportions
        steps.append(LessonStep(
            stepNumber: 2,
            instruction: complexity == .complex ?
                "Apply golden ratio proportions to create natural, pleasing divisions in your composition. Nature follows these mathematical principles." :
                "Apply golden ratio proportions to create natural, pleasing divisions in your composition.",
            guidancePoints: [],
            shapeType: .line
        ))
        
        // Step 3: Organic shapes
        steps.append(LessonStep(
            stepNumber: 3,
            instruction: complexity == .complex ?
                "Build organic shapes using curved lines and natural forms. Avoid rigid geometric shapes and embrace the irregular beauty of nature." :
                "Build organic shapes using curved lines and natural forms. Avoid rigid geometric shapes.",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        // Step 4: Natural details
        steps.append(LessonStep(
            stepNumber: 4,
            instruction: complexity == .complex ?
                "Add natural details like texture, patterns, and surface variations found in nature. Consider the unique characteristics of your subject." :
                "Add natural details like texture, patterns, and surface variations found in nature.",
            guidancePoints: [],
            shapeType: .curve
        ))
        
        return steps
    }
    
    private func createSinglePortraitSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Start with the basic head structure - draw a circle for the skull", guidancePoints: [], shapeType: .circle),
            LessonStep(stepNumber: 2, instruction: "Add the jawline and chin - create the face outline", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 3, instruction: "Draw the eye line - horizontal guideline across the middle", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 4, instruction: "Place the eyes - almond shapes on the eye line", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 5, instruction: "Add the nose - triangular shape below the eyes", guidancePoints: [], shapeType: .polygon),
            LessonStep(stepNumber: 6, instruction: "Draw the mouth - curved line below the nose", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 7, instruction: "Add eyebrows and refine facial features", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 8, instruction: "Final details - hair, ears, and shading", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createGroupPortraitSteps(faceCount: Int) -> [LessonStep] {
        var steps: [LessonStep] = [
            LessonStep(stepNumber: 1, instruction: "Plan the composition - sketch rough positions for \(faceCount) faces", guidancePoints: [], shapeType: .oval),
            LessonStep(stepNumber: 2, instruction: "Start with the largest/most prominent face first", guidancePoints: [], shapeType: .circle),
            LessonStep(stepNumber: 3, instruction: "Add the second face, maintaining proper proportions and spacing", guidancePoints: [], shapeType: .oval)
        ]
        
        if faceCount > 2 {
            steps.append(LessonStep(stepNumber: 4, instruction: "Continue with remaining faces, ensuring good composition", guidancePoints: [], shapeType: .oval))
        }
        
        steps.append(contentsOf: [
            LessonStep(stepNumber: steps.count + 1, instruction: "Refine all facial features and expressions", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: steps.count + 2, instruction: "Add hair and clothing details", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: steps.count + 3, instruction: "Final shading and depth to bring the group to life", guidancePoints: [], shapeType: .curve)
        ])
        
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
            LessonStep(stepNumber: 1, instruction: "Analyze the composition - identify the main objects and their relationships", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 2, instruction: "Start with basic geometric shapes - circles, rectangles, and ovals", guidancePoints: [], shapeType: .circle),
            LessonStep(stepNumber: 3, instruction: "Establish accurate proportions using sighting techniques", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 4, instruction: "Add the three-dimensional form to each object", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 5, instruction: "Identify and draw the light source and shadows", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 6, instruction: "Add surface textures and material properties", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 7, instruction: "Refine details and create depth through value changes", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 8, instruction: "Final touches - highlights, reflections, and atmospheric perspective", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createPerspectiveSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Identify the horizon line and your eye level", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 2, instruction: "Locate the vanishing point(s) on the horizon", guidancePoints: [], shapeType: .circle),
            LessonStep(stepNumber: 3, instruction: "Draw the ground plane and establish depth", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 4, instruction: "Create the basic rectangular forms using perspective guidelines", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 5, instruction: "Add vertical lines to create height and structure", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 6, instruction: "Refine the perspective with accurate proportions", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 7, instruction: "Add details and architectural elements", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 8, instruction: "Final shading and atmospheric perspective for depth", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createLetteringSteps(text: String) -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Analyze the text style and establish guidelines - baseline, x-height, and cap height", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 2, instruction: "Sketch the overall letter shapes for: '\(text)' - focus on proportions", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 3, instruction: "Refine individual letterforms and their relationships", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 4, instruction: "Adjust letter spacing and kerning for visual balance", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 5, instruction: "Add weight and contrast to create visual hierarchy", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 6, instruction: "Refine curves and serifs for character and style", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 7, instruction: "Add final details and flourishes if appropriate", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 8, instruction: "Clean up guidelines and add final polish", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    private func createGeneralDrawingSteps() -> [LessonStep] {
        return [
            LessonStep(stepNumber: 1, instruction: "Study the composition and identify the focal point", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 2, instruction: "Block in the major shapes and proportions using light guidelines", guidancePoints: [], shapeType: .rectangle),
            LessonStep(stepNumber: 3, instruction: "Establish the basic structure and relationships between elements", guidancePoints: [], shapeType: .line),
            LessonStep(stepNumber: 4, instruction: "Add the three-dimensional form and volume to objects", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 5, instruction: "Identify and draw the light source and shadow patterns", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 6, instruction: "Refine details and add texture variations", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 7, instruction: "Create depth through value changes and atmospheric perspective", guidancePoints: [], shapeType: .curve),
            LessonStep(stepNumber: 8, instruction: "Final touches - highlights, contrast, and overall polish", guidancePoints: [], shapeType: .curve)
        ]
    }
    
    // MARK: - Enhanced AI-Powered Analysis Methods
    
    /// Analyze image complexity and generate adaptive difficulty
    private func analyzeImageComplexity(_ analysis: VisionAnalysisResult) -> LessonComplexity {
        var complexityScore: Double = 0.0
        
        // Face complexity analysis
        if !analysis.faces.isEmpty {
            complexityScore += Double(analysis.faces.count) * 0.3
            // Add complexity for multiple faces
            if analysis.faces.count > 1 {
                complexityScore += 0.2
            }
        }
        
        // Object complexity analysis
        if !analysis.objects.isEmpty {
            complexityScore += Double(analysis.objects.count) * 0.2
        }
        
        // Text complexity analysis
        if !analysis.text.isEmpty {
            let totalTextLength = analysis.text.map { $0.text.count }.reduce(0, +)
            complexityScore += min(Double(totalTextLength) * 0.01, 0.3)
        }
        
        // Rectangle/perspective complexity
        if !analysis.rectangles.isEmpty {
            complexityScore += Double(analysis.rectangles.count) * 0.25
        }
        
        // Determine complexity level
        if complexityScore < 0.5 {
            return .simple
        } else if complexityScore < 1.0 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    /// Generate content-specific lesson variations
    private func generateContentSpecificVariations(from analysis: VisionAnalysisResult) -> [LessonVariation] {
        var variations: [LessonVariation] = []
        
        // Face-specific variations
        if !analysis.faces.isEmpty {
            variations.append(LessonVariation(
                type: .facialFeatures,
                title: "Facial Features Focus",
                description: "Concentrate on individual facial features and their relationships",
                difficulty: .intermediate,
                estimatedTime: 25
            ))
            
            if analysis.faces.count > 1 {
                variations.append(LessonVariation(
                    type: .groupPortrait,
                    title: "Group Portrait Dynamics",
                    description: "Learn to draw multiple faces with proper composition and relationships",
                    difficulty: .advanced,
                    estimatedTime: 45
                ))
            }
        }
        
        // Object-specific variations
        if !analysis.objects.isEmpty {
            variations.append(LessonVariation(
                type: .stillLife,
                title: "Still Life Study",
                description: "Focus on form, light, and composition in object drawing",
                difficulty: .intermediate,
                estimatedTime: 30
            ))
        }
        
        // Perspective-specific variations
        if !analysis.rectangles.isEmpty {
            variations.append(LessonVariation(
                type: .perspective,
                title: "Perspective Mastery",
                description: "Learn advanced perspective techniques with architectural elements",
                difficulty: .advanced,
                estimatedTime: 40
            ))
        }
        
        return variations
    }
    
    /// Generate adaptive step complexity based on user level
    private func generateAdaptiveSteps(baseSteps: [LessonStep], userLevel: UserLevel, complexity: LessonComplexity) -> [LessonStep] {
        var adaptiveSteps = baseSteps
        
        switch (userLevel, complexity) {
        case (.beginner, .simple):
            // Simplify steps for beginners
            adaptiveSteps = adaptiveSteps.map { step in
                LessonStep(
                    stepNumber: step.stepNumber,
                    instruction: "\(step.instruction) (Take your time with this step)",
                    guidancePoints: step.guidancePoints,
                    shapeType: step.shapeType
                )
            }
            
        case (.advanced, .complex):
            // Add advanced techniques
            adaptiveSteps.append(contentsOf: [
                LessonStep(stepNumber: adaptiveSteps.count + 1, instruction: "Apply advanced shading techniques", guidancePoints: [], shapeType: .curve),
                LessonStep(stepNumber: adaptiveSteps.count + 2, instruction: "Add artistic interpretation and style", guidancePoints: [], shapeType: .curve)
            ])
            
        default:
            // Standard steps
            break
        }
        
        return adaptiveSteps
    }
    
    // MARK: - Enhanced Adaptive Generation Helpers
    
    private func generateAdaptiveTitle(for category: LessonCategory, faceCount: Int? = nil, rectangleCount: Int? = nil, objectCount: Int? = nil, textLength: Int? = nil, complexity: LessonComplexity) -> String {
        switch category {
        case .faces:
            if let faceCount = faceCount {
                if faceCount == 1 {
                    return complexity == .complex ? "Master Portrait Drawing" : "Portrait Drawing from Photo"
                } else {
                    return complexity == .complex ? "Advanced Group Portrait" : "Group Portrait from Photo"
                }
            }
            return "Portrait Drawing"
            
        case .perspective:
            if let rectangleCount = rectangleCount {
                return complexity == .complex ? "Advanced Perspective Mastery" : "Perspective Drawing from Photo"
            }
            return "Perspective Drawing"
            
        case .objects:
            if let objectCount = objectCount {
                return complexity == .complex ? "Complex Still Life Study" : "Still Life from Photo"
            }
            if let textLength = textLength {
                return complexity == .complex ? "Advanced Lettering & Typography" : "Lettering Practice"
            }
            return "Object Drawing"
            
        default:
            return "Drawing from Photo"
        }
    }
    
    private func generateAdaptiveDescription(for category: LessonCategory, faceCount: Int? = nil, rectangleCount: Int? = nil, objectCount: Int? = nil, textLength: Int? = nil, complexity: LessonComplexity, variations: [LessonVariation]) -> String {
        var baseDescription = ""
        
        switch category {
        case .faces:
            if let faceCount = faceCount {
                if faceCount == 1 {
                    baseDescription = complexity == .complex ? 
                        "Master the art of portrait drawing with advanced techniques, anatomical accuracy, and artistic interpretation." :
                        "Learn to draw a portrait by analyzing facial proportions and features from this photo."
                } else {
                    baseDescription = complexity == .complex ?
                        "Advanced group portrait techniques focusing on composition, relationships, and individual character." :
                        "Practice drawing multiple faces and their relationships in this group portrait."
                }
            }
            
        case .perspective:
            baseDescription = complexity == .complex ?
                "Master advanced perspective techniques with architectural elements, vanishing points, and depth perception." :
                "Learn perspective drawing using the geometric shapes and lines detected in this photo."
                
        case .objects:
            if let objectCount = objectCount {
                baseDescription = complexity == .complex ?
                    "Advanced still life study focusing on form, light, composition, and material properties." :
                    "Draw the objects in this photo, focusing on form, light, and composition."
            }
            if let textLength = textLength {
                baseDescription = complexity == .complex ?
                    "Advanced lettering and typography techniques with focus on style, spacing, and artistic expression." :
                    "Practice lettering and typography based on the text found in this image."
            }
            
        default:
            baseDescription = "Practice general drawing skills using this photo as reference."
        }
        
        // Add variation information if available
        if !variations.isEmpty {
            let variationNames = variations.map { $0.title }.joined(separator: ", ")
            baseDescription += " This lesson includes variations: \(variationNames)."
        }
        
        return baseDescription
    }
    
    private func determineAdaptiveDifficulty(from complexity: LessonComplexity, faceCount: Int? = nil, rectangleCount: Int? = nil, objectCount: Int? = nil, textLength: Int? = nil) -> DifficultyLevel {
        switch complexity {
        case .simple:
            return .beginner
        case .moderate:
            return .intermediate
        case .complex:
            return .advanced
        }
    }
    
    private func calculateAdaptiveTime(complexity: LessonComplexity, faceCount: Int? = nil, rectangleCount: Int? = nil, objectCount: Int? = nil, textLength: Int? = nil) -> Int {
        var baseTime: Int
        
        switch complexity {
        case .simple:
            baseTime = 15
        case .moderate:
            baseTime = 25
        case .complex:
            baseTime = 40
        }
        
        // Add time based on content complexity
        if let faceCount = faceCount {
            baseTime += faceCount * 5
        }
        if let rectangleCount = rectangleCount {
            baseTime += rectangleCount * 3
        }
        if let objectCount = objectCount {
            baseTime += objectCount * 2
        }
        if let textLength = textLength {
            baseTime += min(textLength / 10, 10) // Cap at 10 minutes for text
        }
        
        return min(baseTime, 60) // Cap at 60 minutes
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

// MARK: - Enhanced Analysis Data Structures

enum LessonComplexity {
    case simple
    case moderate
    case complex
}

enum LessonVariationType {
    case facialFeatures
    case groupPortrait
    case stillLife
    case perspective
    case lettering
    case general
}

struct LessonVariation {
    let type: LessonVariationType
    let title: String
    let description: String
    let difficulty: DifficultyLevel
    let estimatedTime: Int
}

enum UserLevel {
    case beginner
    case intermediate
    case advanced
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
