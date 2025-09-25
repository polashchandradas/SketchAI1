import Foundation
import CoreGraphics

// MARK: - Geometric Analysis
class GeometricAnalysis {

    static func analyzeShapeAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        switch targetShape.type {
        case .circle:
            return analyzeCircleAccuracy(stroke, targetShape: targetShape)
        case .oval:
            return analyzeOvalAccuracy(stroke, targetShape: targetShape)
        case .rectangle:
            return analyzeRectangleAccuracy(stroke, targetShape: targetShape)
        case .line:
            return analyzeLineAccuracy(stroke, targetShape: targetShape)
        case .curve:
            return analyzeCurveAccuracy(stroke, targetShape: targetShape)
        case .polygon:
            return analyzePolygonAccuracy(stroke, targetShape: targetShape)
        }
    }

    // MARK: - Private Shape Analysis Methods
    private static func analyzeCircleAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let center = targetShape.center
        let targetRadius = targetShape.dimensions.width / 2
        let distances = stroke.points.map { distance(from: $0, to: center) }
        let averageRadius = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - averageRadius, 2) }.reduce(0, +) / Double(distances.count)
        let standardDeviation = sqrt(variance)

        let radiusAccuracy = max(0.0, 1.0 - abs(averageRadius - Double(targetRadius)) / Double(targetRadius))
        let consistencyScore = max(0.0, 1.0 - (standardDeviation / Double(targetRadius)))
        let closureScore = analyzeShapeClosure(stroke.points, targetCenter: center)

        return (radiusAccuracy * 0.4 + consistencyScore * 0.4 + closureScore * 0.2)
    }

    private static func analyzeOvalAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let center = targetShape.center
        let radiusX = targetShape.dimensions.width / 2
        let radiusY = targetShape.dimensions.height / 2
        var deviations: [Double] = []

        for point in stroke.points {
            let dx = Double(point.x - center.x)
            let dy = Double(point.y - center.y)
            let normalizedDistance = (dx * dx) / (Double(radiusX) * Double(radiusX)) + (dy * dy) / (Double(radiusY) * Double(radiusY))
            let deviation = abs(normalizedDistance - 1.0)
            deviations.append(min(deviation, 1.0))
        }

        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        let accuracy = max(0.0, 1.0 - averageDeviation)
        let closureScore = analyzeShapeClosure(stroke.points, targetCenter: center)

        return (accuracy * 0.8 + closureScore * 0.2)
    }

    private static func analyzeRectangleAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        let center = targetShape.center
        let halfWidth = targetShape.dimensions.width / 2
        let halfHeight = targetShape.dimensions.height / 2
        let expectedCorners = [
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y + halfHeight)
        ]

        var edgeAccuracies: [Double] = []
        let segmentSize = max(1, stroke.points.count / 4)

        for i in 0..<4 {
            let startIndex = i * segmentSize
            let endIndex = min((i + 1) * segmentSize, stroke.points.count)
            if startIndex < endIndex {
                let segmentPoints = Array(stroke.points[startIndex..<endIndex])
                let edgeAccuracy = analyzeEdgeAlignment(points: segmentPoints, expectedStart: expectedCorners[i], expectedEnd: expectedCorners[(i + 1) % 4])
                edgeAccuracies.append(edgeAccuracy)
            }
        }

        let averageEdgeAccuracy = edgeAccuracies.isEmpty ? 0.0 : edgeAccuracies.reduce(0, +) / Double(edgeAccuracies.count)
        let cornerAccuracy = analyzeCornerProximity(stroke: stroke, expectedCorners: expectedCorners)
        let closureScore = analyzeShapeClosure(stroke.points, targetCenter: center)

        return (averageEdgeAccuracy * 0.5 + cornerAccuracy * 0.3 + closureScore * 0.2)
    }

    private static func analyzeLineAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        guard let startPoint = targetShape.points.first, let endPoint = targetShape.points.last, stroke.points.count >= 2 else { return 0.0 }
        let lineVector = CGPoint(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
        let lineLength = sqrt(lineVector.x * lineVector.x + lineVector.y * lineVector.y)
        guard lineLength > 0 else { return 0.0 }
        let lineDirection = CGPoint(x: lineVector.x / lineLength, y: lineVector.y / lineLength)

        let straightnessScore = analyzeLineStraightness(stroke: stroke, expectedDirection: lineDirection)
        let endpointScore = analyzeLineEndpoints(stroke: stroke, expectedStart: startPoint, expectedEnd: endPoint)
        let directionScore = analyzeLineDirection(stroke: stroke, expectedDirection: lineDirection)

        return (straightnessScore * 0.4 + endpointScore * 0.4 + directionScore * 0.2)
    }

    private static func analyzeCurveAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        return 0.75 // Placeholder
    }

    private static func analyzePolygonAccuracy(_ stroke: DrawingStroke, targetShape: GuideShape) -> Double {
        return 0.8 // Placeholder
    }


    // MARK: - Private Helper Methods
    private static func distance(from point1: CGPoint, to point2: CGPoint) -> Double {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(Double(dx * dx + dy * dy))
    }

    private static func analyzeShapeClosure(_ points: [CGPoint], targetCenter: CGPoint) -> Double {
        guard points.count > 3, let firstPoint = points.first, let lastPoint = points.last else { return 0.0 }
        let closureDistance = distance(from: firstPoint, to: lastPoint)
        let averageRadius = distance(from: firstPoint, to: targetCenter)
        return max(0.0, 1.0 - (closureDistance / (averageRadius * 0.2)))
    }

    private static func analyzeEdgeAlignment(points: [CGPoint], expectedStart: CGPoint, expectedEnd: CGPoint) -> Double {
        guard !points.isEmpty else { return 0.0 }
        let edgeVector = CGPoint(x: expectedEnd.x - expectedStart.x, y: expectedEnd.y - expectedStart.y)
        let edgeLength = sqrt(edgeVector.x * edgeVector.x + edgeVector.y * edgeVector.y)
        guard edgeLength > 0 else { return 0.0 }
        let edgeDirection = CGPoint(x: edgeVector.x / edgeLength, y: edgeVector.y / edgeLength)
        var totalDeviation = 0.0
        var pointCount = 0

        for i in 1..<points.count {
            let strokeVector = CGPoint(x: points[i].x - points[i - 1].x, y: points[i].y - points[i - 1].y)
            let strokeLength = sqrt(strokeVector.x * strokeVector.x + strokeVector.y * strokeVector.y)
            if strokeLength > 0 {
                let strokeDirection = CGPoint(x: strokeVector.x / strokeLength, y: strokeVector.y / strokeLength)
                let dotProduct = edgeDirection.x * strokeDirection.x + edgeDirection.y * strokeDirection.y
                totalDeviation += (1.0 - abs(dotProduct))
                pointCount += 1
            }
        }
        if pointCount == 0 { return 0.0 }
        let averageDeviation = totalDeviation / Double(pointCount)
        return max(0.0, 1.0 - averageDeviation)
    }

    private static func analyzeCornerProximity(stroke: DrawingStroke, expectedCorners: [CGPoint]) -> Double {
        guard stroke.points.count >= 4 else { return 0.0 }
        var cornerAccuracies: [Double] = []
        for expectedCorner in expectedCorners {
            let closestDistance = stroke.points.map { distance(from: $0, to: expectedCorner) }.min() ?? Double.infinity
            let accuracy = max(0.0, 1.0 - (closestDistance / 50.0))
            cornerAccuracies.append(accuracy)
        }
        return cornerAccuracies.reduce(0, +) / Double(cornerAccuracies.count)
    }

    private static func analyzeLineStraightness(stroke: DrawingStroke, expectedDirection: CGPoint) -> Double {
        guard stroke.points.count >= 3 else { return 1.0 }
        var deviations: [Double] = []
        for i in 1..<stroke.points.count {
            let segmentVector = CGPoint(x: stroke.points[i].x - stroke.points[i - 1].x, y: stroke.points[i].y - stroke.points[i - 1].y)
            let segmentLength = sqrt(segmentVector.x * segmentVector.x + segmentVector.y * segmentVector.y)
            if segmentLength > 0 {
                let segmentDirection = CGPoint(x: segmentVector.x / segmentLength, y: segmentVector.y / segmentLength)
                let dotProduct = expectedDirection.x * segmentDirection.x + expectedDirection.y * segmentDirection.y
                let angle = acos(max(-1.0, min(1.0, Double(dotProduct))))
                deviations.append(angle / Double.pi)
            }
        }
        if deviations.isEmpty { return 1.0 }
        let averageDeviation = deviations.reduce(0, +) / Double(deviations.count)
        return max(0.0, 1.0 - averageDeviation)
    }

    private static func analyzeLineEndpoints(stroke: DrawingStroke, expectedStart: CGPoint, expectedEnd: CGPoint) -> Double {
        guard let strokeStart = stroke.points.first, let strokeEnd = stroke.points.last else { return 0.0 }
        let startDistance = distance(from: strokeStart, to: expectedStart)
        let endDistance = distance(from: strokeEnd, to: expectedEnd)
        let lineLength = distance(from: expectedStart, to: expectedEnd)
        let tolerance = max(20.0, lineLength * 0.1)
        let startAccuracy = max(0.0, 1.0 - (startDistance / tolerance))
        let endAccuracy = max(0.0, 1.0 - (endDistance / tolerance))
        return (startAccuracy + endAccuracy) / 2.0
    }

    private static func analyzeLineDirection(stroke: DrawingStroke, expectedDirection: CGPoint) -> Double {
        guard let strokeStart = stroke.points.first, let strokeEnd = stroke.points.last else { return 0.0 }
        let strokeVector = CGPoint(x: strokeEnd.x - strokeStart.x, y: strokeEnd.y - strokeStart.y)
        let strokeLength = sqrt(strokeVector.x * strokeVector.x + strokeVector.y * strokeVector.y)
        guard strokeLength > 0 else { return 0.0 }
        let strokeDirection = CGPoint(x: strokeVector.x / strokeLength, y: strokeVector.y / strokeLength)
        let dotProduct = expectedDirection.x * strokeDirection.x + expectedDirection.y * strokeDirection.y
        return abs(dotProduct)
    }
}
