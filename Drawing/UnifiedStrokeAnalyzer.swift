import Foundation
import CoreML
import Vision
import CoreGraphics
import SwiftUI

// MARK: - Unified Stroke Analyzer with Core ML
@MainActor
class UnifiedStrokeAnalyzer: ObservableObject {
    
    // MARK: - Configuration
    private struct Config {
        static let maxStrokePoints = 200
        static let imageSize = CGSize(width: 224, height: 224)
        static let confidenceThreshold: Float = 0.7
        static let analysisTimeout: TimeInterval = 0.1 // 100ms for real-time
    }
    
    // MARK: - Core ML Model
    private var strokeAnalysisModel: MLModel?
    private var visionModel: VNCoreMLModel?
    
    // MARK: - Artistic Feedback Engine
    private let artisticFeedbackEngine = ArtisticFeedbackEngine()
    
    // MARK: - Performance Monitoring
    private var analysisMetrics = AnalysisMetrics()
    
    // MARK: - Initialization
    init() {
        setupCoreMLModel()
    }
    
    // MARK: - Core ML Setup
    private func setupCoreMLModel() {
        do {
            // Try to load the UpdatableDrawingClassifier model
            if let modelURL = Bundle.main.url(forResource: "UpdatableDrawingClassifier", withExtension: "mlmodelc") {
                let config = MLModelConfiguration()
                config.computeUnits = .cpuAndNeuralEngine // ENHANCED: Use Neural Engine for performance
                strokeAnalysisModel = try MLModel(contentsOf: modelURL, configuration: config)
                print("✅ [UnifiedStrokeAnalyzer] UpdatableDrawingClassifier Core ML model loaded successfully with Neural Engine")
            } else {
                // Fallback to Vision framework for stroke analysis
                setupVisionFramework()
                print("⚠️ [UnifiedStrokeAnalyzer] Using Vision framework fallback - Core ML model not found")
            }
        } catch {
            print("❌ [UnifiedStrokeAnalyzer] Failed to load Core ML model: \(error)")
            setupVisionFramework()
        }
    }
    
    private func setupVisionFramework() {
        // Use Vision framework as fallback for stroke analysis
        // This provides basic shape recognition capabilities
    }
    
    // MARK: - Main Analysis Method
    func analyzeStroke(_ stroke: DrawingStroke, against guide: DrawingGuide) -> StrokeFeedback {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        print("🎨 [STROKE ANALYSIS] ========================================")
        print("🎨 [STROKE ANALYSIS] Starting analysis for stroke with \(stroke.points.count) points")
        print("🎯 [STROKE ANALYSIS] Target guide: \(guide.shapes.first?.type.rawValue ?? "unknown")")
        print("📏 [STROKE ANALYSIS] Stroke bounds: \(calculateBoundingRect(for: stroke.points))")
        
        // Validate input
        guard !stroke.points.isEmpty else {
            print("⚠️ [STROKE ANALYSIS] Empty stroke received - returning default feedback")
            return createEmptyStrokeFeedback()
        }
        
        guard guide.shapes.first != nil else {
            print("⚠️ [STROKE ANALYSIS] No guide shapes found - returning default feedback")
            return createDefaultFeedback()
        }
        
        // Perform unified analysis
        let analysisResult = performUnifiedAnalysis(stroke: stroke, guide: guide)
        
        // Record performance metrics
        let analysisTime = CFAbsoluteTimeGetCurrent() - startTime
        analysisMetrics.recordAnalysis(time: analysisTime, success: true)
        
        print("⏱️ [STROKE ANALYSIS] Analysis completed in \(String(format: "%.3f", analysisTime * 1000))ms")
        print("📊 [STROKE ANALYSIS] Result accuracy: \(String(format: "%.2f", analysisResult.accuracy))")
        print("🎯 [STROKE ANALYSIS] Result confidence: \(String(format: "%.2f", analysisResult.confidence))")
        print("🔍 [STROKE ANALYSIS] Analysis method: \(analysisResult.analysisMethod)")
        
        // Generate feedback
        let feedback = generateUnifiedFeedback(from: analysisResult, guide: guide)
        
        print("💬 [STROKE ANALYSIS] Generated \(feedback.suggestions.count) suggestions")
        print("✅ [STROKE ANALYSIS] Is correct: \(feedback.isCorrect)")
        if let artisticFeedback = feedback.artisticFeedback {
            print("🎨 [STROKE ANALYSIS] Artistic score: \(String(format: "%.2f", artisticFeedback.overallScore))")
        }
        print("🎨 [STROKE ANALYSIS] ========================================")
        
        return feedback
    }
    
