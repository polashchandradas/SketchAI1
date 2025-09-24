import Foundation
import CoreGraphics

// MARK: - Path Utilities
class PathUtilities {

    // MARK: - Path Generation
    static func generateReferencePath(from shape: GuideShape) -> [CGPoint] {
        switch shape.type {
        case .circle:
            return generateCirclePath(center: shape.center, radius: shape.dimensions.width / 2)
        case .line:
            return shape.points
        case .curve:
            return interpolateCurvePath(shape.points)
        case .rectangle:
            return generateRectanglePath(center: shape.center, size: shape.dimensions)
        case .oval:
            return generateOvalPath(center: shape.center, size: shape.dimensions)
        case .polygon:
            return shape.points
        }
    }

    // MARK: - Path Manipulation
    static func smoothPath(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var smoothedPoints: [CGPoint] = [points[0]]
        for i in 1..<(points.count - 1) {
            let smoothedX = (points[i - 1].x + points[i].x + points[i + 1].x) / 3
            let smoothedY = (points[i - 1].y + points[i].y + points[i + 1].y) / 3
            smoothedPoints.append(CGPoint(x: smoothedX, y: smoothedY))
        }
        smoothedPoints.append(points.last!)
        return smoothedPoints
    }

    static func resamplePath(_ points: [CGPoint], targetCount: Int) -> [CGPoint] {
        guard points.count > targetCount else { return points }
        var resampledPoints: [CGPoint] = []
        let step = Double(points.count - 1) / Double(targetCount - 1)
        for i in 0..<targetCount {
            let index = Int(Double(i) * step)
            resampledPoints.append(points[min(index, points.count - 1)])
        }
        return resampledPoints
    }

    static func downsampleWithCurvatureAwareness(_ points: [CGPoint], targetSize: Int) -> [CGPoint] {
        guard points.count > targetSize else { return points }
        let curvatures = calculatePointCurvatures(points)
        var candidates: [(index: Int, score: Double)] = []

        for i in 0..<points.count {
            let uniformScore = 1.0 - abs(Double(i) / Double(points.count - 1) - 0.5) * 2.0
            let curvatureScore = curvatures[i]
            candidates.append((index: i, score: uniformScore * 0.3 + curvatureScore * 0.7))
        }

        var selectedIndices = Set<Int>([0, points.count - 1])
        candidates.sort { $0.score > $1.score }
        for candidate in candidates.prefix(targetSize - 2) {
            selectedIndices.insert(candidate.index)
        }
        return selectedIndices.sorted().map { points[$0] }
    }

    // MARK: - Private Helper Methods
    private static func generateCirclePath(center: CGPoint, radius: CGFloat, segments: Int = 64) -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0..<segments {
            let angle = Double(i) * 2.0 * Double.pi / Double(segments)
            points.append(CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
        }
        return points
    }

    private static func generateRectanglePath(center: CGPoint, size: CGSize) -> [CGPoint] {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        return [
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight)
        ]
    }

    private static func generateOvalPath(center: CGPoint, size: CGSize, segments: Int = 64) -> [CGPoint] {
        var points: [CGPoint] = []
        let radiusX = size.width / 2
        let radiusY = size.height / 2
        for i in 0..<segments {
            let angle = Double(i) * 2.0 * Double.pi / Double(segments)
            points.append(CGPoint(x: center.x + radiusX * cos(angle), y: center.y + radiusY * sin(angle)))
        }
        return points
    }

    private static func interpolateCurvePath(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        var interpolatedPoints: [CGPoint] = []
        let segmentsPerSection = 16
        for i in 0..<(points.count - 1) {
            let start = points[i]
            let end = points[i + 1]
            for j in 0..<segmentsPerSection {
                let t = CGFloat(j) / CGFloat(segmentsPerSection)
                interpolatedPoints.append(CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
            }
        }
        interpolatedPoints.append(points.last!)
        return interpolatedPoints
    }

    static func calculateSequenceComplexity(_ sequence: [CGPoint]) -> Double {
        guard sequence.count > 2 else { return 0.0 }
        var totalVariation = 0.0
        for i in 1..<sequence.count {
            totalVariation += distance(sequence[i - 1], sequence[i])
        }
        let averageSegmentLength = totalVariation / Double(sequence.count - 1)
        let variance = sequence.indices.dropFirst().map { i in
            pow(distance(sequence[i - 1], sequence[i]) - averageSegmentLength, 2)
        }.reduce(0, +) / Double(sequence.count - 1)
        return min(1.0, sqrt(variance) / averageSegmentLength)
    }

    private static func calculatePointCurvatures(_ points: [CGPoint]) -> [Double] {
        guard points.count >= 3 else { return Array(repeating: 0.0, count: points.count) }
        var curvatures: [Double] = [0.0]
        for i in 1..<(points.count - 1) {
            let p1 = points[i - 1]
            let p2 = points[i]
            let p3 = points[i + 1]
            let a = distance(p1, p2)
            let b = distance(p2, p3)
            let c = distance(p1, p3)
            let area = abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2.0
            let curvature = (a > 0.01 && b > 0.01 && c > 0.01) ? (4.0 * Double(area)) / (Double(a * b * c)) : 0.0
            curvatures.append(min(1.0, curvature))
        }
        curvatures.append(0.0)
        return curvatures
    }

    private static func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        let dx = Double(p1.x - p2.x)
        let dy = Double(p1.y - p2.y)
        return sqrt(dx * dx + dy * dy)
    }
}
