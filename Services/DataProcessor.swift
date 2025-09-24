import Foundation
import CoreML
import Vision
import Accelerate
import UIKit

/// Service for processing and preparing drawing data for training
class DataProcessor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var processingProgress: Double = 0.0
    @Published var processingStatus: ProcessingStatus = .idle
    @Published var totalProcessedData: Int = 0
    
    // MARK: - Private Properties
    private let encryptionService: DataEncryptionService
    private let qualityValidator: DataQualityValidator
    private let augmentationEngine: DataAugmentationEngine
    
    // MARK: - Processing Configuration
    private let imageSize: CGSize = CGSize(width: 224, height: 224)
    private let augmentationMultiplier: Int = 5 // Generate 5 augmented versions per stroke
    private let qualityThreshold: Double = 0.7
    private let maxStrokeLength: Int = 1000
    
    init() {
        self.encryptionService = DataEncryptionService()
        self.qualityValidator = DataQualityValidator()
        self.augmentationEngine = DataAugmentationEngine()
    }
    
    // MARK: - Main Processing Methods
    
    /// Process raw drawing data for machine learning training
    func processDrawingData(_ rawData: Data) async throws -> ProcessedDrawingData {
        await MainActor.run {
            processingStatus = .processing
        }
        
        do {
            // Decrypt and deserialize the data
            let drawingData = try encryptionService.decrypt(rawData, as: AnonymizedDrawingData.self)
            
            // Validate data quality
            guard try await qualityValidator.validateStroke(drawingData.stroke) else {
                throw ProcessingError.qualityCheckFailed
            }
            
            // Normalize stroke data
            let normalizedStroke = try await normalizeStroke(drawingData.stroke)
            
            // Convert to training format
            let processedStroke = try await convertToProcessedStroke(normalizedStroke)
            
            // Generate label for supervised learning
            let label = try await generateLabel(for: processedStroke)
            
            // Create metadata
            let metadata = createProcessingMetadata(originalStroke: drawingData.stroke)
            
            await MainActor.run {
                processingStatus = .completed
                totalProcessedData += 1
            }
            
            return ProcessedDrawingData(
                stroke: processedStroke,
                label: label,
                metadata: metadata
            )
            
        } catch {
            await MainActor.run {
                processingStatus = .failed
            }
            throw error
        }
    }
    
    /// Process multiple data points in batch
    func processBatch(_ dataRecords: [DataCollectionRecord]) async throws -> [ProcessedDrawingData] {
        await MainActor.run {
            processingStatus = .batchProcessing
            processingProgress = 0.0
        }
        
        var processedData: [ProcessedDrawingData] = []
        
        for (index, record) in dataRecords.enumerated() {
            do {
                let processed = try await processDrawingData(record.encryptedData)
                processedData.append(processed)
                
                // Generate augmented versions
                let augmentedData = try await generateAugmentedData(from: processed)
                processedData.append(contentsOf: augmentedData)
                
                // Update progress
                let progress = Double(index + 1) / Double(dataRecords.count)
                await MainActor.run {
                    processingProgress = progress
                }
                
            } catch {
                print("Error processing data record \(record.id): \(error)")
                continue
            }
        }
        
        await MainActor.run {
            processingStatus = .completed
        }
        
        return processedData
    }
    
    // MARK: - Data Normalization
    
    /// Normalize stroke data for consistent training
    private func normalizeStroke(_ stroke: AnonymizedStroke) async throws -> NormalizedStroke {
        // Normalize coordinates to [0, 1] range
        let points = stroke.points
        guard !points.isEmpty else {
            throw ProcessingError.emptyStroke
        }
        
        // Calculate bounding box
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        let width = maxX - minX
        let height = maxY - minY
        
        // Avoid division by zero
        let normalizedWidth = width > 0 ? width : 1.0
        let normalizedHeight = height > 0 ? height : 1.0
        
        // Normalize points
        let normalizedPoints = points.map { point in
            NormalizedPoint(
                x: (point.x - minX) / normalizedWidth,
                y: (point.y - minY) / normalizedHeight,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        // Resample to consistent point count
        let resampledPoints = try await resamplePoints(normalizedPoints, targetCount: 100)
        
        return NormalizedStroke(
            points: resampledPoints,
            duration: stroke.duration,
            originalBoundingBox: CGRect(x: minX, y: minY, width: width, height: height),
            context: stroke.context,
            timestamp: stroke.timestamp
        )
    }
    
    /// Resample points to consistent count for training
    private func resamplePoints(_ points: [NormalizedPoint], targetCount: Int) async throws -> [NormalizedPoint] {
        guard points.count > 1 else { return points }
        
        if points.count == targetCount {
            return points
        }
        
        // Calculate cumulative distances
        var cumulativeDistances: [Double] = [0]
        var totalDistance: Double = 0
        
        for i in 1..<points.count {
            let distance = calculateDistance(from: points[i-1], to: points[i])
            totalDistance += distance
            cumulativeDistances.append(totalDistance)
        }
        
        // Resample at regular intervals
        var resampledPoints: [NormalizedPoint] = []
        let interval = totalDistance / Double(targetCount - 1)
        
        for i in 0..<targetCount {
            let targetDistance = Double(i) * interval
            
            // Find the appropriate segment
            var segmentIndex = 0
            for j in 1..<cumulativeDistances.count {
                if cumulativeDistances[j] >= targetDistance {
                    segmentIndex = j - 1
                    break
                }
            }
            
            if segmentIndex >= points.count - 1 {
                resampledPoints.append(points.last!)
                continue
            }
            
            // Interpolate between points
            let startPoint = points[segmentIndex]
            let endPoint = points[segmentIndex + 1]
            let segmentStart = cumulativeDistances[segmentIndex]
            let segmentEnd = cumulativeDistances[segmentIndex + 1]
            let segmentLength = segmentEnd - segmentStart
            
            let t = segmentLength > 0 ? (targetDistance - segmentStart) / segmentLength : 0
            
            let interpolatedPoint = NormalizedPoint(
                x: startPoint.x + t * (endPoint.x - startPoint.x),
                y: startPoint.y + t * (endPoint.y - startPoint.y),
                timestamp: startPoint.timestamp + t * (endPoint.timestamp - startPoint.timestamp),
                pressure: startPoint.pressure + t * (endPoint.pressure - startPoint.pressure)
            )
            
            resampledPoints.append(interpolatedPoint)
        }
        
        return resampledPoints
    }
    
    private func calculateDistance(from point1: NormalizedPoint, to point2: NormalizedPoint) -> Double {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    // MARK: - Format Conversion
    
    /// Convert normalized stroke to processed format for training
    private func convertToProcessedStroke(_ stroke: NormalizedStroke) async throws -> ProcessedStroke {
        let processedPoints = stroke.points.map { point in
            ProcessedPoint(
                x: point.x,
                y: point.y,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: processedPoints,
            duration: stroke.duration,
            boundingBox: stroke.originalBoundingBox
        )
    }
    
    // MARK: - Label Generation
    
    /// Generate appropriate labels for supervised learning
    private func generateLabel(for stroke: ProcessedStroke) async throws -> String {
        // Analyze stroke characteristics to determine shape type
        let shapeClassifier = ShapeClassifier()
        let shape = try await shapeClassifier.classifyShape(stroke)
        
        return shape.rawValue
    }
    
    // MARK: - Data Augmentation
    
    /// Generate augmented versions of training data
    private func generateAugmentedData(from original: ProcessedDrawingData) async throws -> [ProcessedDrawingData] {
        var augmentedData: [ProcessedDrawingData] = []
        
        for i in 0..<augmentationMultiplier {
            let augmented = try await augmentationEngine.augmentStroke(
                original.stroke,
                augmentationType: AugmentationType.allCases[i % AugmentationType.allCases.count]
            )
            
            let augmentedDrawingData = ProcessedDrawingData(
                stroke: augmented,
                label: original.label,
                metadata: original.metadata.merging([
                    "augmentation_type": AugmentationType.allCases[i % AugmentationType.allCases.count].rawValue,
                    "augmentation_index": i
                ]) { _, new in new }
            )
            
            augmentedData.append(augmentedDrawingData)
        }
        
        return augmentedData
    }
    
    // MARK: - Metadata Creation
    
    private func createProcessingMetadata(originalStroke: AnonymizedStroke) -> [String: Any] {
        return [
            "processing_timestamp": Date(),
            "processing_version": "1.0",
            "original_point_count": originalStroke.points.count,
            "normalized_point_count": 100,
            "processing_algorithm": "dtw_normalization",
            "quality_score": qualityValidator.calculateQualityScore(originalStroke)
        ]
    }
}

// MARK: - Data Quality Validator

class DataQualityValidator {
    
    func validateStroke(_ stroke: AnonymizedStroke) async throws -> Bool {
        // Check minimum requirements
        guard stroke.points.count >= 10 else { return false }
        guard stroke.duration > 0.1 else { return false }
        
        // Check for reasonable variation
        let pressureVariance = calculatePressureVariance(stroke.points)
        guard pressureVariance > 0.05 else { return false }
        
        // Check for stroke complexity
        let complexity = calculateComplexity(stroke.points)
        guard complexity > 0.2 else { return false }
        
        return true
    }
    
    func calculateQualityScore(_ stroke: AnonymizedStroke) -> Double {
        var score: Double = 0.0
        
        // Point count score (0.3 weight)
        let pointScore = min(Double(stroke.points.count) / 100.0, 1.0)
        score += pointScore * 0.3
        
        // Duration score (0.2 weight)
        let durationScore = min(stroke.duration / 5.0, 1.0)
        score += durationScore * 0.2
        
        // Pressure variance score (0.3 weight)
        let pressureScore = min(calculatePressureVariance(stroke.points) * 5.0, 1.0)
        score += pressureScore * 0.3
        
        // Complexity score (0.2 weight)
        let complexityScore = min(calculateComplexity(stroke.points) * 2.0, 1.0)
        score += complexityScore * 0.2
        
        return score
    }
    
    private func calculatePressureVariance(_ points: [AnonymizedPoint]) -> Double {
        let pressures = points.map { $0.pressure }
        let mean = pressures.reduce(0, +) / Double(pressures.count)
        let variance = pressures.map { pow($0 - mean, 2) }.reduce(0, +) / Double(pressures.count)
        return sqrt(variance)
    }
    
    private func calculateComplexity(_ points: [AnonymizedPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        
        var totalAngleChange: Double = 0
        for i in 1..<points.count - 1 {
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = points[i + 1]
            
            let angle1 = atan2(p2.y - p1.y, p2.x - p1.x)
            let angle2 = atan2(p3.y - p2.y, p3.x - p2.x)
            
            let angleChange = abs(angle2 - angle1)
            totalAngleChange += min(angleChange, 2 * .pi - angleChange)
        }
        
        return totalAngleChange / Double(points.count - 2)
    }
}

// MARK: - Data Augmentation Engine

class DataAugmentationEngine {
    
    func augmentStroke(_ stroke: ProcessedStroke, augmentationType: AugmentationType) async throws -> ProcessedStroke {
        switch augmentationType {
        case .rotation:
            return try await rotateStroke(stroke, angle: Double.random(in: -0.3...0.3))
        case .scaling:
            return try await scaleStroke(stroke, factor: Double.random(in: 0.8...1.2))
        case .translation:
            return try await translateStroke(stroke, dx: Double.random(in: -0.1...0.1), dy: Double.random(in: -0.1...0.1))
        case .noise:
            return try await addNoise(stroke, intensity: Double.random(in: 0.01...0.05))
        case .timeWarping:
            return try await warpTime(stroke, factor: Double.random(in: 0.8...1.2))
        }
    }
    
    private func rotateStroke(_ stroke: ProcessedStroke, angle: Double) async throws -> ProcessedStroke {
        let rotatedPoints = stroke.points.map { point in
            let x = point.x * cos(angle) - point.y * sin(angle)
            let y = point.x * sin(angle) + point.y * cos(angle)
            
            return ProcessedPoint(
                x: x,
                y: y,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: rotatedPoints,
            duration: stroke.duration,
            boundingBox: stroke.boundingBox
        )
    }
    
    private func scaleStroke(_ stroke: ProcessedStroke, factor: Double) async throws -> ProcessedStroke {
        let scaledPoints = stroke.points.map { point in
            ProcessedPoint(
                x: point.x * factor,
                y: point.y * factor,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: scaledPoints,
            duration: stroke.duration,
            boundingBox: stroke.boundingBox
        )
    }
    
    private func translateStroke(_ stroke: ProcessedStroke, dx: Double, dy: Double) async throws -> ProcessedStroke {
        let translatedPoints = stroke.points.map { point in
            ProcessedPoint(
                x: point.x + dx,
                y: point.y + dy,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: translatedPoints,
            duration: stroke.duration,
            boundingBox: stroke.boundingBox
        )
    }
    
    private func addNoise(_ stroke: ProcessedStroke, intensity: Double) async throws -> ProcessedStroke {
        let noisyPoints = stroke.points.map { point in
            let noiseX = Double.random(in: -intensity...intensity)
            let noiseY = Double.random(in: -intensity...intensity)
            
            return ProcessedPoint(
                x: point.x + noiseX,
                y: point.y + noiseY,
                timestamp: point.timestamp,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: noisyPoints,
            duration: stroke.duration,
            boundingBox: stroke.boundingBox
        )
    }
    
    private func warpTime(_ stroke: ProcessedStroke, factor: Double) async throws -> ProcessedStroke {
        let warpedPoints = stroke.points.map { point in
            ProcessedPoint(
                x: point.x,
                y: point.y,
                timestamp: point.timestamp * factor,
                pressure: point.pressure
            )
        }
        
        return ProcessedStroke(
            points: warpedPoints,
            duration: stroke.duration * factor,
            boundingBox: stroke.boundingBox
        )
    }
}

// MARK: - Shape Classifier

class ShapeClassifier {
    
    func classifyShape(_ stroke: ProcessedStroke) async throws -> ShapeType {
        // Analyze geometric properties to determine shape type
        let analyzer = GeometricShapeAnalyzer()
        
        // Calculate features
        let circularity = analyzer.calculateCircularity(stroke.points)
        let rectangularity = analyzer.calculateRectangularity(stroke.points)
        let linearity = analyzer.calculateLinearity(stroke.points)
        
        // Simple heuristic classification (would be ML-based in production)
        if circularity > 0.7 {
            return .circle
        } else if rectangularity > 0.7 {
            return .rectangle
        } else if linearity > 0.8 {
            return .line
        } else {
            return .curve
        }
    }
}

// MARK: - Geometric Shape Analyzer

class GeometricShapeAnalyzer {
    
    func calculateCircularity(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 3 else { return 0 }
        
        // Calculate center
        let centerX = points.map { $0.x }.reduce(0, +) / Double(points.count)
        let centerY = points.map { $0.y }.reduce(0, +) / Double(points.count)
        
        // Calculate distances from center
        let distances = points.map { point in
            sqrt(pow(point.x - centerX, 2) + pow(point.y - centerY, 2))
        }
        
        // Calculate variance of distances
        let meanDistance = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - meanDistance, 2) }.reduce(0, +) / Double(distances.count)
        
        // Lower variance = more circular
        return max(0, 1.0 - sqrt(variance) / meanDistance)
    }
    
    func calculateRectangularity(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 4 else { return 0 }
        
        // Find bounding box
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        // Check how many points are near the edges
        let tolerance = 0.05
        var edgePoints = 0
        
        for point in points {
            if abs(point.x - minX) < tolerance || abs(point.x - maxX) < tolerance ||
               abs(point.y - minY) < tolerance || abs(point.y - maxY) < tolerance {
                edgePoints += 1
            }
        }
        
        return Double(edgePoints) / Double(points.count)
    }
    
    func calculateLinearity(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        // Calculate line equation
        let lineLength = sqrt(pow(lastPoint.x - firstPoint.x, 2) + pow(lastPoint.y - firstPoint.y, 2))
        
        if lineLength == 0 { return 0 }
        
        // Calculate deviation from line
        var totalDeviation: Double = 0
        
        for point in points {
            let deviation = distanceFromPointToLine(
                point: CGPoint(x: point.x, y: point.y),
                lineStart: CGPoint(x: firstPoint.x, y: firstPoint.y),
                lineEnd: CGPoint(x: lastPoint.x, y: lastPoint.y)
            )
            totalDeviation += deviation
        }
        
        let averageDeviation = totalDeviation / Double(points.count)
        
        // Lower deviation = more linear
        return max(0, 1.0 - averageDeviation / (lineLength * 0.1))
    }
    
    private func distanceFromPointToLine(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Double {
        let A = Double(lineEnd.y - lineStart.y)
        let B = Double(lineStart.x - lineEnd.x)
        let C = Double(lineEnd.x * lineStart.y - lineStart.x * lineEnd.y)
        
        let numerator = abs(A * Double(point.x) + B * Double(point.y) + C)
        let denominator = sqrt(A * A + B * B)
        
        return denominator > 0 ? numerator / denominator : 0.0
    }
}

// MARK: - Supporting Types

enum ProcessingStatus {
    case idle
    case processing
    case batchProcessing
    case completed
    case failed
}

enum ProcessingError: Error {
    case qualityCheckFailed
    case emptyStroke
    case normalizationFailed
    case augmentationFailed
    case labelGenerationFailed
}

enum AugmentationType: String, CaseIterable {
    case rotation = "rotation"
    case scaling = "scaling"
    case translation = "translation"
    case noise = "noise"
    case timeWarping = "time_warping"
}

enum ShapeType: String, CaseIterable {
    case circle = "circle"
    case rectangle = "rectangle"
    case line = "line"
    case oval = "oval"
    case curve = "curve"
    case polygon = "polygon"
}

struct NormalizedStroke {
    let points: [NormalizedPoint]
    let duration: TimeInterval
    let originalBoundingBox: CGRect
    let context: String
    let timestamp: Date
}

struct NormalizedPoint {
    let x: Double
    let y: Double
    let timestamp: TimeInterval
    let pressure: Double
}