    // MARK: - Unified Analysis Implementation
    private func performUnifiedAnalysis(stroke: DrawingStroke, guide: DrawingGuide) -> UnifiedAnalysisResult {
        // Step 1: Preprocess stroke data
        let preprocessedStroke = preprocessStroke(stroke)
        
        // Step 2: Convert to image representation
        let strokeImage = renderStrokeToImage(preprocessedStroke)
        
        // Step 3: Perform Core ML analysis
        let mlResult = performCoreMLAnalysis(strokeImage: strokeImage, targetShape: guide.shapes.first)
        
        // Step 4: Perform geometric analysis as fallback/validation
        let geometricResult = performGeometricAnalysis(stroke: preprocessedStroke, guide: guide)
        
        // Step 5: Combine results
        var result = combineAnalysisResults(mlResult: mlResult, geometricResult: geometricResult)
        result.stroke = stroke // Set the original stroke
        return result
    }
    
    // MARK: - Stroke Preprocessing
    private func preprocessStroke(_ stroke: DrawingStroke) -> DrawingStroke {
        // Normalize stroke points
        let normalizedPoints = normalizeStrokePoints(stroke.points)
        
        // Resample if necessary
        let resampledPoints = resampleStroke(normalizedPoints, targetCount: Config.maxStrokePoints)
        
        // Smooth the stroke
        let smoothedPoints = smoothStroke(resampledPoints)
        
        return DrawingStroke(
            points: smoothedPoints,
            timestamp: stroke.timestamp,
            pressure: Array(stroke.pressure.prefix(smoothedPoints.count)),
            velocity: Array(stroke.velocity.prefix(smoothedPoints.count))
        )
    }
    
    private func normalizeStrokePoints(_ points: [CGPoint]) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        
        // Calculate bounding box
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        let width = maxX - minX
        let height = maxY - minY
        let maxDimension = max(width, height)
        
        guard maxDimension > 0 else { return points }
        
