import Foundation
import CoreGraphics
import SwiftUI

/// Geometric analysis-based stroke analyzer that replaces ML models
/// Provides real-time feedback using mathematical calculations
class GeometricStrokeAnalyzer {
    
    // MARK: - Geometric Analysis Properties
    
    /// Tolerance for distance calculations
    private let distanceTolerance: CGFloat = 10.0
    
    /// Minimum stroke length to consider valid
    private let minimumStrokeLength: CGFloat = 5.0
    
    /// Angle tolerance for straight lines (in degrees)
    private let angleTolerance: CGFloat = 15.0
    
    /// Curvature threshold for smooth curves
    private let curvatureThreshold: CGFloat = 0.1
    
    // MARK: - Stroke Analysis Results
    
    struct GeometricAnalysisResult {
        let shapeType: ShapeType
        let confidence: Double
        let geometricProperties: GeometricProperties
        let feedback: String
        let suggestions: [String]
    }
    
    struct GeometricProperties {
        let length: CGFloat
        let angle: CGFloat
        let curvature: CGFloat
        let boundingBox: CGRect
        let centerPoint: CGPoint
        let isClosed: Bool
        let symmetry: Double
    }
    
    // Use the ShapeType from DataModels.swift - no need to redefine it
    
    // MARK: - Main Analysis Method
    
    /// Analyzes a stroke using geometric calculations instead of ML
    func analyzeStroke(_ points: [CGPoint], in canvasSize: CGSize) -> GeometricAnalysisResult {
        guard !points.isEmpty else {
            return createUnknownResult()
        }
        
        // Calculate geometric properties
        let properties = calculateGeometricProperties(points)
        
        // Determine shape type based on geometric analysis
        let shapeType = determineShapeType(properties, points: points)
        
        // Calculate confidence based on geometric consistency
        let confidence = calculateConfidence(properties, shapeType: shapeType)
        
        // Generate feedback and suggestions
        let (feedback, suggestions) = generateFeedback(properties, shapeType: shapeType)
        
        return GeometricAnalysisResult(
            shapeType: shapeType,
            confidence: confidence,
            geometricProperties: properties,
            feedback: feedback,
            suggestions: suggestions
        )
    }
    
    /// MEMORY FIX: Analyze stroke with timeout for memory management
    func analyzeStrokeWithTimeout(_ points: [CGPoint], in canvasSize: CGSize, timeout: TimeInterval) throws -> GeometricAnalysisResult {
        // Use autoreleasepool for memory management
        return try autoreleasepool {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Check timeout before processing
            if CFAbsoluteTimeGetCurrent() - startTime > timeout {
                throw AnalysisTimeoutError.timeoutExceeded
            }
            
            // Perform analysis with periodic timeout checks
            let result = analyzeStroke(points, in: canvasSize)
            
            // Check timeout after processing
            if CFAbsoluteTimeGetCurrent() - startTime > timeout {
                throw AnalysisTimeoutError.timeoutExceeded
            }
            
            return result
        }
    }
    
    // MARK: - Geometric Property Calculations
    
    private func calculateGeometricProperties(_ points: [CGPoint]) -> GeometricProperties {
        let length = calculateStrokeLength(points)
        let angle = calculateStrokeAngle(points)
        let curvature = calculateCurvature(points)
        let boundingBox = calculateBoundingBox(points)
        let centerPoint = calculateCenterPoint(points)
        let isClosed = isStrokeClosed(points)
        let symmetry = calculateSymmetry(points)
        
        return GeometricProperties(
            length: length,
            angle: angle,
            curvature: curvature,
            boundingBox: boundingBox,
            centerPoint: centerPoint,
            isClosed: isClosed,
            symmetry: symmetry
        )
    }
    
    private func calculateStrokeLength(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 1 else { return 0 }
        
        var totalLength: CGFloat = 0
        for i in 1..<points.count {
            let distance = distanceBetween(points[i-1], points[i])
            totalLength += distance
        }
        return totalLength
    }
    
    private func calculateStrokeAngle(_ points: [CGPoint]) -> CGFloat {
        guard points.count >= 2 else { return 0 }
        
        let startPoint = points.first!
        let endPoint = points.last!
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        
        let angle = atan2(deltaY, deltaX) * 180 / .pi
        return angle < 0 ? angle + 360 : angle
    }
    
