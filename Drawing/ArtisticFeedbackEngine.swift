import Foundation
import CoreML
import Vision
import CoreGraphics
import SwiftUI

// MARK: - Artistic Feedback Engine
@MainActor
class ArtisticFeedbackEngine: ObservableObject {
    
    // MARK: - Configuration
    private struct Config {
        static let artisticAnalysisTimeout: TimeInterval = 0.15 // 150ms for real-time
        static let confidenceThreshold: Float = 0.6
        static let maxSuggestions = 3
    }
    
    // MARK: - Artistic Analysis Models
    private var compositionAnalyzer: MLModel?
    private var styleAnalyzer: MLModel?
    private var colorHarmonyAnalyzer: MLModel?
    
    // MARK: - Performance Monitoring
    private var analysisMetrics = ArtisticAnalysisMetrics()
    
    // MARK: - Initialization
    init() {
        setupArtisticAnalysisModels()
    }
    
    // MARK: - Model Setup
    private func setupArtisticAnalysisModels() {
        // For now, we'll use Vision framework for artistic analysis
        // In production, you would load trained Core ML models for:
        // - Composition analysis
        // - Style recognition
        // - Color harmony evaluation
        
        print("🎨 [ArtisticFeedbackEngine] Initialized with Vision framework artistic analysis")
    }
    
    // MARK: - Main Artistic Analysis Method
    func analyzeArtisticQuality(_ stroke: DrawingStroke, against guide: DrawingGuide, context: ArtisticContext) -> ArtisticFeedback {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        print("🎨 [ARTISTIC ANALYSIS] ========================================")
        print("🎨 [ARTISTIC ANALYSIS] Starting artistic analysis for stroke with \(stroke.points.count) points")
        print("🎯 [ARTISTIC ANALYSIS] Target guide: \(guide.shapes.first?.type.rawValue ?? "unknown")")
        print("👤 [ARTISTIC ANALYSIS] User level: \(context.userLevel)")
        print("🎨 [ARTISTIC ANALYSIS] Lesson category: \(context.lessonCategory)")
        
        // Perform comprehensive artistic analysis using geometric methods
        let compositionAnalysis = analyzeCompositionGeometric(stroke, guide: guide)
        let styleAnalysis = analyzeStyleGeometric(stroke, guide: guide)
        let colorAnalysis = analyzeColorHarmonyGeometric(stroke, guide: guide)
        let creativityAnalysis = analyzeCreativityGeometric(stroke, guide: guide, context: context)
        
        // Combine analyses into unified feedback
        let artisticFeedback = combineArtisticAnalyses(
            composition: compositionAnalysis,
            style: styleAnalysis,
            color: colorAnalysis,
            creativity: creativityAnalysis,
            context: context
        )
        
        // Record performance metrics
        let analysisTime = CFAbsoluteTimeGetCurrent() - startTime
        analysisMetrics.recordAnalysis(time: analysisTime, success: true)
        
        print("⏱️ [ARTISTIC ANALYSIS] Analysis completed in \(String(format: "%.3f", analysisTime * 1000))ms")
        print("📊 [ARTISTIC ANALYSIS] Overall score: \(String(format: "%.3f", artisticFeedback.overallScore))")
        print("💡 [ARTISTIC ANALYSIS] Generated \(artisticFeedback.suggestions.count) suggestions")
        print("🌟 [ARTISTIC ANALYSIS] Encouragement: \(artisticFeedback.encouragement)")
        print("🎨 [ARTISTIC ANALYSIS] ========================================")
        
        return artisticFeedback
    }
    
    // MARK: - Geometric Composition Analysis
    private func analyzeCompositionGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> CompositionAnalysis {
        // Analyze visual composition principles using geometric calculations
        let balance = analyzeVisualBalanceGeometric(stroke, guide: guide)
        let proportion = analyzeProportionGeometric(stroke, guide: guide)
        let rhythm = analyzeRhythmGeometric(stroke, guide: guide)
        let emphasis = analyzeEmphasisGeometric(stroke, guide: guide)
        
        return CompositionAnalysis(
            balance: balance,
            proportion: proportion,
            rhythm: rhythm,
            emphasis: emphasis,
            overallScore: (balance + proportion + rhythm + emphasis) / 4.0
        )
    }
    
    private func analyzeVisualBalanceGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze visual weight distribution using geometric calculations
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        // Calculate center of mass
        let strokeCenter = calculateCenterPoint(of: stroke.points)
        let guideCenter = calculateCenterPoint(of: guide.targetPoints)
        
        // Calculate distance from center
        let centerDistance = distance(from: strokeCenter, to: guideCenter)
        let maxDistance = max(guideBounds.width, guideBounds.height) * 0.5
        
        // Balance score based on how close the stroke center is to the guide center
        let balanceScore = max(0.0, 1.0 - (centerDistance / maxDistance))
        