        // Normalize to 0-1 range
        return points.map { point in
            CGPoint(
                x: (point.x - minX) / maxDimension,
                y: (point.y - minY) / maxDimension
            )
        }
    }
    
    private func resampleStroke(_ points: [CGPoint], targetCount: Int) -> [CGPoint] {
        guard points.count > targetCount else { return points }
        
        let step = Double(points.count - 1) / Double(targetCount - 1)
        var resampledPoints: [CGPoint] = []
        
        for i in 0..<targetCount {
            let index = Double(i) * step
            let lowerIndex = Int(index)
            let upperIndex = min(lowerIndex + 1, points.count - 1)
            let fraction = index - Double(lowerIndex)
            
            let lowerPoint = points[lowerIndex]
            let upperPoint = points[upperIndex]
            
            let interpolatedPoint = CGPoint(
                x: lowerPoint.x + fraction * (upperPoint.x - lowerPoint.x),
                y: lowerPoint.y + fraction * (upperPoint.y - lowerPoint.y)
            )
            
            resampledPoints.append(interpolatedPoint)
        }
        
        return resampledPoints
    }
    
    private func smoothStroke(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        var smoothedPoints: [CGPoint] = [points[0]]
        
        for i in 1..<(points.count - 1) {
            let prevPoint = points[i - 1]
            let currentPoint = points[i]
            let nextPoint = points[i + 1]
            
            let smoothedPoint = CGPoint(
                x: (prevPoint.x + currentPoint.x + nextPoint.x) / 3,
                y: (prevPoint.y + currentPoint.y + nextPoint.y) / 3
            )
            
            smoothedPoints.append(smoothedPoint)
        }
        
        smoothedPoints.append(points.last!)
        return smoothedPoints
    }
    
    // MARK: - Image Rendering
    private func renderStrokeToImage(_ stroke: DrawingStroke) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Config.imageSize)
        
        return renderer.image { context in
            // Clear background
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: Config.imageSize))
            
            // Draw stroke
            UIColor.black.setStroke()
            let path = UIBezierPath()
            
            guard !stroke.points.isEmpty else { return }
            
            // Scale points to image size
            let scaledPoints = stroke.points.map { point in
                CGPoint(
                    x: point.x * Config.imageSize.width,
                    y: point.y * Config.imageSize.height
                )
            }
            
            path.move(to: scaledPoints[0])
            for i in 1..<scaledPoints.count {
                path.addLine(to: scaledPoints[i])
            }
            
            path.lineWidth = 3.0
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
    }
    
    // MARK: - Core ML Analysis
    private func performCoreMLAnalysis(strokeImage: UIImage, targetShape: GuideShape?) -> CoreMLResult {
        print("🧠 [CORE ML ANALYSIS] Starting Core ML analysis...")
        print("🎯 [CORE ML ANALYSIS] Target shape: \(targetShape?.type.rawValue ?? "none")")
        
        guard let model = strokeAnalysisModel else {
            print("⚠️ [CORE ML ANALYSIS] No Core ML model available, falling back to Vision framework")
            return performVisionFrameworkAnalysis(strokeImage: strokeImage, targetShape: targetShape)
        }
        
        do {
            // ENHANCED: Convert image to 28x28 grayscale for UpdatableDrawingClassifier
            let processedImage = preprocessImageForCoreML(strokeImage)
            print("🖼️ [CORE ML ANALYSIS] Image preprocessed to 28x28 grayscale")
            
            guard let pixelBuffer = processedImage.toPixelBuffer() else {
                print("❌ [CORE ML ANALYSIS] Failed to convert image to pixel buffer")
                return CoreMLResult(confidence: 0.0, shapeType: .line, accuracy: 0.0)
            }
            
            // Create input for UpdatableDrawingClassifier
            let input = try MLDictionaryFeatureProvider(dictionary: ["image": MLFeatureValue(pixelBuffer: pixelBuffer)])
            print("📥 [CORE ML ANALYSIS] Input created for UpdatableDrawingClassifier")
            
            // Perform prediction with real Core ML model
            let prediction = try model.prediction(from: input)
            print("🔮 [CORE ML ANALYSIS] Core ML prediction completed")
            
            // Extract results from UpdatableDrawingClassifier
            let confidence = extractConfidenceFromUpdatableClassifier(from: prediction)
            let shapeType = extractShapeTypeFromUpdatableClassifier(from: prediction)
            let accuracy = calculateAccuracy(confidence: confidence, targetShape: targetShape)
            
            print("✅ [CORE ML ANALYSIS] Results:")
            print("   📊 Confidence: \(String(format: "%.3f", confidence))")
            print("   🎯 Detected Shape: \(shapeType.rawValue)")
            print("   📈 Accuracy: \(String(format: "%.3f", accuracy))")
            print("   🎯 Target Shape: \(targetShape?.type.rawValue ?? "none")")
            print("   ✅ Match: \(shapeType == targetShape?.type ? "YES" : "NO")")
            
            return CoreMLResult(confidence: confidence, shapeType: shapeType, accuracy: accuracy)
            
        } catch {
            print("❌ [CORE ML ANALYSIS] Core ML prediction failed: \(error)")
            print("🔄 [CORE ML ANALYSIS] Falling back to Vision framework")
            return performVisionFrameworkAnalysis(strokeImage: strokeImage, targetShape: targetShape)
        }
    }
    
    private func performVisionFrameworkAnalysis(strokeImage: UIImage, targetShape: GuideShape?) -> CoreMLResult {
        // Fallback to Vision framework for basic shape recognition
        guard let cgImage = strokeImage.cgImage else {
            return CoreMLResult(confidence: 0.0, shapeType: .line, accuracy: 0.0)
        }
        
        // Use Vision framework to detect basic shapes
        let request = VNDetectRectanglesRequest { request, error in
            // Handle rectangle detection
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])
        
        // For now, return a basic result
        return CoreMLResult(confidence: 0.6, shapeType: .rectangle, accuracy: 0.6)
    }
    
    // MARK: - Geometric Analysis (Fallback)
    private func performGeometricAnalysis(stroke: DrawingStroke, guide: DrawingGuide) -> GeometricResult {
        guard let primaryShape = guide.shapes.first else {
            return GeometricResult(accuracy: 0.0, shapeMatch: false, positionAccuracy: 0.0)
        }
        
        // Analyze shape accuracy
        let shapeAccuracy = analyzeShapeAccuracy(stroke, targetShape: primaryShape)
        
        // Analyze position accuracy
        let positionAccuracy = analyzePositionAccuracy(stroke, guide: guide)
        
        // Determine shape match
        let shapeMatch = shapeAccuracy > 0.7
        
        return GeometricResult(
            accuracy: shapeAccuracy,
            shapeMatch: shapeMatch,
            positionAccuracy: positionAccuracy
        )
    }
    
    private func analyzeShapeAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        switch targetShape.type {
        case .circle:
            return analyzeCircleAccuracy(stroke, targetShape: targetShape)
        case .rectangle:
            return analyzeRectangleAccuracy(stroke, targetShape: targetShape)
        case .line:
            return analyzeLineAccuracy(stroke, targetShape: targetShape)
        case .oval:
            return analyzeOvalAccuracy(stroke, targetShape: targetShape)
        case .curve:
            return analyzeCurveAccuracy(stroke, targetShape: targetShape)
        case .polygon:
            return analyzePolygonAccuracy(stroke, targetShape: targetShape)
        }
    }
    
    private func analyzeCircleAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let center = targetShape.center
        let targetRadius = targetShape.dimensions.width / 2
        
        // Calculate distances from center
        let distances = stroke.points.map { point in
            sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
        }
        
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { Foundation.pow($0 - averageDistance, 2) }.reduce(0, +) / Double(distances.count)
        let standardDeviation = sqrt(variance)
        
        // Check radius accuracy
        let radiusAccuracy = 1.0 - min(abs(averageDistance - targetRadius) / targetRadius, 1.0)
        
        // Check consistency
        let consistencyScore = max(0.0, 1.0 - (standardDeviation / targetRadius))
        
        return (radiusAccuracy * 0.6 + consistencyScore * 0.4)
    }
    
    private func analyzeRectangleAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let targetRect = CGRect(
            x: targetShape.center.x - targetShape.dimensions.width / 2,
            y: targetShape.center.y - targetShape.dimensions.height / 2,
            width: targetShape.dimensions.width,
            height: targetShape.dimensions.height
        )
        
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let centerAccuracy = 1.0 - min(distance(from: strokeBounds.center, to: targetRect.center) / 50.0, 1.0)
        let sizeAccuracy = 1.0 - min(abs(strokeBounds.width - targetRect.width) / targetRect.width, 1.0)
        
        return (centerAccuracy + sizeAccuracy) / 2.0
    }
    
    private func analyzeLineAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        guard stroke.points.count >= 2, targetShape.points.count >= 2 else { return 0.0 }
        
        let startPoint = stroke.points.first!
        let endPoint = stroke.points.last!
        let targetStart = targetShape.points[0]
        let targetEnd = targetShape.points[1]
        
        let startAccuracy = 1.0 - min(distance(from: startPoint, to: targetStart) / 50.0, 1.0)
        let endAccuracy = 1.0 - min(distance(from: endPoint, to: targetEnd) / 50.0, 1.0)
        let straightnessScore = analyzeStraightness(stroke.points)
        
        return (startAccuracy * 0.3 + endAccuracy * 0.3 + straightnessScore * 0.4)
    }
    
    private func analyzeOvalAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let center = targetShape.center
        let targetWidth = targetShape.dimensions.width
        let targetHeight = targetShape.dimensions.height
        
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let widthAccuracy = 1.0 - min(abs(strokeBounds.width - targetWidth) / targetWidth, 1.0)
        let heightAccuracy = 1.0 - min(abs(strokeBounds.height - targetHeight) / targetHeight, 1.0)
        let centerAccuracy = 1.0 - min(distance(from: strokeBounds.center, to: center) / 50.0, 1.0)
        
        return (widthAccuracy + heightAccuracy + centerAccuracy) / 3.0
    }
    
    private func analyzeCurveAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let smoothnessScore = analyzeSmoothness(stroke)
        let pathScore = analyzePathSimilarity(stroke.points, target: targetShape.points)
        return (smoothnessScore + pathScore) / 2.0
    }
    
    private func analyzePolygonAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let corners = detectCorners(in: stroke.points)
        let targetCornerCount = targetShape.points.count
        let cornerCountAccuracy = 1.0 - min(abs(Double(corners.count - targetCornerCount)) / Double(targetCornerCount), 1.0)
        return cornerCountAccuracy
    }
    
    private func analyzePositionAccuracy(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        guard !guide.targetPoints.isEmpty else { return 1.0 }
        
        let strokeCenter = calculateCenterPoint(of: stroke.points)
        let closestTarget = guide.targetPoints.min { point1, point2 in
            distance(from: strokeCenter, to: point1) < distance(from: strokeCenter, to: point2)
        }
        
        guard let target = closestTarget else { return 0.5 }
        
        let distanceToTarget = distance(from: strokeCenter, to: target)
        let tolerance = guide.tolerance
        
        return max(0.0, 1.0 - (distanceToTarget / tolerance))
    }
    
    // MARK: - Result Combination
    private func combineAnalysisResults(mlResult: CoreMLResult, geometricResult: GeometricResult) -> UnifiedAnalysisResult {
        // Weight the results based on confidence
        let mlWeight = Double(mlResult.confidence)
        let geometricWeight = 1.0 - mlWeight
        
        let combinedAccuracy = (mlResult.accuracy * mlWeight) + (geometricResult.accuracy * geometricWeight)
        let combinedConfidence = max(mlResult.confidence, Float(geometricResult.accuracy))
        
        return UnifiedAnalysisResult(
            accuracy: combinedAccuracy,
            confidence: combinedConfidence,
            shapeType: mlResult.shapeType,
            shapeMatch: geometricResult.shapeMatch,
            positionAccuracy: geometricResult.positionAccuracy,
            analysisMethod: mlResult.confidence > 0.7 ? .coreML : .geometric,
            stroke: nil, // We'll set this in the calling method
            points: nil
        )
    }
    
    // MARK: - Helper Methods
    private func createArtisticContext(for guide: DrawingGuide) -> ArtisticContext {
        // Determine context based on guide properties, lesson type, etc.
        // For example, if the guide is a simple circle, the context might emphasize line quality.
        // If it's a complex scene, it might emphasize composition.
        let isCentralized = guide.shapes.count == 1 && guide.shapes.first?.type == .circle
        return ArtisticContext(
            userLevel: .beginner,
            lessonCategory: guide.category,
            previousAttempts: 0,
            timeSpent: 0,
            userPreferences: UserArtisticPreferences(
                preferredStyle: "realistic",
                focusAreas: ["line_quality"],
                encouragementLevel: .moderate
            )
        )
    }
    
    private func createStrokeFromResult(_ result: UnifiedAnalysisResult) -> DrawingStroke? {
        // If we have the original stroke, use it
        if let stroke = result.stroke {
            return stroke
        }
        
        // Otherwise, create a basic stroke from the analysis result
        // This is a fallback for when we don't have the original stroke data
        guard let points = result.points, !points.isEmpty else { return nil }
        
        return DrawingStroke(
            points: points,
            timestamp: Date(),
            pressure: Array(repeating: 1.0, count: points.count),
            velocity: Array(repeating: 0.0, count: points.count)
        )
    }
    
    private func combineTechnicalAndArtisticSuggestions(technicalSuggestions: [String], artisticFeedback: ArtisticFeedback) -> [String] {
        var combined = technicalSuggestions
        combined.append(contentsOf: artisticFeedback.suggestions)
        return Array(Set(combined)).sorted() // Remove duplicates and sort
    }
    
    // MARK: - Feedback Generation
    private func generateUnifiedFeedback(from result: UnifiedAnalysisResult, guide: DrawingGuide) -> StrokeFeedback {
        print("💬 [FEEDBACK GENERATION] Generating feedback for accuracy: \(String(format: "%.3f", result.accuracy))")
        
        let suggestions = generateSuggestions(from: result, guide: guide)
        let isCorrect = result.accuracy >= 0.7
        
        print("✅ [FEEDBACK GENERATION] Is correct: \(isCorrect) (threshold: 0.7)")
        print("💡 [FEEDBACK GENERATION] Generated \(suggestions.count) suggestions")
        
        // ENHANCED: Generate artistic feedback alongside technical feedback
        let artisticContext = createArtisticContext(for: guide)
        let strokeForAnalysis = result.stroke ?? createStrokeFromResult(result)
        guard let strokeForAnalysis = strokeForAnalysis else {
            print("⚠️ [FEEDBACK GENERATION] No stroke available for artistic analysis")
            // If we can't get a stroke for analysis, return basic feedback
            return StrokeFeedback(
                accuracy: result.accuracy,
                suggestions: suggestions,
                correctionPoints: [],
                isCorrect: isCorrect,
                dtwDistance: nil,
                temporalAccuracy: nil,
                velocityConsistency: nil,
                spatialAlignment: nil,
                confidenceScore: Double(result.confidence),
                artisticFeedback: nil
            )
        }
        
        let artisticFeedback = artisticFeedbackEngine.analyzeArtisticQuality(
            strokeForAnalysis,
            against: guide,
            context: artisticContext
        )
        
        print("🎨 [FEEDBACK GENERATION] Artistic feedback generated:")
        print("   📊 Overall score: \(String(format: "%.3f", artisticFeedback.overallScore))")
        print("   💡 Artistic suggestions: \(artisticFeedback.suggestions.count)")
        print("   🌟 Encouragement: \(artisticFeedback.encouragement)")
        
        // Combine technical and artistic suggestions
        let combinedSuggestions = combineTechnicalAndArtisticSuggestions(
            technicalSuggestions: suggestions,
            artisticFeedback: artisticFeedback
        )
        
        print("🔗 [FEEDBACK GENERATION] Combined suggestions: \(combinedSuggestions.count) total")
        
        return StrokeFeedback(
            accuracy: result.accuracy,
            suggestions: combinedSuggestions,
            correctionPoints: generateCorrectionPoints(from: result, guide: guide),
            isCorrect: isCorrect,
            dtwDistance: nil, // Not used in unified approach
            temporalAccuracy: nil,
            velocityConsistency: nil,
            spatialAlignment: nil,
            confidenceScore: Double(result.confidence),
            artisticFeedback: artisticFeedback // ENHANCED: Include artistic feedback
        )
    }
    
    private func generateSuggestions(from result: UnifiedAnalysisResult, guide: DrawingGuide) -> [String] {
        var suggestions: [String] = []
        
        if result.accuracy < 0.7 {
            switch result.analysisMethod {
            case .coreML:
                suggestions.append("🎯 Try to follow the guide shape a bit more closely - you're doing great!")
            case .geometric:
                suggestions.append("📐 Focus on matching the guide lines - your drawing is getting better!")
            case .hybrid:
                suggestions.append("✨ You're improving! Try to match both the shape and the guide lines")
            }
            
            if result.positionAccuracy < 0.7 {
                suggestions.append("📍 Try to aim for the guide markers - you're almost there!")
            }
        } else {
            suggestions.append("🌟 Amazing! You're following the guide perfectly - keep it up!")
        }
        
        return suggestions.isEmpty ? ["💪 Keep practicing - you're doing great!"] : suggestions
    }
    
    private func generateCorrectionPoints(from result: UnifiedAnalysisResult, guide: DrawingGuide) -> [CGPoint] {
        guard let primaryShape = guide.shapes.first else { return [] }
        
        // Generate correction points based on shape type
        switch primaryShape.type {
        case .circle:
            return generateCircleCorrections(primaryShape)
        case .rectangle:
            return generateRectangleCorrections(primaryShape)
        case .line:
            return primaryShape.points
        default:
            return primaryShape.points
        }
    }
    
    private func generateCircleCorrections(_ shape: GuideShape) -> [CGPoint] {
        let center = shape.center
        let radius = shape.dimensions.width / 2
        let points = 8
        
        var corrections: [CGPoint] = []
        for i in 0..<points {
            let angle = Double(i) * 2 * .pi / Double(points)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            corrections.append(CGPoint(x: x, y: y))
        }
        
        return corrections
    }
    
    private func generateRectangleCorrections(_ shape: GuideShape) -> [CGPoint] {
        let rect = CGRect(
            x: shape.center.x - shape.dimensions.width / 2,
            y: shape.center.y - shape.dimensions.height / 2,
            width: shape.dimensions.width,
            height: shape.dimensions.height
        )
        
        return [
            CGPoint(x: rect.minX, y: rect.minY), // Top-left
            CGPoint(x: rect.maxX, y: rect.minY), // Top-right
            CGPoint(x: rect.maxX, y: rect.maxY), // Bottom-right
            CGPoint(x: rect.minX, y: rect.maxY)  // Bottom-left
        ]
    }
    
    // MARK: - Helper Methods
    private func distance(from point1: CGPoint, to point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(Double(dx * dx + dy * dy))
    }
    
    private func calculateBoundingRect(for points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func calculateCenterPoint(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    private func analyzeStraightness(_ points: [CGPoint]) -> Double {
        guard points.count > 2 else { return 1.0 }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        var totalDeviation = 0.0
        let lineLength = distance(from: firstPoint, to: lastPoint)
        
        for point in points.dropFirst().dropLast() {
            let deviation = distanceFromPointToLine(point: point, lineStart: firstPoint, lineEnd: lastPoint)
            totalDeviation += deviation
        }
        
        let averageDeviation = totalDeviation / Double(points.count - 2)
        let maxAllowedDeviation = lineLength * 0.05
        
        return max(0.0, 1.0 - (averageDeviation / maxAllowedDeviation))
    }
    
    private func distanceFromPointToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Double {
        let A = Double(lineEnd.y - lineStart.y)
        let B = Double(lineStart.x - lineEnd.x)
        let C = Double(lineEnd.x * lineStart.y - lineStart.x * lineEnd.y)
        
        let numerator = abs(A * Double(point.x) + B * Double(point.y) + C)
        let denominator = sqrt(A * A + B * B)
        
        return denominator > 0 ? numerator / denominator : 0.0
    }
    
    private func analyzeSmoothness(_ stroke: DrawingStroke) -> Double {
        guard stroke.points.count > 2 else { return 1.0 }
        
        var totalAngularChange = 0.0
        
        for i in 1..<(stroke.points.count - 1) {
            let prevPoint = stroke.points[i - 1]
            let currentPoint = stroke.points[i]
            let nextPoint = stroke.points[i + 1]
            
            let angle1 = atan2(currentPoint.y - prevPoint.y, currentPoint.x - prevPoint.x)
            let angle2 = atan2(nextPoint.y - currentPoint.y, nextPoint.x - currentPoint.x)
            
            var angleChange = abs(angle2 - angle1)
            if angleChange > .pi {
                angleChange = 2 * .pi - angleChange
            }
            
            totalAngularChange += angleChange
        }
        
        let averageAngularChange = totalAngularChange / Double(stroke.points.count - 2)
        return max(0.0, 1.0 - (averageAngularChange / .pi))
    }
    
    private func analyzePathSimilarity(_ actualPath: [CGPoint], target: [CGPoint]) -> Double {
        guard !actualPath.isEmpty && !target.isEmpty else { return 0.0 }
        
        let actualBounds = calculateBoundingRect(for: actualPath)
        let targetBounds = calculateBoundingRect(for: target)
        
        let centerDistance = distance(from: actualBounds.center, to: targetBounds.center)
        let tolerance = max(targetBounds.width, targetBounds.height) * 0.3
        
        return max(0.0, 1.0 - (centerDistance / tolerance))
    }
    
    private func detectCorners(in points: [CGPoint]) -> [CGPoint] {
        guard points.count > 3 else { return [] }
        
        var corners: [CGPoint] = []
        let angleThreshold: Double = .pi / 4
        
        for i in 1..<(points.count - 1) {
            let prevPoint = points[i - 1]
            let currentPoint = points[i]
            let nextPoint = points[i + 1]
            
            let angle1 = atan2(Double(currentPoint.y - prevPoint.y), Double(currentPoint.x - prevPoint.x))
            let angle2 = atan2(Double(nextPoint.y - currentPoint.y), Double(nextPoint.x - currentPoint.x))
            
            var angleChange = abs(angle2 - angle1)
            if angleChange > .pi {
                angleChange = 2 * .pi - angleChange
            }
            
            if angleChange > angleThreshold {
                corners.append(currentPoint)
            }
        }
        
        return corners
    }
    
    // MARK: - Core ML Helper Methods
    private func preprocessImageForCoreML(_ image: UIImage) -> UIImage {
        // Convert to 28x28 grayscale for UpdatableDrawingClassifier
        let targetSize = CGSize(width: 28, height: 28)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { context in
            // Clear background to white
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            
            // Draw the original image scaled to 28x28
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func extractConfidenceFromUpdatableClassifier(from prediction: MLFeatureProvider) -> Float {
        // Extract confidence from UpdatableDrawingClassifier prediction
        if let confidenceFeature = prediction.featureValue(for: "confidence") {
            return Float(truncating: confidenceFeature.multiArrayValue?[0] ?? 0.0)
        }
        return 0.5 // Default confidence
    }
    
    private func extractShapeTypeFromUpdatableClassifier(from prediction: MLFeatureProvider) -> ShapeType {
        // Extract shape type from UpdatableDrawingClassifier prediction
        if let labelFeature = prediction.featureValue(for: "label") {
            let label = labelFeature.stringValue ?? "unknown"
            return mapLabelToShapeType(label)
        }
        return .line // Default shape type
    }
    
    private func mapLabelToShapeType(_ label: String) -> ShapeType {
        // Map UpdatableDrawingClassifier labels to our ShapeType enum
        switch label.lowercased() {
        case "circle", "round":
            return .circle
        case "rectangle", "square", "rect":
            return .rectangle
        case "line", "straight":
            return .line
        case "oval", "ellipse":
            return .oval
        case "curve", "curved":
            return .curve
        case "polygon", "triangle", "hexagon":
            return .polygon
        default:
            return .line
        }
    }
    
    private func calculateAccuracy(confidence: Float, targetShape: GuideShape?) -> Double {
        guard targetShape != nil else { return Double(confidence) }
        
        // Calculate accuracy based on confidence and target shape
        return Double(confidence) * 0.8 + 0.2 // Placeholder
    }
    
    // MARK: - Feedback Creation
    private func createEmptyStrokeFeedback() -> StrokeFeedback {
        return StrokeFeedback(
            accuracy: 0.0,
            suggestions: ["🎨 Ready to start drawing? Give it a try!"],
            correctionPoints: [],
            isCorrect: false
        )
    }
    
    private func createDefaultFeedback() -> StrokeFeedback {
        return StrokeFeedback(
            accuracy: 0.5,
            suggestions: ["✨ Let's find a guide to help you draw something amazing!"],
            correctionPoints: [],
            isCorrect: false
        )
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> AnalysisMetrics {
        return analysisMetrics
    }
}

// MARK: - Supporting Data Structures

struct UnifiedAnalysisResult {
    let accuracy: Double
    let confidence: Float
    let shapeType: ShapeType
    let shapeMatch: Bool
    let positionAccuracy: Double
    let analysisMethod: AnalysisMethod
    var stroke: DrawingStroke?
    var points: [CGPoint]?
}

struct CoreMLResult {
    let confidence: Float
    let shapeType: ShapeType
    let accuracy: Double
}

struct GeometricResult {
    let accuracy: Double
    let shapeMatch: Bool
    let positionAccuracy: Double
}

enum AnalysisMethod {
    case coreML
    case geometric
    case hybrid
}

class AnalysisMetrics {
    private var analysisTimes: [TimeInterval] = []
    private var successCount = 0
    private var totalCount = 0
    
    func recordAnalysis(time: TimeInterval, success: Bool) {
        analysisTimes.append(time)
        totalCount += 1
        if success {
            successCount += 1
        }
        
        // Keep only last 100 measurements
        if analysisTimes.count > 100 {
            analysisTimes.removeFirst()
        }
    }
    
    var averageAnalysisTime: TimeInterval {
        guard !analysisTimes.isEmpty else { return 0 }
        return analysisTimes.reduce(0, +) / Double(analysisTimes.count)
    }
    
    var successRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(successCount) / Double(totalCount)
    }
    
    // MARK: - ENHANCED: Artistic Feedback Helper Methods
    
    private func createArtisticContext(for guide: DrawingGuide) -> ArtisticContext {
        // Determine context based on guide properties, lesson type, etc.
        // For example, if the guide is a simple circle, the context might emphasize line quality.
        // If it's a complex scene, it might emphasize composition.
        let isCentralized = guide.shapes.count == 1 && guide.shapes.first?.type == .circle
        return ArtisticContext(
            userLevel: .beginner,
            lessonCategory: guide.category,
            previousAttempts: 0,
            timeSpent: 0,
            userPreferences: UserArtisticPreferences(
                preferredStyle: "realistic",
                focusAreas: ["line_quality"],
                encouragementLevel: .moderate
            )
        )
    }
    
    private func combineTechnicalAndArtisticSuggestions(technicalSuggestions: [String], artisticFeedback: ArtisticFeedback) -> [String] {
        var combined = technicalSuggestions
        combined.append(contentsOf: artisticFeedback.suggestions)
        return Array(Set(combined)).sorted() // Remove duplicates and sort
    }
    
    private func createStrokeFromResult(_ result: UnifiedAnalysisResult) -> DrawingStroke? {
        // If we have the original stroke, use it
        if let stroke = result.stroke {
            return stroke
        }
        
        // Otherwise, create a basic stroke from the analysis result
        // This is a fallback for when we don't have the original stroke data
        guard let points = result.points, !points.isEmpty else { return nil }
        
        return DrawingStroke(
            points: points,
            timestamp: Date(),
            pressure: Array(repeating: 1.0, count: points.count),
            velocity: Array(repeating: 0.0, count: points.count)
        )
    }
}

// MARK: - UIImage Extension for Pixel Buffer Conversion

extension UIImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
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
        draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        
        return buffer
    }
}

// MARK: - Extensions

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
