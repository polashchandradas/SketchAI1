import Foundation
import CoreGraphics
import SwiftUI
import Darwin.Mach

/// Unified stroke analyzer that uses geometric analysis instead of ML models
/// Provides comprehensive stroke analysis using mathematical calculations
@MainActor
class UnifiedStrokeAnalyzer: ObservableObject {
    
    // MARK: - Configuration
    private struct Config {
        static let maxStrokePoints = 200
        static let confidenceThreshold: Double = 0.7
        static let analysisTimeout: TimeInterval = 0.1 // 100ms for real-time
    }
    
    // MARK: - Geometric Analysis
    
    /// Geometric stroke analyzer for real-time feedback
    private var geometricAnalyzer: GeometricStrokeAnalyzer
    
    /// Analysis results cache for performance optimization
    private var analysisCache: [String: GeometricStrokeAnalyzer.GeometricAnalysisResult] = [:]
    
    /// Artistic Feedback Engine
    private let artisticFeedbackEngine = ArtisticFeedbackEngine()
    
    // MARK: - Performance Monitoring
    private var analysisMetrics = AnalysisMetrics()
    
    // MARK: - Initialization
    init() {
        self.geometricAnalyzer = GeometricStrokeAnalyzer()
        print("✅ [UnifiedStrokeAnalyzer] Geometric analysis engine initialized")
    }
    
    // MARK: - Main Analysis Method
    func analyzeStroke(_ stroke: DrawingStroke, against guide: DrawingGuide) -> StrokeFeedback {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        print("🎨 [GEOMETRIC ANALYSIS] ========================================")
        print("🎨 [GEOMETRIC ANALYSIS] Starting geometric analysis for stroke with \(stroke.points.count) points")
        print("🎯 [GEOMETRIC ANALYSIS] Target guide: \(guide.shapes.first?.type.rawValue ?? "unknown")")
        print("📏 [GEOMETRIC ANALYSIS] Stroke bounds: \(calculateBoundingRect(for: stroke.points))")
        
        // MEMORY FIX: Use autoreleasepool for memory management
        return autoreleasepool {
            do {
                // Validate input with error handling
                guard !stroke.points.isEmpty else {
                    print("⚠️ [GEOMETRIC ANALYSIS] Empty stroke received - returning default feedback")
                    return createEmptyStrokeFeedback()
                }
                
                guard guide.shapes.first != nil else {
                    print("⚠️ [GEOMETRIC ANALYSIS] No guide shapes found - returning default feedback")
                    return createDefaultFeedback()
                }
                
                // MEMORY FIX: Check memory pressure before analysis
                let currentMemory = getCurrentMemoryUsageMB()
                if currentMemory > 150.0 {
                    print("⚠️ [GEOMETRIC ANALYSIS] High memory pressure detected (\(currentMemory)MB) - using simplified analysis")
                    return performSimplifiedAnalysis(stroke: stroke, guide: guide)
                }
                
                // Perform geometric analysis with error handling
                let analysisResult = try performGeometricAnalysisWithErrorHandling(stroke: stroke, guide: guide)
                
                // Record performance metrics
                let analysisTime = CFAbsoluteTimeGetCurrent() - startTime
                analysisMetrics.recordAnalysis(time: analysisTime, success: true)
                
                print("⏱️ [GEOMETRIC ANALYSIS] Analysis completed in \(String(format: "%.3f", analysisTime * 1000))ms")
                print("📊 [GEOMETRIC ANALYSIS] Result accuracy: \(String(format: "%.2f", analysisResult.accuracy))")
                print("🎯 [GEOMETRIC ANALYSIS] Result confidence: \(String(format: "%.2f", analysisResult.confidence))")
                print("🔍 [GEOMETRIC ANALYSIS] Detected shape: \(analysisResult.shapeType.rawValue)")
                
                // Generate feedback with error handling
                let feedback = try generateGeometricFeedbackWithErrorHandling(from: analysisResult, guide: guide)
                
                print("💬 [GEOMETRIC ANALYSIS] Generated \(feedback.suggestions.count) suggestions")
                print("✅ [GEOMETRIC ANALYSIS] Is correct: \(feedback.isCorrect)")
                if let artisticFeedback = feedback.artisticFeedback {
                    print("🎨 [GEOMETRIC ANALYSIS] Artistic score: \(String(format: "%.2f", artisticFeedback.overallScore))")
                }
                print("🎨 [GEOMETRIC ANALYSIS] ========================================")
                
                return feedback
                
            } catch {
                // MEMORY FIX: Cleanup on error
                cleanupOnError()
                
                // Record failed analysis
                let analysisTime = CFAbsoluteTimeGetCurrent() - startTime
                analysisMetrics.recordAnalysis(time: analysisTime, success: false)
                
                print("❌ [GEOMETRIC ANALYSIS] Analysis failed with error: \(error)")
                print("🧹 [GEOMETRIC ANALYSIS] Cleanup performed due to error")
                
                // Return fallback feedback
                return createErrorFallbackFeedback(error: error)
            }
        }
    }
    