        return balanceScore
    }
    
    private func analyzeProportionGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        guard let targetShape = guide.shapes.first else { return 0.5 }
        
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let targetWidth = targetShape.dimensions.width
        let targetHeight = targetShape.dimensions.height
        
        // Calculate aspect ratio accuracy
        let strokeAspectRatio = strokeBounds.width / strokeBounds.height
        let targetAspectRatio = targetWidth / targetHeight
        
        let aspectRatioAccuracy = 1.0 - min(abs(strokeAspectRatio - targetAspectRatio) / targetAspectRatio, 1.0)
        
        // Calculate size accuracy
        let sizeAccuracy = 1.0 - min(abs(strokeBounds.width - targetWidth) / targetWidth, 1.0)
        
        return (aspectRatioAccuracy + sizeAccuracy) / 2.0
    }
    
    private func analyzeRhythmGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze rhythm using stroke velocity and pressure patterns
        let velocityConsistency = analyzeVelocityConsistency(stroke)
        let pressureConsistency = analyzePressureConsistency(stroke)
        
        return (velocityConsistency + pressureConsistency) / 2.0
    }
    
    private func analyzeEmphasisGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze emphasis using stroke characteristics
        let strokeLength = calculateStrokeLength(stroke.points)
        let guideLength = calculateGuideLength(guide)
        
        // Emphasis score based on stroke strength relative to guide
        let emphasisScore = min(strokeLength / guideLength, 1.0)
        
        return emphasisScore
    }
    
    // MARK: - Geometric Style Analysis
    private func analyzeStyleGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> StyleAnalysis {
        let lineQuality = analyzeLineQualityGeometric(stroke)
        let strokeConsistency = analyzeStrokeConsistencyGeometric(stroke)
        let artisticExpression = analyzeArtisticExpressionGeometric(stroke, guide: guide)
        
        return StyleAnalysis(
            lineQuality: lineQuality,
            strokeConsistency: strokeConsistency,
            artisticExpression: artisticExpression,
            overallScore: (lineQuality + strokeConsistency + artisticExpression) / 3.0
        )
    }
    
    private func analyzeLineQualityGeometric(_ stroke: DrawingStroke) -> Double {
        // Analyze line quality using geometric properties
        let smoothness = analyzeSmoothnessGeometric(stroke)
        let consistency = analyzeLineConsistencyGeometric(stroke)
        
        return (smoothness + consistency) / 2.0
    }
    
    private func analyzeSmoothnessGeometric(_ stroke: DrawingStroke) -> Double {
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
    
    private func analyzeLineConsistencyGeometric(_ stroke: DrawingStroke) -> Double {
        guard stroke.points.count > 1 else { return 1.0 }
        
        let distances = calculateSegmentDistances(stroke.points)
        let averageDistance = distances.reduce(0, +) / Double(distances.count)
        
        let variance = distances.map { pow($0 - averageDistance, 2) }.reduce(0, +) / Double(distances.count)
        let standardDeviation = sqrt(variance)
        
        return max(0.0, 1.0 - (standardDeviation / averageDistance))
    }
    
    private func analyzeStrokeConsistencyGeometric(_ stroke: DrawingStroke) -> Double {
        // Analyze consistency of stroke characteristics
        let pressureConsistency = analyzePressureConsistency(stroke)
        let velocityConsistency = analyzeVelocityConsistency(stroke)
        
        return (pressureConsistency + velocityConsistency) / 2.0
    }
    
    private func analyzeArtisticExpressionGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze artistic expression using geometric properties
        let strokeVariation = analyzeStrokeVariation(stroke)
        let creativeDeviation = analyzeCreativeDeviation(stroke, guide: guide)
        
        return (strokeVariation + creativeDeviation) / 2.0
    }
    
    // MARK: - Geometric Color Analysis
    private func analyzeColorHarmonyGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> ColorAnalysis {
        // For now, return basic color analysis since we're focusing on geometric properties
        // In a full implementation, this would analyze color relationships
        return ColorAnalysis(
            harmony: 0.7,
            contrast: 0.6,
            saturation: 0.5,
            overallScore: 0.6
        )
    }
    
    // MARK: - Geometric Creativity Analysis
    private func analyzeCreativityGeometric(_ stroke: DrawingStroke, guide: DrawingGuide, context: ArtisticContext) -> CreativityAnalysis {
        let originality = analyzeOriginalityGeometric(stroke, guide: guide)
        let innovation = analyzeInnovationGeometric(stroke, guide: guide)
        let artisticRisk = analyzeArtisticRiskGeometric(stroke, guide: guide, context: context)
        
        return CreativityAnalysis(
            originality: originality,
            innovation: innovation,
            artisticRisk: artisticRisk,
            overallScore: (originality + innovation + artisticRisk) / 3.0
        )
    }
    
    private func analyzeOriginalityGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze originality using geometric deviation from guide
        let deviation = calculateGeometricDeviation(stroke, guide: guide)
        return min(deviation, 1.0)
    }
    
    private func analyzeInnovationGeometric(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze innovation using creative geometric patterns
        let patternComplexity = analyzePatternComplexity(stroke)
        return min(patternComplexity, 1.0)
    }
    
    private func analyzeArtisticRiskGeometric(_ stroke: DrawingStroke, guide: DrawingGuide, context: ArtisticContext) -> Double {
        // Analyze artistic risk based on user level and stroke characteristics
        let baseRisk = calculateBaseRisk(stroke, guide: guide)
        let userLevelMultiplier = getUserLevelMultiplier(context.userLevel)
        
        return min(baseRisk * userLevelMultiplier, 1.0)
    }
    
    // MARK: - Composition Analysis (Legacy - keeping for compatibility)
    private func analyzeComposition(_ stroke: DrawingStroke, guide: DrawingGuide) -> CompositionAnalysis {
        // Analyze visual composition principles
        let balance = analyzeVisualBalance(stroke, guide: guide)
        let proportion = analyzeProportion(stroke, guide: guide)
        let rhythm = analyzeRhythm(stroke, guide: guide)
        let emphasis = analyzeEmphasis(stroke, guide: guide)
        
        return CompositionAnalysis(
            balance: balance,
            proportion: proportion,
            rhythm: rhythm,
            emphasis: emphasis,
            overallScore: (balance + proportion + rhythm + emphasis) / 4.0
        )
    }
    
    private func analyzeVisualBalance(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze visual weight distribution
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        // Check if stroke is centered within guide
        let centerOffset = distance(from: strokeBounds.center, to: guideBounds.center)
        let maxOffset = max(guideBounds.width, guideBounds.height) * 0.3
        
        return max(0.0, 1.0 - (centerOffset / maxOffset))
    }
    
    private func analyzeProportion(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze size relationships
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        let widthRatio = strokeBounds.width / guideBounds.width
        let heightRatio = strokeBounds.height / guideBounds.height
        
        // Ideal ratio is close to 1.0
        let widthAccuracy = 1.0 - abs(widthRatio - 1.0)
        let heightAccuracy = 1.0 - abs(heightRatio - 1.0)
        
        return (widthAccuracy + heightAccuracy) / 2.0
    }
    
    private func analyzeRhythm(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze stroke rhythm and flow
        guard stroke.points.count > 3 else { return 0.5 }
        
        var rhythmScore = 0.0
        let segmentSize = max(1, stroke.points.count / 5)
        
        for i in 0..<(stroke.points.count - segmentSize) {
            let segment = Array(stroke.points[i..<(i + segmentSize)])
            let segmentRhythm = calculateSegmentRhythm(segment)
            rhythmScore += segmentRhythm
        }
        
        return min(1.0, rhythmScore / Double(stroke.points.count / segmentSize))
    }
    
    private func calculateSegmentRhythm(_ points: [CGPoint]) -> Double {
        guard points.count > 2 else { return 0.5 }
        
        var totalVariation = 0.0
        for i in 1..<points.count {
            let distance = distance(from: points[i-1], to: points[i])
            totalVariation += distance
        }
        
        let averageDistance = totalVariation / Double(points.count - 1)
        let variance = points.enumerated().dropFirst().map { (i, point) in
            let dist = distance(from: points[i-1], to: point)
            return pow(dist - averageDistance, 2)
        }.reduce(0, +) / Double(points.count - 1)
        
        // Lower variance = more consistent rhythm
        return max(0.0, 1.0 - sqrt(variance) / averageDistance)
    }
    
    private func analyzeEmphasis(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze focal points and emphasis
        guard let primaryShape = guide.shapes.first else { return 0.5 }
        
        // Check if stroke emphasizes the main shape
        let strokeCenter = calculateCenterPoint(of: stroke.points)
        let guideCenter = primaryShape.center
        
        let centerAlignment = 1.0 - min(distance(from: strokeCenter, to: guideCenter) / 100.0, 1.0)
        
        // Check stroke weight consistency (emphasis through contrast)
        let strokeWeightConsistency = analyzeStrokeWeightConsistency(stroke)
        
        return (centerAlignment + strokeWeightConsistency) / 2.0
    }
    
    private func analyzeStrokeWeightConsistency(_ stroke: DrawingStroke) -> Double {
        guard !stroke.pressure.isEmpty else { return 0.7 }
        
        let avgPressure = stroke.pressure.reduce(0, +) / Double(stroke.pressure.count)
        let variance = stroke.pressure.map { Foundation.pow($0 - avgPressure, 2) }.reduce(0, +) / Double(stroke.pressure.count)
        
        // Moderate variance is good for emphasis
        let idealVariance = 0.1
        return max(0.0, 1.0 - abs(sqrt(variance) - idealVariance) / idealVariance)
    }
    
    // MARK: - Style Analysis
    private func analyzeStyle(_ stroke: DrawingStroke, guide: DrawingGuide) -> StyleAnalysis {
        let lineQuality = analyzeLineQuality(stroke)
        let expressiveness = analyzeExpressiveness(stroke)
        let technique = analyzeTechnique(stroke, guide: guide)
        
        return StyleAnalysis(
            lineQuality: lineQuality,
            expressiveness: expressiveness,
            technique: technique,
            overallScore: (lineQuality + expressiveness + technique) / 3.0
        )
    }
    
    private func analyzeLineQuality(_ stroke: DrawingStroke) -> Double {
        guard stroke.points.count > 2 else { return 0.5 }
        
        // Analyze line smoothness and confidence
        let smoothness = analyzeSmoothness(stroke)
        let confidence = analyzeStrokeConfidence(stroke)
        
        return (smoothness + confidence) / 2.0
    }
    
    private func analyzeSmoothness(_ stroke: DrawingStroke) -> Double {
        guard stroke.points.count > 2 else { return 0.5 }
        
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
    
    private func analyzeStrokeConfidence(_ stroke: DrawingStroke) -> Double {
        // Analyze stroke confidence based on velocity consistency
        guard stroke.velocity.count > 1 else { return 0.7 }
        
        let avgVelocity = stroke.velocity.reduce(0, +) / Double(stroke.velocity.count)
        let velocityVariance = stroke.velocity.map { Foundation.pow($0 - avgVelocity, 2) }.reduce(0, +) / Double(stroke.velocity.count)
        
        // Lower variance indicates more confident strokes
        return max(0.0, 1.0 - sqrt(velocityVariance) / avgVelocity)
    }
    
    private func analyzeExpressiveness(_ stroke: DrawingStroke) -> Double {
        // Analyze artistic expressiveness
        let pressureVariation = analyzePressureVariation(stroke)
        let velocityVariation = analyzeVelocityVariation(stroke)
        let gesturalQuality = analyzeGesturalQuality(stroke)
        
        return (pressureVariation + velocityVariation + gesturalQuality) / 3.0
    }
    
    private func analyzePressureVariation(_ stroke: DrawingStroke) -> Double {
        guard !stroke.pressure.isEmpty else { return 0.5 }
        
        let minPressure = stroke.pressure.min() ?? 0
        let maxPressure = stroke.pressure.max() ?? 1
        let pressureRange = maxPressure - minPressure
        
        // Good expressiveness has moderate pressure variation
        return min(1.0, pressureRange * 2.0)
    }
    
    private func analyzeVelocityVariation(_ stroke: DrawingStroke) -> Double {
        guard stroke.velocity.count > 1 else { return 0.5 }
        
        let minVelocity = stroke.velocity.min() ?? 0
        let maxVelocity = stroke.velocity.max() ?? 1
        let velocityRange = maxVelocity - minVelocity
        
        // Good expressiveness has moderate velocity variation
        return min(1.0, velocityRange / 2.0)
    }
    
    private func analyzeGesturalQuality(_ stroke: DrawingStroke) -> Double {
        // Analyze the gestural quality of the stroke
        guard stroke.points.count > 3 else { return 0.5 }
        
        // Check for natural, flowing movements
        let flowScore = analyzeFlow(stroke)
        let spontaneityScore = analyzeSpontaneity(stroke)
        
        return (flowScore + spontaneityScore) / 2.0
    }
    
    private func analyzeFlow(_ stroke: DrawingStroke) -> Double {
        // Analyze the flow of the stroke
        guard stroke.points.count > 2 else { return 0.5 }
        
        var flowScore = 0.0
        for i in 1..<stroke.points.count {
            let distance = distance(from: stroke.points[i-1], to: stroke.points[i])
            // Consistent distances indicate good flow
            flowScore += min(1.0, distance / 10.0)
        }
        
        return min(1.0, flowScore / Double(stroke.points.count - 1))
    }
    
    private func analyzeSpontaneity(_ stroke: DrawingStroke) -> Double {
        // Analyze the spontaneity of the stroke
        guard stroke.points.count > 3 else { return 0.5 }
        
        // Look for natural variations in direction and speed
        var directionChanges = 0
        for i in 2..<stroke.points.count {
            let angle1 = atan2(stroke.points[i-1].y - stroke.points[i-2].y, 
                              stroke.points[i-1].x - stroke.points[i-2].x)
            let angle2 = atan2(stroke.points[i].y - stroke.points[i-1].y, 
                              stroke.points[i].x - stroke.points[i-1].x)
            
            let angleDiff = abs(angle2 - angle1)
            if angleDiff > .pi / 6 { // 30 degrees
                directionChanges += 1
            }
        }
        
        // Moderate direction changes indicate spontaneity
        let expectedChanges = stroke.points.count / 10
        let spontaneityRatio = Double(directionChanges) / Double(expectedChanges)
        
        return max(0.0, 1.0 - abs(spontaneityRatio - 1.0))
    }
    
    private func analyzeTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze drawing technique appropriateness
        guard let primaryShape = guide.shapes.first else { return 0.5 }
        
        let techniqueScore = switch primaryShape.type {
        case .circle:
            analyzeCircleTechnique(stroke, guide: guide)
        case .rectangle:
            analyzeRectangleTechnique(stroke, guide: guide)
        case .line:
            analyzeLineTechnique(stroke, guide: guide)
        case .oval:
            analyzeOvalTechnique(stroke, guide: guide)
        case .curve:
            analyzeCurveTechnique(stroke, guide: guide)
        case .polygon:
            analyzePolygonTechnique(stroke, guide: guide)
        }
        
        return techniqueScore
    }
    
    private func analyzeCircleTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze circular drawing technique
        guard let primaryShape = guide.shapes.first else { return 0.5 }
        
        let center = primaryShape.center
        let targetRadius = primaryShape.dimensions.width / 2
        
        // Check for circular motion
        let distances = stroke.points.map { point in
            distance(from: point, to: center)
        }
        
        let avgDistance = distances.reduce(0, +) / Double(distances.count)
        let radiusAccuracy = 1.0 - min(abs(avgDistance - targetRadius) / targetRadius, 1.0)
        
        // Check for consistent radius
        let radiusVariance = distances.map { pow($0 - avgDistance, 2) }.reduce(0, +) / Double(distances.count)
        let consistencyScore = max(0.0, 1.0 - sqrt(radiusVariance) / targetRadius)
        
        return (radiusAccuracy + consistencyScore) / 2.0
    }
    
    private func analyzeRectangleTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze rectangular drawing technique
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        let aspectRatioAccuracy = 1.0 - abs(strokeBounds.width / strokeBounds.height - guideBounds.width / guideBounds.height)
        let sizeAccuracy = 1.0 - abs(strokeBounds.width - guideBounds.width) / guideBounds.width
        
        return (aspectRatioAccuracy + sizeAccuracy) / 2.0
    }
    
    private func analyzeLineTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze line drawing technique
        guard stroke.points.count >= 2, guide.targetPoints.count >= 2 else { return 0.5 }
        
        let straightness = analyzeStraightness(stroke.points)
        let startAccuracy = 1.0 - min(distance(from: stroke.points.first!, to: guide.targetPoints.first!) / 50.0, 1.0)
        let endAccuracy = 1.0 - min(distance(from: stroke.points.last!, to: guide.targetPoints.last!) / 50.0, 1.0)
        
        return (straightness + startAccuracy + endAccuracy) / 3.0
    }
    
    private func analyzeOvalTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze oval drawing technique
        return analyzeCircleTechnique(stroke, guide: guide) * 0.8 // Similar to circle but less strict
    }
    
    private func analyzeCurveTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze curve drawing technique
        let smoothness = analyzeSmoothness(stroke)
        let flow = analyzeFlow(stroke)
        
        return (smoothness + flow) / 2.0
    }
    
    private func analyzePolygonTechnique(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze polygon drawing technique
        let corners = detectCorners(in: stroke.points)
        let expectedCorners = guide.targetPoints.count
        
        let cornerCountAccuracy = 1.0 - min(abs(Double(corners.count - expectedCorners)) / Double(expectedCorners), 1.0)
        let cornerPrecision = analyzeCornerPrecision(corners, targetCorners: guide.targetPoints)
        
        return (cornerCountAccuracy + cornerPrecision) / 2.0
    }
    
    private func analyzeCornerPrecision(_ detectedCorners: [CGPoint], targetCorners: [CGPoint]) -> Double {
        guard !detectedCorners.isEmpty && !targetCorners.isEmpty else { return 0.5 }
        
        var totalAccuracy = 0.0
        let minCount = min(detectedCorners.count, targetCorners.count)
        
        for i in 0..<minCount {
            let accuracy = 1.0 - min(distance(from: detectedCorners[i], to: targetCorners[i]) / 50.0, 1.0)
            totalAccuracy += accuracy
        }
        
        return totalAccuracy / Double(minCount)
    }
    
    // MARK: - Color Harmony Analysis
    private func analyzeColorHarmony(_ stroke: DrawingStroke, guide: DrawingGuide) -> ColorAnalysis {
        // For now, we'll provide basic color analysis
        // In production, this would analyze actual colors from the drawing
        
        let colorBalance = 0.7 // Placeholder
        let colorContrast = 0.6 // Placeholder
        let colorSaturation = 0.8 // Placeholder
        
        return ColorAnalysis(
            balance: colorBalance,
            contrast: colorContrast,
            saturation: colorSaturation,
            overallScore: (colorBalance + colorContrast + colorSaturation) / 3.0
        )
    }
    
    // MARK: - Creativity Analysis
    private func analyzeCreativity(_ stroke: DrawingStroke, guide: DrawingGuide, context: ArtisticContext) -> CreativityAnalysis {
        let originality = analyzeOriginality(stroke, guide: guide)
        let innovation = analyzeInnovation(stroke, guide: guide, context: context)
        let artisticVoice = analyzeArtisticVoice(stroke, context: context)
        
        return CreativityAnalysis(
            originality: originality,
            innovation: innovation,
            artisticVoice: artisticVoice,
            overallScore: (originality + innovation + artisticVoice) / 3.0
        )
    }
    
    private func analyzeOriginality(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze how original the approach is
        // This would compare against common patterns in the user's previous work
        
        // For now, provide a base score that encourages creativity
        let baseScore = 0.6
        
        // Add bonus for unique approaches
        let uniqueApproachBonus = analyzeUniqueApproach(stroke, guide: guide)
        
        return min(1.0, baseScore + uniqueApproachBonus)
    }
    
    private func analyzeUniqueApproach(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze if the user took a unique approach to the shape
        guard let primaryShape = guide.shapes.first else { return 0.0 }
        
        // Check for creative variations
        let creativeVariation = switch primaryShape.type {
        case .circle:
            analyzeCreativeCircleVariation(stroke, guide: guide)
        case .rectangle:
            analyzeCreativeRectangleVariation(stroke, guide: guide)
        case .line:
            analyzeCreativeLineVariation(stroke, guide: guide)
        default:
            0.1 // Base creativity score
        }
        
        return creativeVariation
    }
    
    private func analyzeCreativeCircleVariation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Check for creative approaches to drawing circles
        // e.g., starting from different points, using different techniques
        
        guard let primaryShape = guide.shapes.first else { return 0.0 }
        let center = primaryShape.center
        
        // Check if user started from an unusual point
        let startPoint = stroke.points.first!
        let expectedStartAngle = atan2(startPoint.y - center.y, startPoint.x - center.x)
        
        // Unusual starting angles get creativity bonus
        let angleFromExpected = abs(expectedStartAngle - 0) // Expected to start at 0 degrees
        let creativityBonus = min(0.3, angleFromExpected / .pi)
        
        return creativityBonus
    }
    
    private func analyzeCreativeRectangleVariation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Check for creative approaches to drawing rectangles
        // e.g., different corner orders, rounded corners
        
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        // Check for rounded corners (creative variation)
        let cornerRadius = analyzeCornerRadius(stroke)
        let creativityBonus = min(0.2, cornerRadius * 2.0)
        
        return creativityBonus
    }
    
    private func analyzeCreativeLineVariation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Check for creative approaches to drawing lines
        // e.g., curved lines, dashed lines, varying thickness
        
        let straightness = analyzeStraightness(stroke.points)
        let creativityBonus = max(0.0, 0.3 - straightness) // Less straight = more creative
        
        return creativityBonus
    }
    
    private func analyzeCornerRadius(_ stroke: DrawingStroke) -> Double {
        // Analyze if the stroke has rounded corners
        let corners = detectCorners(in: stroke.points)
        
        if corners.count < 2 {
            return 0.0
        }
        
        // Check the sharpness of detected corners
        var totalSharpness = 0.0
        for corner in corners {
            let sharpness = analyzeCornerSharpness(corner, in: stroke.points)
            totalSharpness += sharpness
        }
        
        let avgSharpness = totalSharpness / Double(corners.count)
        return max(0.0, 1.0 - avgSharpness) // Less sharp = more rounded
    }
    
    private func analyzeCornerSharpness(_ corner: CGPoint, in points: [CGPoint]) -> Double {
        // Find the index of the corner point
        guard let cornerIndex = points.firstIndex(where: { distance(from: $0, to: corner) < 5.0 }) else {
            return 0.5
        }
        
        guard cornerIndex > 0 && cornerIndex < points.count - 1 else {
            return 0.5
        }
        
        let prevPoint = points[cornerIndex - 1]
        let nextPoint = points[cornerIndex + 1]
        
        // Calculate the angle at the corner
        let angle1 = atan2(corner.y - prevPoint.y, corner.x - prevPoint.x)
        let angle2 = atan2(nextPoint.y - corner.y, nextPoint.x - corner.x)
        
        var angleDiff = abs(angle2 - angle1)
        if angleDiff > .pi {
            angleDiff = 2 * .pi - angleDiff
        }
        
        // Sharp corners have angles close to π (180 degrees)
        return max(0.0, 1.0 - abs(angleDiff - Double.pi) / Double.pi)
    }
    
    private func analyzeInnovation(_ stroke: DrawingStroke, guide: DrawingGuide, context: ArtisticContext) -> Double {
        // Analyze how innovative the approach is
        let techniqueInnovation = analyzeTechniqueInnovation(stroke, guide: guide)
        let styleInnovation = analyzeStyleInnovation(stroke, context: context)
        
        return (techniqueInnovation + styleInnovation) / 2.0
    }
    
    private func analyzeTechniqueInnovation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Analyze innovative techniques used
        let pressureInnovation = analyzePressureInnovation(stroke)
        let velocityInnovation = analyzeVelocityInnovation(stroke)
        
        return (pressureInnovation + velocityInnovation) / 2.0
    }
    
    private func analyzePressureInnovation(_ stroke: DrawingStroke) -> Double {
        guard !stroke.pressure.isEmpty else { return 0.5 }
        
        // Look for creative pressure variations
        let pressureRange = (stroke.pressure.max() ?? 1.0) - (stroke.pressure.min() ?? 0.0)
        let pressureVariation = stroke.pressure.map { Foundation.pow($0 - 0.5, 2) }.reduce(0, +) / Double(stroke.pressure.count)
        
        // Moderate variation indicates innovation
        let innovationScore = min(1.0, pressureRange * pressureVariation * 4.0)
        return innovationScore
    }
    
    private func analyzeVelocityInnovation(_ stroke: DrawingStroke) -> Double {
        guard stroke.velocity.count > 1 else { return 0.5 }
        
        // Look for creative velocity patterns
        let velocityRange = (stroke.velocity.max() ?? 1.0) - (stroke.velocity.min() ?? 0.0)
        let velocityVariation = stroke.velocity.map { Foundation.pow($0 - 0.5, 2) }.reduce(0, +) / Double(stroke.velocity.count)
        
        // Moderate variation indicates innovation
        let innovationScore = min(1.0, velocityRange * velocityVariation * 4.0)
        return innovationScore
    }
    
    private func analyzeStyleInnovation(_ stroke: DrawingStroke, context: ArtisticContext) -> Double {
        // Analyze style innovation based on user's previous work
        // For now, provide a base score
        return 0.6
    }
    
    private func analyzeArtisticVoice(_ stroke: DrawingStroke, context: ArtisticContext) -> Double {
        // Analyze the user's developing artistic voice
        let consistency = analyzeStyleConsistency(stroke, context: context)
        let expressiveness = analyzeExpressiveness(stroke)
        let confidence = analyzeArtisticConfidence(stroke)
        
        return (consistency + expressiveness + confidence) / 3.0
    }
    
    private func analyzeStyleConsistency(_ stroke: DrawingStroke, context: ArtisticContext) -> Double {
        // Analyze consistency with user's developing style
        // For now, provide a base score
        return 0.7
    }
    
    private func analyzeArtisticConfidence(_ stroke: DrawingStroke) -> Double {
        // Analyze artistic confidence in the stroke
        let strokeConfidence = analyzeStrokeConfidence(stroke)
        let decisionConfidence = analyzeDecisionConfidence(stroke)
        
        return (strokeConfidence + decisionConfidence) / 2.0
    }
    
    private func analyzeDecisionConfidence(_ stroke: DrawingStroke) -> Double {
        // Analyze confidence in artistic decisions
        // Look for hesitation marks, corrections, etc.
        
        guard stroke.points.count > 3 else { return 0.7 }
        
        var hesitationCount = 0
        for i in 1..<(stroke.points.count - 1) {
            let prevPoint = stroke.points[i - 1]
            let currentPoint = stroke.points[i]
            let nextPoint = stroke.points[i + 1]
            
            // Check for back-and-forth movements (hesitation)
            let dist1 = distance(from: prevPoint, to: currentPoint)
            let dist2 = distance(from: currentPoint, to: nextPoint)
            
            if dist1 < 2.0 && dist2 < 2.0 {
                hesitationCount += 1
            }
        }
        
        let hesitationRatio = Double(hesitationCount) / Double(stroke.points.count)
        return max(0.0, 1.0 - hesitationRatio * 2.0)
    }
    
    // MARK: - Result Combination
    private func combineArtisticAnalyses(
        composition: CompositionAnalysis,
        style: StyleAnalysis,
        color: ColorAnalysis,
        creativity: CreativityAnalysis,
        context: ArtisticContext
    ) -> ArtisticFeedback {
        
        // Calculate overall artistic score
        let overallScore = (
            composition.overallScore * 0.25 +
            style.overallScore * 0.25 +
            color.overallScore * 0.20 +
            creativity.overallScore * 0.30
        )
        
        // Generate artistic suggestions
        let suggestions = generateArtisticSuggestions(
            composition: composition,
            style: style,
            color: color,
            creativity: creativity,
            context: context
        )
        
        // Generate encouragement
        let encouragement = generateEncouragement(overallScore, context: context)
        
        return ArtisticFeedback(
            overallScore: overallScore,
            composition: composition,
            style: style,
            color: color,
            creativity: creativity,
            suggestions: suggestions,
            encouragement: encouragement,
            artisticInsights: generateArtisticInsights(composition: composition, style: style, creativity: creativity)
        )
    }
    
    private func generateArtisticSuggestions(
        composition: CompositionAnalysis,
        style: StyleAnalysis,
        color: ColorAnalysis,
        creativity: CreativityAnalysis,
        context: ArtisticContext
    ) -> [String] {
        var suggestions: [String] = []
        
        // Composition suggestions - User-friendly language
        if composition.balance < 0.6 {
            suggestions.append("✨ Try centering your drawing more - it'll look more balanced!")
        }
        if composition.proportion < 0.6 {
            suggestions.append("📏 Great start! Try matching the size of the guide a bit more closely")
        }
        if composition.rhythm < 0.6 {
            suggestions.append("🎵 Keep a steady pace as you draw - it'll make your lines flow better")
        }
        
        // Style suggestions - Encouraging language
        if style.lineQuality < 0.6 {
            suggestions.append("💪 You're doing great! Try drawing with more confidence - your strokes will be smoother")
        }
        if style.expressiveness < 0.6 {
            suggestions.append("🎨 Experiment with pressing harder and softer to add more personality to your drawing")
        }
        if style.technique < 0.6 {
            suggestions.append("🎯 Focus on the main technique for this shape - you've got this!")
        }
        
        // Creativity suggestions - Positive reinforcement
        if creativity.originality > 0.8 {
            suggestions.append("🌟 Amazing! Your creative style is really shining through - keep it up!")
        } else if creativity.originality < 0.4 {
            suggestions.append("💡 Don't be afraid to try something different - creativity comes from experimenting!")
        }
        
        // Limit suggestions to avoid overwhelming
        return Array(suggestions.prefix(Config.maxSuggestions))
    }
    
    private func generateEncouragement(_ score: Double, context: ArtisticContext) -> String {
        if score >= 0.9 {
            return "🌟 Wow! You're becoming an amazing artist - your skills are really shining!"
        } else if score >= 0.8 {
            return "✨ Fantastic! You're growing so much as an artist - keep up the amazing work!"
        } else if score >= 0.7 {
            return "👍 You're doing great! Every stroke is making you a better artist"
        } else if score >= 0.6 {
            return "💪 Nice work! Keep practicing and you'll see your skills improve even more"
        } else if score >= 0.5 {
            return "🎨 You're getting the hang of it! Every artist learns by practicing - you're doing great!"
        } else {
            return "🌟 Don't worry! Every amazing artist started right where you are - keep drawing and having fun!"
        }
    }
    
    private func generateArtisticInsights(
        composition: CompositionAnalysis,
        style: StyleAnalysis,
        creativity: CreativityAnalysis
    ) -> [String] {
        var insights: [String] = []
        
        // Composition insights - Encouraging language
        if composition.balance > 0.8 {
            insights.append("🎯 You have a great eye for balance - your drawings look so well-composed!")
        }
        if composition.rhythm > 0.8 {
            insights.append("🎵 You draw with such a natural flow - it's really beautiful to watch!")
        }
        
        // Style insights - Positive reinforcement
        if style.expressiveness > 0.8 {
            insights.append("🎨 Your artistic personality really shines through in your drawings!")
        }
        if style.lineQuality > 0.8 {
            insights.append("💪 Your confident strokes show you're really getting the hang of this!")
        }
        
        // Creativity insights - Celebrating uniqueness
        if creativity.originality > 0.8 {
            insights.append("🌟 You're developing your own unique style - that's what makes great artists!")
        }
        if creativity.innovation > 0.8 {
            insights.append("💡 Your creative approach is so fresh and inspiring!")
        }
        
        return insights
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
    
    // MARK: - Geometric Helper Methods
    private func calculateStrokeLength(_ points: [CGPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        
        var totalLength: Double = 0
        for i in 1..<points.count {
            let distance = distance(from: points[i-1], to: points[i])
            totalLength += distance
        }
        return totalLength
    }
    
    private func calculateGuideLength(_ guide: DrawingGuide) -> Double {
        guard !guide.targetPoints.isEmpty else { return 1.0 }
        
        var totalLength: Double = 0
        for i in 1..<guide.targetPoints.count {
            let distance = distance(from: guide.targetPoints[i-1], to: guide.targetPoints[i])
            totalLength += distance
        }
        return max(totalLength, 1.0)
    }
    
    private func calculateSegmentDistances(_ points: [CGPoint]) -> [Double] {
        guard points.count > 1 else { return [] }
        
        var distances: [Double] = []
        for i in 1..<points.count {
            let distance = distance(from: points[i-1], to: points[i])
            distances.append(distance)
        }
        return distances
    }
    
    private func analyzeVelocityConsistency(_ stroke: DrawingStroke) -> Double {
        guard stroke.velocity.count > 1 else { return 1.0 }
        
        let averageVelocity = stroke.velocity.reduce(0, +) / Double(stroke.velocity.count)
        let variance = stroke.velocity.map { pow($0 - averageVelocity, 2) }.reduce(0, +) / Double(stroke.velocity.count)
        let standardDeviation = sqrt(variance)
        
        return max(0.0, 1.0 - (standardDeviation / averageVelocity))
    }
    
    private func analyzePressureConsistency(_ stroke: DrawingStroke) -> Double {
        guard stroke.pressure.count > 1 else { return 1.0 }
        
        let averagePressure = stroke.pressure.reduce(0, +) / Double(stroke.pressure.count)
        let variance = stroke.pressure.map { pow($0 - averagePressure, 2) }.reduce(0, +) / Double(stroke.pressure.count)
        let standardDeviation = sqrt(variance)
        
        return max(0.0, 1.0 - (standardDeviation / averagePressure))
    }
    
    private func analyzeStrokeVariation(_ stroke: DrawingStroke) -> Double {
        // Analyze variation in stroke characteristics
        let pressureVariation = analyzePressureVariation(stroke)
        let velocityVariation = analyzeVelocityVariation(stroke)
        
        return (pressureVariation + velocityVariation) / 2.0
    }
    
    private func analyzePressureVariation(_ stroke: DrawingStroke) -> Double {
        guard stroke.pressure.count > 1 else { return 0.0 }
        
        let minPressure = stroke.pressure.min() ?? 0
        let maxPressure = stroke.pressure.max() ?? 0
        
        return maxPressure - minPressure
    }
    
    private func analyzeVelocityVariation(_ stroke: DrawingStroke) -> Double {
        guard stroke.velocity.count > 1 else { return 0.0 }
        
        let minVelocity = stroke.velocity.min() ?? 0
        let maxVelocity = stroke.velocity.max() ?? 0
        
        return maxVelocity - minVelocity
    }
    
    private func analyzeCreativeDeviation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Calculate how much the stroke deviates creatively from the guide
        let strokeCenter = calculateCenterPoint(of: stroke.points)
        let guideCenter = calculateCenterPoint(of: guide.targetPoints)
        
        let centerDeviation = distance(from: strokeCenter, to: guideCenter)
        let maxDeviation = max(guide.targetPoints.map { distance(from: $0, to: guideCenter) }.max() ?? 1.0, 1.0)
        
        return min(centerDeviation / maxDeviation, 1.0)
    }
    
    private func calculateGeometricDeviation(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Calculate geometric deviation from guide
        let strokeBounds = calculateBoundingRect(for: stroke.points)
        let guideBounds = calculateBoundingRect(for: guide.targetPoints)
        
        let centerDeviation = distance(from: strokeBounds.center, to: guideBounds.center)
        let sizeDeviation = abs(strokeBounds.width - guideBounds.width) + abs(strokeBounds.height - guideBounds.height)
        
        return (centerDeviation + sizeDeviation) / 100.0 // Normalize
    }
    
    private func analyzePatternComplexity(_ stroke: DrawingStroke) -> Double {
        // Analyze complexity of stroke patterns
        let cornerCount = detectCornerCount(stroke.points)
        let curveComplexity = analyzeCurveComplexity(stroke.points)
        
        return (Double(cornerCount) / 10.0 + curveComplexity) / 2.0
    }
    
    private func detectCornerCount(_ points: [CGPoint]) -> Int {
        guard points.count > 3 else { return 0 }
        
        var cornerCount = 0
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
                cornerCount += 1
            }
        }
        
        return cornerCount
    }
    
    private func analyzeCurveComplexity(_ points: [CGPoint]) -> Double {
        guard points.count > 2 else { return 0.0 }
        
        var totalCurvature: Double = 0
        var validSamples = 0
        
        for i in 1..<(points.count - 1) {
            let p1 = points[i-1]
            let p2 = points[i]
            let p3 = points[i+1]
            
            let curvature = calculatePointCurvature(p1, p2, p3)
            if !curvature.isNaN && !curvature.isInfinite {
                totalCurvature += abs(curvature)
                validSamples += 1
            }
        }
        
        return validSamples > 0 ? totalCurvature / Double(validSamples) : 0.0
    }
    
    private func calculatePointCurvature(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> Double {
        let a = distance(from: p1, to: p2)
        let b = distance(from: p2, to: p3)
        let c = distance(from: p1, to: p3)
        
        guard a > 0 && b > 0 && c > 0 else { return 0 }
        
        let area = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
        return 4 * area / (a * b * c)
    }
    
    private func calculateBaseRisk(_ stroke: DrawingStroke, guide: DrawingGuide) -> Double {
        // Calculate base artistic risk
        let deviation = calculateGeometricDeviation(stroke, guide: guide)
        let complexity = analyzePatternComplexity(stroke)
        
        return (deviation + complexity) / 2.0
    }
    
    private func getUserLevelMultiplier(_ userLevel: UserLevel) -> Double {
        switch userLevel {
        case .beginner:
            return 0.5
        case .intermediate:
            return 0.7
        case .advanced:
            return 1.0
        case .expert:
            return 1.2
        }
    }
    
    // MARK: - Performance Metrics
    func getPerformanceMetrics() -> ArtisticAnalysisMetrics {
        return analysisMetrics
    }
    
    // MARK: - Timeout Error for Memory Management
    enum AnalysisTimeoutError: Error, LocalizedError {
        case timeoutExceeded
        
        var errorDescription: String? {
            switch self {
            case .timeoutExceeded:
                return "Artistic analysis timeout exceeded"
            }
        }
    }
}

// MARK: - Supporting Data Structures
// Note: ArtisticFeedback, ArtisticContext, and related types are now defined in DataModels.swift

class ArtisticAnalysisMetrics {
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
