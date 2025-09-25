import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Drawing Mathematics Utilities
struct DrawingMath {
    
    // MARK: - Constants
    static let goldenRatio: CGFloat = 1.618033988749
    static let inverseGoldenRatio: CGFloat = 0.618033988749
    static let pi: CGFloat = CGFloat.pi
    static let twoPi: CGFloat = CGFloat.pi * 2
    
    // MARK: - Point Utilities
    
    /// Calculate distance between two points
    static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Calculate midpoint between two points
    static func midpoint(between point1: CGPoint, and point2: CGPoint) -> CGPoint {
        return CGPoint(
            x: (point1.x + point2.x) / 2,
            y: (point1.y + point2.y) / 2
        )
    }
    
    /// Calculate angle between two points in radians
    static func angle(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return atan2(point2.y - point1.y, point2.x - point1.x)
    }
    
    /// Rotate a point around another point by a given angle
    static func rotate(point: CGPoint, around center: CGPoint, by angle: CGFloat) -> CGPoint {
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        
        let translatedX = point.x - center.x
        let translatedY = point.y - center.y
        
        let rotatedX = translatedX * cosAngle - translatedY * sinAngle
        let rotatedY = translatedX * sinAngle + translatedY * cosAngle
        
        return CGPoint(x: rotatedX + center.x, y: rotatedY + center.y)
    }
    
    /// Linear interpolation between two points
    static func lerp(from startPoint: CGPoint, to endPoint: CGPoint, t: CGFloat) -> CGPoint {
        let clampedT = max(0, min(1, t))
        return CGPoint(
            x: startPoint.x + (endPoint.x - startPoint.x) * clampedT,
            y: startPoint.y + (endPoint.y - startPoint.y) * clampedT
        )
    }
    
    // MARK: - Circle and Arc Utilities
    
    /// Generate points for a circle
    static func circlePoints(center: CGPoint, radius: CGFloat, segments: Int = 64) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = twoPi / CGFloat(segments)
        
        for i in 0..<segments {
            let angle = CGFloat(i) * angleStep
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    /// Generate points for an ellipse
    static func ellipsePoints(center: CGPoint, radiusX: CGFloat, radiusY: CGFloat, segments: Int = 64) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = twoPi / CGFloat(segments)
        
        for i in 0..<segments {
            let angle = CGFloat(i) * angleStep
            let x = center.x + radiusX * cos(angle)
            let y = center.y + radiusY * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    /// Generate points for an arc
    static func arcPoints(center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, segments: Int = 32) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleRange = endAngle - startAngle
        let angleStep = angleRange / CGFloat(segments - 1)
        
        for i in 0..<segments {
            let angle = startAngle + CGFloat(i) * angleStep
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    // MARK: - Geometric Shape Utilities
    
    /// Generate points for a regular polygon
    static func polygonPoints(center: CGPoint, radius: CGFloat, sides: Int, rotation: CGFloat = 0) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = twoPi / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = CGFloat(i) * angleStep + rotation
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    /// Generate points for a rectangle
    static func rectanglePoints(center: CGPoint, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        return [
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight), // Top-left
            CGPoint(x: center.x + halfWidth, y: center.y - halfHeight), // Top-right
            CGPoint(x: center.x + halfWidth, y: center.y + halfHeight), // Bottom-right
            CGPoint(x: center.x - halfWidth, y: center.y + halfHeight)  // Bottom-left
        ]
    }
    
    /// Generate points for a rounded rectangle
    static func roundedRectanglePoints(center: CGPoint, width: CGFloat, height: CGFloat, cornerRadius: CGFloat, segments: Int = 8) -> [CGPoint] {
        var points: [CGPoint] = []
        let halfWidth = width / 2
        let halfHeight = height / 2
        let radius = min(cornerRadius, min(halfWidth, halfHeight))
        
        // Define corner centers
        let corners = [
            CGPoint(x: center.x + halfWidth - radius, y: center.y - halfHeight + radius), // Top-right
            CGPoint(x: center.x + halfWidth - radius, y: center.y + halfHeight - radius), // Bottom-right
            CGPoint(x: center.x - halfWidth + radius, y: center.y + halfHeight - radius), // Bottom-left
            CGPoint(x: center.x - halfWidth + radius, y: center.y - halfHeight + radius)  // Top-left
        ]
        
        let startAngles: [CGFloat] = [0, pi/2, pi, 3*pi/2]
        
        for i in 0..<4 {
            let cornerCenter = corners[i]
            let startAngle = startAngles[i]
            let endAngle = startAngle + pi/2
            
            let arcPoints = self.arcPoints(center: cornerCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, segments: segments)
            points.append(contentsOf: arcPoints)
        }
        
        return points
    }
    
    // MARK: - Bezier Curve Utilities
    
    /// Generate points for a quadratic Bezier curve
    static func quadraticBezierPoints(start: CGPoint, control: CGPoint, end: CGPoint, segments: Int = 32) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = quadraticBezierPoint(start: start, control: control, end: end, t: t)
            points.append(point)
        }
        
        return points
    }
    