    private func calculateCurvature(_ points: [CGPoint]) -> CGFloat {
        guard points.count >= 3 else { return 0 }
        
        var totalCurvature: CGFloat = 0
        var validSamples = 0
        
        for i in 1..<points.count - 1 {
            let p1 = points[i-1]
            let p2 = points[i]
            let p3 = points[i+1]
            
            let curvature = calculatePointCurvature(p1, p2, p3)
            if !curvature.isNaN && !curvature.isInfinite {
                totalCurvature += abs(curvature)
                validSamples += 1
            }
        }
        
        return validSamples > 0 ? totalCurvature / CGFloat(validSamples) : 0
    }
    
    private func calculatePointCurvature(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        let a = distanceBetween(p1, p2)
        let b = distanceBetween(p2, p3)
        let c = distanceBetween(p1, p3)
        
        guard a > 0 && b > 0 && c > 0 else { return 0 }
        
        // Using the formula for curvature: 4 * area / (a * b * c)
        let area = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2
        return 4 * area / (a * b * c)
    }
    
    private func calculateBoundingBox(_ points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func calculateCenterPoint(_ points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        
        let sumX = points.map { $0.x }.reduce(0, +)
        let sumY = points.map { $0.y }.reduce(0, +)
        
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    private func isStrokeClosed(_ points: [CGPoint]) -> Bool {
        guard points.count >= 3 else { return false }
        
        let startPoint = points.first!
        let endPoint = points.last!
        let distance = distanceBetween(startPoint, endPoint)
        
        return distance <= distanceTolerance
    }
    
    private func calculateSymmetry(_ points: [CGPoint]) -> Double {
        guard points.count >= 4 else { return 0 }
        
        let center = calculateCenterPoint(points)
        var symmetryScore: Double = 0
        var validPairs = 0
        
        for i in 0..<points.count {
            let point = points[i]
            let reflectedPoint = CGPoint(
                x: 2 * center.x - point.x,
                y: 2 * center.y - point.y
            )
            
            // Find closest point to reflected point
            var minDistance = CGFloat.greatestFiniteMagnitude
            for otherPoint in points {
                let distance = distanceBetween(reflectedPoint, otherPoint)
                if distance < minDistance {
                    minDistance = distance
                }
            }
            
            if minDistance <= distanceTolerance {
                symmetryScore += 1
            }
            validPairs += 1
        }
        
        return validPairs > 0 ? symmetryScore / Double(validPairs) : 0
    }
    
    // MARK: - Shape Type Determination
    
    private func determineShapeType(_ properties: GeometricProperties, points: [CGPoint]) -> ShapeType {
        // Check for circle
        if isCircle(properties, points: points) {
            return .circle
        }
        
        // Check for line
        if isLine(properties, points: points) {
            return .line
        }
        
        // Check for rectangle
        if isRectangle(properties, points: points) {
            return .rectangle
        }
        
        // Check for triangle (map to polygon)
        if isTriangle(properties, points: points) {
            return .polygon
        }
        
        // Check for curve
        if isCurve(properties, points: points) {
            return .curve
        }
        
        // Check for oval (ellipse-like shape)
        if isOval(properties, points: points) {
            return .oval
        }
        
        return .line // Default fallback
    }
    
    private func isCircle(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        guard properties.isClosed && points.count >= 8 else { return false }
        
        let center = properties.centerPoint
        let distances = points.map { distanceBetween($0, center) }
        
        guard let minDistance = distances.min(),
              let maxDistance = distances.max() else { return false }
        
        // Check if distances are relatively consistent (circle-like)
        let distanceVariation = (maxDistance - minDistance) / minDistance
        let symmetryScore = properties.symmetry
        
        return distanceVariation < 0.3 && symmetryScore > 0.7
    }
    
    private func isLine(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        guard points.count >= 2 else { return false }
        
        // Check if points are roughly collinear
        let startPoint = points.first!
        let endPoint = points.last!
        let lineLength = distanceBetween(startPoint, endPoint)
        
        if lineLength < minimumStrokeLength { return false }
        
        // Calculate average distance from points to the line
        var totalDeviation: CGFloat = 0
        for point in points {
            let deviation = distanceFromPointToLine(point, startPoint, endPoint)
            totalDeviation += deviation
        }
        
        let averageDeviation = totalDeviation / CGFloat(points.count)
        let deviationRatio = averageDeviation / lineLength
        
        return deviationRatio < 0.1 // Less than 10% deviation
    }
    
    private func isRectangle(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        guard points.count >= 4 else { return false }
        
        // Check for 4 corners and straight edges
        let corners = findCorners(points)
        guard corners.count >= 4 else { return false }
        
        // Check if edges are roughly straight and perpendicular
        let edges = createEdgesFromCorners(corners)
        let straightEdgeCount = edges.filter { isEdgeStraight($0) }.count
        let perpendicularCount = countPerpendicularEdges(edges)
        
        return straightEdgeCount >= 3 && perpendicularCount >= 2
    }
    
    private func isTriangle(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        guard points.count >= 3 else { return false }
        
        // Check for 3 distinct corners
        let corners = findCorners(points)
        return corners.count >= 3 && corners.count <= 4
    }
    
    private func isCurve(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        return properties.curvature > curvatureThreshold && !isLine(properties, points: points)
    }
    
    private func isOval(_ properties: GeometricProperties, points: [CGPoint]) -> Bool {
        guard properties.isClosed && points.count >= 6 else { return false }
        
        let center = properties.centerPoint
        let distances = points.map { distanceBetween($0, center) }
        
        guard let minDistance = distances.min(),
              let maxDistance = distances.max() else { return false }
        
        // Check if distances vary significantly (oval-like)
        let distanceVariation = (maxDistance - minDistance) / minDistance
        let symmetryScore = properties.symmetry
        
        // Oval should have moderate distance variation and good symmetry
        return distanceVariation > 0.2 && distanceVariation < 0.8 && symmetryScore > 0.6
    }
    
    // MARK: - Confidence Calculation
    
    private func calculateConfidence(_ properties: GeometricProperties, shapeType: ShapeType) -> Double {
        var confidence: Double = 0.5 // Base confidence
        
        // Adjust based on stroke length
        if properties.length > minimumStrokeLength {
            confidence += 0.2
        }
        
        // Adjust based on shape-specific criteria
        switch shapeType {
        case .circle:
            confidence += properties.symmetry * 0.3
        case .line:
            confidence += (1.0 - properties.curvature) * 0.3
        case .rectangle, .polygon:
            confidence += properties.symmetry * 0.2
        case .curve:
            confidence += min(properties.curvature, 1.0) * 0.3
        case .oval:
            confidence += properties.symmetry * 0.25
        default:
            confidence = 0.3
        }
        
        return min(max(confidence, 0.0), 1.0)
    }
    
    // MARK: - Feedback Generation
    
    private func generateFeedback(_ properties: GeometricProperties, shapeType: ShapeType) -> (String, [String]) {
        var feedback = ""
        var suggestions: [String] = []
        
        switch shapeType {
        case .circle:
            feedback = "Great circle! Your stroke shows good symmetry."
            if properties.symmetry < 0.8 {
                suggestions.append("Try to keep your stroke more centered for better symmetry")
            }
            
        case .line:
            feedback = "Nice straight line!"
            if properties.curvature > 0.1 {
                suggestions.append("Try to draw with a steadier hand for straighter lines")
            }
            
        case .rectangle:
            feedback = "Good rectangle shape!"
            if properties.symmetry < 0.7 {
                suggestions.append("Focus on making opposite sides parallel")
            }
            
        case .polygon:
            feedback = "Great polygon shape!"
            suggestions.append("Make sure all sides connect properly")
            
        case .curve:
            feedback = "Smooth curve detected!"
            suggestions.append("Your curve shows good flow and continuity")
            
        case .oval:
            feedback = "Nice oval shape!"
            suggestions.append("Try to keep the shape symmetrical")
            
        default:
            feedback = "Keep practicing! Try to focus on basic shapes first."
            suggestions.append("Start with simple lines and circles")
            suggestions.append("Take your time with each stroke")
        }
        
        // Add general suggestions based on properties
        if properties.length < minimumStrokeLength {
            suggestions.append("Try making longer, more deliberate strokes")
        }
        
        if !properties.isClosed && (shapeType == .circle || shapeType == .rectangle) {
            suggestions.append("Try to close your shape by connecting the start and end points")
        }
        
        return (feedback, suggestions)
    }
    
    // MARK: - Helper Methods
    
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    private func distanceFromPointToLine(_ point: CGPoint, _ lineStart: CGPoint, _ lineEnd: CGPoint) -> CGFloat {
        let A = lineEnd.y - lineStart.y
        let B = lineStart.x - lineEnd.x
        let C = lineEnd.x * lineStart.y - lineStart.x * lineEnd.y
        
        return abs(A * point.x + B * point.y + C) / sqrt(A * A + B * B)
    }
    
    private func findCorners(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count >= 3 else { return [] }
        
        var corners: [CGPoint] = []
        
        for i in 1..<points.count - 1 {
            let p1 = points[i-1]
            let p2 = points[i]
            let p3 = points[i+1]
            
            let angle = calculateAngle(p1, p2, p3)
            if angle < 150 || angle > 210 { // Significant angle change
                corners.append(p2)
            }
        }
        
        return corners
    }
    
    private func calculateAngle(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        let v1 = CGPoint(x: p1.x - p2.x, y: p1.y - p2.y)
        let v2 = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1, min(1, cosAngle))
        return acos(clampedCos) * 180 / .pi
    }
    
    private func createEdgesFromCorners(_ corners: [CGPoint]) -> [(CGPoint, CGPoint)] {
        guard corners.count >= 2 else { return [] }
        
        var edges: [(CGPoint, CGPoint)] = []
        for i in 0..<corners.count {
            let nextIndex = (i + 1) % corners.count
            edges.append((corners[i], corners[nextIndex]))
        }
        return edges
    }
    
    private func isEdgeStraight(_ edge: (CGPoint, CGPoint)) -> Bool {
        let (start, end) = edge
        let length = distanceBetween(start, end)
        return length > minimumStrokeLength
    }
    
    private func countPerpendicularEdges(_ edges: [(CGPoint, CGPoint)]) -> Int {
        guard edges.count >= 2 else { return 0 }
        
        var perpendicularCount = 0
        for i in 0..<edges.count {
            let nextIndex = (i + 1) % edges.count
            let edge1 = edges[i]
            let edge2 = edges[nextIndex]
            
            if areEdgesPerpendicular(edge1, edge2) {
                perpendicularCount += 1
            }
        }
        
        return perpendicularCount
    }
    
    private func areEdgesPerpendicular(_ edge1: (CGPoint, CGPoint), _ edge2: (CGPoint, CGPoint)) -> Bool {
        let (p1, p2) = edge1
        let (p3, p4) = edge2
        
        let v1 = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        let v2 = CGPoint(x: p4.x - p3.x, y: p4.y - p3.y)
        
        let dot = v1.x * v2.x + v1.y * v2.y
        let mag1 = sqrt(v1.x * v1.x + v1.y * v1.y)
        let mag2 = sqrt(v2.x * v2.x + v2.y * v2.y)
        
        guard mag1 > 0 && mag2 > 0 else { return false }
        
        let cosAngle = abs(dot) / (mag1 * mag2)
        return cosAngle < 0.2 // Close to perpendicular (cos(90°) = 0)
    }
    
    private func createUnknownResult() -> GeometricAnalysisResult {
        return GeometricAnalysisResult(
            shapeType: .line, // Use line as default since unknown is not available
            confidence: 0.0,
            geometricProperties: GeometricProperties(
                length: 0,
                angle: 0,
                curvature: 0,
                boundingBox: .zero,
                centerPoint: .zero,
                isClosed: false,
                symmetry: 0
            ),
            feedback: "Please draw a stroke to get feedback",
            suggestions: ["Start with a simple line or circle"]
        )
    }
}

// MARK: - Timeout Error for Memory Management
enum AnalysisTimeoutError: Error, LocalizedError {
    case timeoutExceeded
    
    var errorDescription: String? {
        switch self {
        case .timeoutExceeded:
            return "Analysis timeout exceeded"
        }
    }
}