    // MARK: - Geometric Analysis Implementation
    private func performGeometricAnalysis(stroke: DrawingStroke, guide: DrawingGuide) -> GeometricAnalysisResult {
        // Step 1: Preprocess stroke data
        let preprocessedStroke = preprocessStroke(stroke)
        
        // Step 2: Perform geometric analysis
        let geometricResult = geometricAnalyzer.analyzeStroke(preprocessedStroke.points, in: CGSize(width: 1000, height: 1000))
        
        // Step 3: Calculate accuracy against guide
        let accuracy = calculateAccuracyAgainstGuide(geometricResult, guide: guide)
        
        // Step 4: Create unified result
        return GeometricAnalysisResult(
            accuracy: accuracy,
            confidence: geometricResult.confidence,
            shapeType: geometricResult.shapeType,
            shapeMatch: isShapeMatch(geometricResult.shapeType, guide: guide),
            positionAccuracy: calculatePositionAccuracy(stroke, guide: guide),
            analysisMethod: .geometric,
            stroke: stroke,
            geometricResult: geometricResult
        )
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
    
    // MARK: - Accuracy Calculation
    private func calculateAccuracyAgainstGuide(_ geometricResult: GeometricStrokeAnalyzer.GeometricAnalysisResult, guide: DrawingGuide) -> Double {
        guard let targetShape = guide.shapes.first else { return 0.0 }
        
        // Base accuracy from geometric analysis
        var accuracy = geometricResult.confidence
        
        // Adjust based on shape type match
        if isShapeMatch(geometricResult.shapeType, guide: guide) {
            accuracy += 0.2
        }
        
        // Adjust based on geometric properties
        let properties = geometricResult.geometricProperties
        
        // Check if properties match expected shape characteristics
        switch targetShape.type {
        case .circle:
            if geometricResult.shapeType == .circle {
                accuracy += 0.3
            }
            // Check for circular properties
            if properties.symmetry > 0.7 {
                accuracy += 0.1
            }
            
        case .rectangle:
            if geometricResult.shapeType == .rectangle {
                accuracy += 0.3
            }
            // Check for rectangular properties
            if properties.symmetry > 0.6 {
                accuracy += 0.1
            }
            
        case .line:
            if geometricResult.shapeType == .line {
                accuracy += 0.3
            }
            // Check for straight line properties
            if properties.curvature < 0.1 {
                accuracy += 0.1
            }
            
        case .oval:
            if geometricResult.shapeType == .circle || geometricResult.shapeType == .curve {
                accuracy += 0.2
            }
            
        case .curve:
            if geometricResult.shapeType == .curve {
                accuracy += 0.3
            }
            // Check for curve properties
            if properties.curvature > 0.1 {
                accuracy += 0.1
            }
            
        case .polygon:
            if geometricResult.shapeType == .polygon {
                accuracy += 0.3
            }
        }
        
        return min(max(accuracy, 0.0), 1.0)
    }
    
    private func isShapeMatch(_ detectedShape: ShapeType, guide: DrawingGuide) -> Bool {
        guard let targetShape = guide.shapes.first else { return false }
        
        switch targetShape.type {
        case .circle:
            return detectedShape == .circle
        case .rectangle:
            return detectedShape == .rectangle
        case .line:
            return detectedShape == .line
        case .oval:
            return detectedShape == .circle || detectedShape == .curve
        case .curve:
            return detectedShape == .curve
        case .polygon:
            return detectedShape == .polygon
        }
    }
    
    private func calculatePositionAccuracy(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
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
    
    // MARK: - Feedback Generation
    private func generateGeometricFeedback(from result: GeometricAnalysisResult, guide: DrawingGuide) -> StrokeFeedback {
        print("💬 [FEEDBACK GENERATION] Generating geometric feedback for accuracy: \(String(format: "%.3f", result.accuracy))")
        
        let suggestions = generateGeometricSuggestions(from: result, guide: guide)
        let isCorrect = result.accuracy >= Config.confidenceThreshold
        
        print("✅ [FEEDBACK GENERATION] Is correct: \(isCorrect) (threshold: \(Config.confidenceThreshold))")
        print("💡 [FEEDBACK GENERATION] Generated \(suggestions.count) suggestions")
        
        // Generate artistic feedback alongside technical feedback
        let artisticContext = createArtisticContext(for: guide)
        let strokeForAnalysis = result.stroke ?? createStrokeFromResult(result)
        
        var artisticFeedback: ArtisticFeedback? = nil
        if let strokeForAnalysis = strokeForAnalysis {
            artisticFeedback = artisticFeedbackEngine.analyzeArtisticQuality(
            strokeForAnalysis,
            against: guide,
            context: artisticContext
        )
        
        print("🎨 [FEEDBACK GENERATION] Artistic feedback generated:")
            print("   📊 Overall score: \(String(format: "%.3f", artisticFeedback?.overallScore ?? 0))")
            print("   💡 Artistic suggestions: \(artisticFeedback?.suggestions.count ?? 0)")
            print("   🌟 Encouragement: \(artisticFeedback?.encouragement ?? "")")
        }
        
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
            dtwDistance: nil,
            temporalAccuracy: nil,
            velocityConsistency: nil,
            spatialAlignment: nil,
            confidenceScore: result.confidence,
            artisticFeedback: artisticFeedback
        )
    }
    
    private func generateGeometricSuggestions(from result: GeometricAnalysisResult, guide: DrawingGuide) -> [String] {
        var suggestions: [String] = []
        
        // Use geometric analysis feedback
        if let geometricResult = result.geometricResult {
            suggestions.append(geometricResult.feedback)
            suggestions.append(contentsOf: geometricResult.suggestions)
        }
        
        // Add accuracy-based suggestions
        if result.accuracy < Config.confidenceThreshold {
            suggestions.append("📐 Try to match the guide shape more closely - you're getting better!")
            
            if result.positionAccuracy < 0.7 {
                suggestions.append("📍 Focus on positioning - aim for the guide markers!")
            }
            
            if !result.shapeMatch {
                suggestions.append("🎯 Try to match the shape type - you're on the right track!")
            }
        } else {
            suggestions.append("🌟 Excellent! Your drawing matches the guide perfectly!")
        }
        
        return suggestions.isEmpty ? ["💪 Keep practicing - you're doing great!"] : suggestions
    }
    
    private func generateCorrectionPoints(from result: GeometricAnalysisResult, guide: DrawingGuide) -> [CGPoint] {
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
    
    private func createArtisticContext(for guide: DrawingGuide) -> ArtisticContext {
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
    
    private func combineTechnicalAndArtisticSuggestions(technicalSuggestions: [String], artisticFeedback: ArtisticFeedback?) -> [String] {
        var combined = technicalSuggestions
        if let artistic = artisticFeedback {
            combined.append(contentsOf: artistic.suggestions)
        }
        return Array(Set(combined)).sorted() // Remove duplicates and sort
    }
    
    private func createStrokeFromResult(_ result: GeometricAnalysisResult) -> DrawingStroke? {
        if let stroke = result.stroke {
            return stroke
        }
        return nil
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
    
    // MARK: - Error Handling and Memory Management
    
    /// MEMORY FIX: Get current memory usage in MB
    private func getCurrentMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024)
        }
        
        return 50.0 // Safe default
    }
    
    /// MEMORY FIX: Perform simplified analysis under memory pressure
    private func performSimplifiedAnalysis(stroke: DrawingStroke, guide: DrawingGuide) -> StrokeFeedback {
        print("🧹 [SIMPLIFIED ANALYSIS] Using simplified analysis due to memory pressure")
        
        // Use basic geometric analysis without complex calculations
        let basicAccuracy = calculateBasicAccuracy(stroke: stroke, guide: guide)
        
        return StrokeFeedback(
            accuracy: basicAccuracy,
            suggestions: ["💡 Keep practicing! Your drawing is improving."],
            correctionPoints: [],
            isCorrect: basicAccuracy >= 0.6,
            confidenceScore: basicAccuracy
        )
    }
    
    /// MEMORY FIX: Calculate basic accuracy without complex analysis
    private func calculateBasicAccuracy(stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        guard !stroke.points.isEmpty, let targetShape = guide.shapes.first else { return 0.5 }
        
        let strokeCenter = calculateCenterPoint(of: stroke.points)
        let targetCenter = targetShape.center
        
        let distance = self.distance(from: strokeCenter, to: targetCenter)
        let maxDistance = max(targetShape.dimensions.width, targetShape.dimensions.height)
        
        return max(0.0, 1.0 - (distance / maxDistance))
    }
    
    /// MEMORY FIX: Perform geometric analysis with error handling
    private func performGeometricAnalysisWithErrorHandling(stroke: DrawingStroke, guide: DrawingGuide) throws -> GeometricAnalysisResult {
        do {
            // Step 1: Preprocess stroke data with error handling
            let preprocessedStroke = try preprocessStrokeWithErrorHandling(stroke)
            
            // Step 2: Perform geometric analysis with timeout
            let geometricResult = try geometricAnalyzer.analyzeStrokeWithTimeout(
                preprocessedStroke.points, 
                in: CGSize(width: 1000, height: 1000),
                timeout: Config.analysisTimeout
            )
            
            // Step 3: Calculate accuracy against guide
            let accuracy = try calculateAccuracyAgainstGuideWithErrorHandling(geometricResult, guide: guide)
            
            // Step 4: Create unified result
            return GeometricAnalysisResult(
                accuracy: accuracy,
                confidence: geometricResult.confidence,
                shapeType: geometricResult.shapeType,
                shapeMatch: isShapeMatch(geometricResult.shapeType, guide: guide),
                positionAccuracy: calculatePositionAccuracy(stroke, guide: guide),
                analysisMethod: .geometric,
                stroke: stroke,
                geometricResult: geometricResult
            )
            
        } catch {
            print("❌ [GEOMETRIC ANALYSIS] Error in geometric analysis: \(error)")
            throw AnalysisError.geometricAnalysisFailed(error)
        }
    }
    
    /// MEMORY FIX: Preprocess stroke with error handling
    private func preprocessStrokeWithErrorHandling(_ stroke: DrawingStroke) throws -> DrawingStroke {
        do {
            // Normalize stroke points with bounds checking
            let normalizedPoints = try normalizeStrokePointsWithErrorHandling(stroke.points)
            
            // Resample if necessary with size limits
            let resampledPoints = try resampleStrokeWithErrorHandling(normalizedPoints, targetCount: Config.maxStrokePoints)
            
            // Smooth the stroke with error handling
            let smoothedPoints = try smoothStrokeWithErrorHandling(resampledPoints)
            
            return DrawingStroke(
                points: smoothedPoints,
                timestamp: stroke.timestamp,
                pressure: Array(stroke.pressure.prefix(smoothedPoints.count)),
                velocity: Array(stroke.velocity.prefix(smoothedPoints.count))
            )
            
        } catch {
            print("❌ [PREPROCESSING] Error in stroke preprocessing: \(error)")
            throw AnalysisError.preprocessingFailed(error)
        }
    }
    
    /// MEMORY FIX: Normalize stroke points with error handling
    private func normalizeStrokePointsWithErrorHandling(_ points: [CGPoint]) throws -> [CGPoint] {
        guard !points.isEmpty else { 
            throw AnalysisError.emptyStroke 
        }
        
        guard points.count <= 1000 else {
            throw AnalysisError.strokeTooLarge(points.count)
        }
        
        // Calculate bounding box with error handling
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        let width = maxX - minX
        let height = maxY - minY
        let maxDimension = max(width, height)
        
        guard maxDimension > 0 else { 
            throw AnalysisError.invalidStrokeDimensions 
        }
        
        // Normalize to 0-1 range
        return points.map { point in
            CGPoint(
                x: (point.x - minX) / maxDimension,
                y: (point.y - minY) / maxDimension
            )
        }
    }
    
    /// MEMORY FIX: Resample stroke with error handling
    private func resampleStrokeWithErrorHandling(_ points: [CGPoint], targetCount: Int) throws -> [CGPoint] {
        guard points.count > targetCount else { return points }
        guard targetCount > 0 && targetCount <= 200 else {
            throw AnalysisError.invalidTargetCount(targetCount)
        }
        
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
    
    /// MEMORY FIX: Smooth stroke with error handling
    private func smoothStrokeWithErrorHandling(_ points: [CGPoint]) throws -> [CGPoint] {
        guard points.count > 2 else { return points }
        guard points.count <= 200 else {
            throw AnalysisError.strokeTooLarge(points.count)
        }
        
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
    
    /// MEMORY FIX: Calculate accuracy with error handling
    private func calculateAccuracyAgainstGuideWithErrorHandling(_ geometricResult: GeometricStrokeAnalyzer.GeometricAnalysisResult, guide: DrawingGuide) throws -> Double {
        guard let targetShape = guide.shapes.first else { 
            throw AnalysisError.noTargetShape 
        }
        
        // Base accuracy from geometric analysis
        var accuracy = geometricResult.confidence
        
        // Adjust based on shape type match
        if isShapeMatch(geometricResult.shapeType, guide: guide) {
            accuracy += 0.2
        }
        
        // Adjust based on geometric properties
        let properties = geometricResult.geometricProperties
        
        // Check if properties match expected shape characteristics
        switch targetShape.type {
        case .circle:
            if geometricResult.shapeType == .circle {
                accuracy += 0.3
            }
            if properties.symmetry > 0.7 {
                accuracy += 0.1
            }
            
        case .rectangle:
            if geometricResult.shapeType == .rectangle {
                accuracy += 0.3
            }
            if properties.symmetry > 0.6 {
                accuracy += 0.1
            }
            
        case .line:
            if geometricResult.shapeType == .line {
                accuracy += 0.3
            }
            if properties.curvature < 0.1 {
                accuracy += 0.1
            }
            
        case .oval:
            if geometricResult.shapeType == .circle || geometricResult.shapeType == .curve {
                accuracy += 0.2
            }
            
        case .curve:
            if geometricResult.shapeType == .curve {
                accuracy += 0.3
            }
            if properties.curvature > 0.1 {
                accuracy += 0.1
            }
            
        case .polygon:
            if geometricResult.shapeType == .polygon {
                accuracy += 0.3
            }
        }
        
        return min(max(accuracy, 0.0), 1.0)
    }
    
    /// MEMORY FIX: Generate feedback with error handling
    private func generateGeometricFeedbackWithErrorHandling(from result: GeometricAnalysisResult, guide: DrawingGuide) throws -> StrokeFeedback {
        do {
            let suggestions = generateGeometricSuggestions(from: result, guide: guide)
            let isCorrect = result.accuracy >= Config.confidenceThreshold
            
            // Generate artistic feedback with error handling
            var artisticFeedback: ArtisticFeedback? = nil
            if let strokeForAnalysis = result.stroke {
                do {
                    let artisticContext = createArtisticContext(for: guide)
                    artisticFeedback = try artisticFeedbackEngine.analyzeArtisticQualityWithErrorHandling(
                        strokeForAnalysis,
                        against: guide,
                        context: artisticContext
                    )
                } catch {
                    print("⚠️ [ARTISTIC FEEDBACK] Failed to generate artistic feedback: \(error)")
                    // Continue without artistic feedback
                }
            }
            
            // Combine technical and artistic suggestions
            let combinedSuggestions = combineTechnicalAndArtisticSuggestions(
                technicalSuggestions: suggestions,
                artisticFeedback: artisticFeedback
            )
            
            return StrokeFeedback(
                accuracy: result.accuracy,
                suggestions: combinedSuggestions,
                correctionPoints: generateCorrectionPoints(from: result, guide: guide),
                isCorrect: isCorrect,
                dtwDistance: nil,
                temporalAccuracy: nil,
                velocityConsistency: nil,
                spatialAlignment: nil,
                confidenceScore: result.confidence,
                artisticFeedback: artisticFeedback
            )
            
        } catch {
            print("❌ [FEEDBACK GENERATION] Error generating feedback: \(error)")
            throw AnalysisError.feedbackGenerationFailed(error)
        }
    }
    
    /// MEMORY FIX: Cleanup on error
    private func cleanupOnError() {
        print("🧹 [CLEANUP] Performing cleanup due to error")
        
        // Clear analysis cache
        analysisCache.removeAll(keepingCapacity: false)
        
        // Reset geometric analyzer if needed
        geometricAnalyzer = GeometricStrokeAnalyzer()
        
        // Clear any pending operations
        // Note: This would be expanded based on specific cleanup needs
    }
    
    /// MEMORY FIX: Create error fallback feedback
    private func createErrorFallbackFeedback(error: Error) -> StrokeFeedback {
        let errorMessage = switch error {
        case AnalysisError.emptyStroke:
            "Please draw something to get feedback!"
        case AnalysisError.strokeTooLarge(let count):
            "Stroke too large (\(count) points). Try a simpler drawing."
        case AnalysisError.invalidStrokeDimensions:
            "Invalid stroke dimensions. Please try again."
        case AnalysisError.noTargetShape:
            "No target shape found. Please select a guide."
        case AnalysisError.geometricAnalysisFailed(let innerError):
            "Analysis failed: \(innerError.localizedDescription)"
        case AnalysisError.preprocessingFailed(let innerError):
            "Preprocessing failed: \(innerError.localizedDescription)"
        case AnalysisError.feedbackGenerationFailed(let innerError):
            "Feedback generation failed: \(innerError.localizedDescription)"
        default:
            "Something went wrong. Please try again."
        }
        
        return StrokeFeedback(
            accuracy: 0.5,
            suggestions: [errorMessage],
            correctionPoints: [],
            isCorrect: false,
            confidenceScore: 0.0
        )
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> AnalysisMetrics {
        return analysisMetrics
    }
}

// MARK: - Supporting Data Structures

struct GeometricAnalysisResult {
    let accuracy: Double
    let confidence: Double
    let shapeType: ShapeType
    let shapeMatch: Bool
    let positionAccuracy: Double
    let analysisMethod: AnalysisMethod
    let stroke: DrawingStroke?
    let geometricResult: GeometricStrokeAnalyzer.GeometricAnalysisResult
}

enum AnalysisMethod {
    case geometric
    case hybrid
}

// MARK: - Error Types for Memory Management
enum AnalysisError: Error, LocalizedError {
    case emptyStroke
    case strokeTooLarge(Int)
    case invalidStrokeDimensions
    case invalidTargetCount(Int)
    case noTargetShape
    case geometricAnalysisFailed(Error)
    case preprocessingFailed(Error)
    case feedbackGenerationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .emptyStroke:
            return "Empty stroke provided"
        case .strokeTooLarge(let count):
            return "Stroke too large: \(count) points"
        case .invalidStrokeDimensions:
            return "Invalid stroke dimensions"
        case .invalidTargetCount(let count):
            return "Invalid target count: \(count)"
        case .noTargetShape:
            return "No target shape found"
        case .geometricAnalysisFailed(let error):
            return "Geometric analysis failed: \(error.localizedDescription)"
        case .preprocessingFailed(let error):
            return "Preprocessing failed: \(error.localizedDescription)"
        case .feedbackGenerationFailed(let error):
            return "Feedback generation failed: \(error.localizedDescription)"
        }
    }
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
}

// MARK: - Extensions

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}