    /// Calculate point on quadratic Bezier curve at parameter t
    static func quadraticBezierPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }
    
    /// Generate points for a cubic Bezier curve
    static func cubicBezierPoints(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint, segments: Int = 32) -> [CGPoint] {
        var points: [CGPoint] = []
        
        for i in 0...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = cubicBezierPoint(start: start, control1: control1, control2: control2, end: end, t: t)
            points.append(point)
        }
        
        return points
    }
    
    /// Calculate point on cubic Bezier curve at parameter t
    static func cubicBezierPoint(start: CGPoint, control1: CGPoint, control2: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let oneMinusTSquared = oneMinusT * oneMinusT
        let oneMinusTCubed = oneMinusTSquared * oneMinusT
        let tSquared = t * t
        let tCubed = tSquared * t
        
        let x = oneMinusTCubed * start.x + 3 * oneMinusTSquared * t * control1.x + 3 * oneMinusT * tSquared * control2.x + tCubed * end.x
        let y = oneMinusTCubed * start.y + 3 * oneMinusTSquared * t * control1.y + 3 * oneMinusT * tSquared * control2.y + tCubed * end.y
        
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Proportion and Golden Ratio Utilities
    
    /// Calculate golden ratio divisions of a length
    static func goldenRatioDivisions(length: CGFloat) -> (major: CGFloat, minor: CGFloat) {
        let major = length * inverseGoldenRatio
        let minor = length - major
        return (major, minor)
    }
    
    /// Create golden rectangle proportions
    static func goldenRectangle(width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width / goldenRatio)
    }
    
    /// Create golden spiral points
    static func goldenSpiralPoints(center: CGPoint, initialRadius: CGFloat, turns: CGFloat = 2, segments: Int = 100) -> [CGPoint] {
        var points: [CGPoint] = []
        let totalAngle = turns * twoPi
        let angleStep = totalAngle / CGFloat(segments)
        let radiusGrowthFactor = pow(goldenRatio, 1 / (twoPi / angleStep))
        
        var currentRadius = initialRadius
        
        for i in 0..<segments {
            let angle = CGFloat(i) * angleStep
            let x = center.x + currentRadius * cos(angle)
            let y = center.y + currentRadius * sin(angle)
            points.append(CGPoint(x: x, y: y))
            
            currentRadius *= radiusGrowthFactor
        }
        
        return points
    }
    
    // MARK: - Face Proportion Utilities (Loomis Method)
    
    /// Calculate facial proportions using the Loomis method
    static func loomisHeadProportions(headCenter: CGPoint, headRadius: CGFloat) -> LoomisProportions {
        let eyeLineY = headCenter.y
        let noseLineY = headCenter.y + headRadius * 0.5
        let mouthLineY = headCenter.y + headRadius * 0.83
        let chinY = headCenter.y + headRadius * 1.2
        
        let eyeWidth = headRadius * 0.3
        let eyeSeparation = eyeWidth
        let leftEyeX = headCenter.x - eyeSeparation / 2 - eyeWidth / 2
        let rightEyeX = headCenter.x + eyeSeparation / 2 + eyeWidth / 2
        
        return LoomisProportions(
            headCenter: headCenter,
            headRadius: headRadius,
            eyeLine: CGPoint(x: headCenter.x, y: eyeLineY),
            noseLine: CGPoint(x: headCenter.x, y: noseLineY),
            mouthLine: CGPoint(x: headCenter.x, y: mouthLineY),
            chinLine: CGPoint(x: headCenter.x, y: chinY),
            leftEye: CGPoint(x: leftEyeX, y: eyeLineY),
            rightEye: CGPoint(x: rightEyeX, y: eyeLineY),
            eyeWidth: eyeWidth
        )
    }
    
    // MARK: - Line and Curve Analysis
    
    /// Calculate the distance from a point to a line segment
    static func distanceFromPointToLineSegment(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let A = point.x - lineStart.x
        let B = point.y - lineStart.y
        let C = lineEnd.x - lineStart.x
        let D = lineEnd.y - lineStart.y
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        
        if lenSq == 0 {
            return distance(from: point, to: lineStart)
        }
        
        let param = dot / lenSq
        
        let closestPoint: CGPoint
        if param < 0 {
            closestPoint = lineStart
        } else if param > 1 {
            closestPoint = lineEnd
        } else {
            closestPoint = CGPoint(x: lineStart.x + param * C, y: lineStart.y + param * D)
        }
        
        return distance(from: point, to: closestPoint)
    }
    
    /// Smooth a path using moving average
    static func smoothPath(_ points: [CGPoint], windowSize: Int = 3) -> [CGPoint] {
        guard points.count > windowSize else { return points }
        
        var smoothedPoints: [CGPoint] = []
        let halfWindow = windowSize / 2
        
        for i in 0..<points.count {
            let startIndex = max(0, i - halfWindow)
            let endIndex = min(points.count - 1, i + halfWindow)
            
            var sumX: CGFloat = 0
            var sumY: CGFloat = 0
            var count = 0
            
            for j in startIndex...endIndex {
                sumX += points[j].x
                sumY += points[j].y
                count += 1
            }
            
            smoothedPoints.append(CGPoint(x: sumX / CGFloat(count), y: sumY / CGFloat(count)))
        }
        
        return smoothedPoints
    }
    
    /// Simplify a path using Douglas-Peucker algorithm
    static func simplifyPath(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        return douglasPeucker(points: points, epsilon: tolerance)
    }
    
    private static func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        let firstPoint = points.first!
        let lastPoint = points.last!
        
        var maxDistance: CGFloat = 0
        var maxIndex = 0
        
        for i in 1..<(points.count - 1) {
            let distance = distanceFromPointToLineSegment(point: points[i], lineStart: firstPoint, lineEnd: lastPoint)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        if maxDistance > epsilon {
            let leftSegment = douglasPeucker(points: Array(points[0...maxIndex]), epsilon: epsilon)
            let rightSegment = douglasPeucker(points: Array(points[maxIndex..<points.count]), epsilon: epsilon)
            
            return leftSegment + Array(rightSegment.dropFirst())
        } else {
            return [firstPoint, lastPoint]
        }
    }
    
    // MARK: - Perspective and Projection
    
    /// Calculate vanishing point for one-point perspective
    static func onePointPerspectiveVanishingPoint(imageSize: CGSize, horizonRatio: CGFloat = 0.4) -> CGPoint {
        return CGPoint(x: imageSize.width / 2, y: imageSize.height * horizonRatio)
    }
    
    /// Calculate vanishing points for two-point perspective
    static func twoPointPerspectiveVanishingPoints(imageSize: CGSize, horizonRatio: CGFloat = 0.4, separation: CGFloat = 0.8) -> (left: CGPoint, right: CGPoint) {
        let horizonY = imageSize.height * horizonRatio
        let separationDistance = imageSize.width * separation
        
        let leftVP = CGPoint(x: imageSize.width / 2 - separationDistance / 2, y: horizonY)
        let rightVP = CGPoint(x: imageSize.width / 2 + separationDistance / 2, y: horizonY)
        
        return (left: leftVP, right: rightVP)
    }
    
    /// Calculate perspective line from vanishing point through a given point
    static func perspectiveLine(vanishingPoint: CGPoint, throughPoint: CGPoint, length: CGFloat) -> (start: CGPoint, end: CGPoint) {
        let direction = CGPoint(
            x: throughPoint.x - vanishingPoint.x,
            y: throughPoint.y - vanishingPoint.y
        )
        
        let magnitude = sqrt(direction.x * direction.x + direction.y * direction.y)
        let normalizedDirection = CGPoint(x: direction.x / magnitude, y: direction.y / magnitude)
        
        let start = CGPoint(
            x: throughPoint.x - normalizedDirection.x * length / 2,
            y: throughPoint.y - normalizedDirection.y * length / 2
        )
        
        let end = CGPoint(
            x: throughPoint.x + normalizedDirection.x * length / 2,
            y: throughPoint.y + normalizedDirection.y * length / 2
        )
        
        return (start: start, end: end)
    }
}

// MARK: - Supporting Structures

struct LoomisProportions {
    let headCenter: CGPoint
    let headRadius: CGFloat
    let eyeLine: CGPoint
    let noseLine: CGPoint
    let mouthLine: CGPoint
    let chinLine: CGPoint
    let leftEye: CGPoint
    let rightEye: CGPoint
    let eyeWidth: CGFloat
}

