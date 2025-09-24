import Foundation
import CoreGraphics
import SwiftUI

// MARK: - Proportion Calculator
class ProportionCalculator {
    
    // MARK: - Golden Ratio Constants
    private let goldenRatio: CGFloat = 1.618
    private let inverseGoldenRatio: CGFloat = 0.618
    
    // MARK: - Face Proportion Constants (Loomis Method)
    private struct FaceProportions {
        static let eyeLineRatio: CGFloat = 0.5        // Eyes at halfway point
        static let noseLineRatio: CGFloat = 0.67      // Nose line at 2/3 down
        static let mouthLineRatio: CGFloat = 0.83     // Mouth line at 5/6 down
        static let eyeWidthRatio: CGFloat = 0.2       // Eye width is 1/5 of face width
        static let eyeSeparationRatio: CGFloat = 0.2  // Space between eyes equals eye width
        static let noseWidthRatio: CGFloat = 0.25     // Nose width
        static let mouthWidthRatio: CGFloat = 0.4     // Mouth width
    }
    
    // MARK: - Main Calculation Method
    func calculateProportions(for analysisResult: ImageAnalysisResult) -> ProportionData {
        switch analysisResult.boundingBoxes.first?.type {
        case .face:
            return calculateFaceProportions(from: analysisResult)
        case .hand:
            return calculateHandProportions(from: analysisResult)
        case .animal:
            return calculateAnimalProportions(from: analysisResult)
        case .building:
            return calculatePerspectiveProportions(from: analysisResult)
        case .flower:
            return calculateNatureProportions(from: analysisResult)
        case .vehicle:
            return calculateObjectProportions(from: analysisResult)
        default:
            return calculateGenericProportions(from: analysisResult)
        }
    }
    
    // MARK: - Face Proportions (Loomis Method)
    private func calculateFaceProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let faceBounds = result.boundingBoxes.first(where: { $0.type == .face })?.boundingBox else {
            return createDefaultFaceProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        let faceCenter = CGPoint(x: faceBounds.midX, y: faceBounds.midY)
        let faceWidth = faceBounds.width
        let faceHeight = faceBounds.height
        
        // Step 1: Basic head construction (Loomis sphere method)
        let headRadius = min(faceWidth, faceHeight) * 0.4
        let headCenter = CGPoint(x: faceCenter.x, y: faceCenter.y - faceHeight * 0.1)
        
        // Step 2: Face guidelines
        let eyeLine = CGPoint(x: faceCenter.x, y: faceCenter.y - faceHeight * 0.1)
        let noseLine = CGPoint(x: faceCenter.x, y: faceCenter.y + faceHeight * 0.17)
        let mouthLine = CGPoint(x: faceCenter.x, y: faceCenter.y + faceHeight * 0.33)
        let chinLine = CGPoint(x: faceCenter.x, y: faceCenter.y + faceHeight * 0.5)
        
        // Step 3: Feature positions
        let leftEyePos = findOptimalEyePosition(.leftEye, from: result.landmarks, fallback: CGPoint(x: eyeLine.x - faceWidth * 0.15, y: eyeLine.y))
        let rightEyePos = findOptimalEyePosition(.rightEye, from: result.landmarks, fallback: CGPoint(x: eyeLine.x + faceWidth * 0.15, y: eyeLine.y))
        let nosePos = findOptimalLandmarkPosition(.nose, from: result.landmarks, fallback: noseLine)
        let mouthPos = findOptimalLandmarkPosition(.mouth, from: result.landmarks, fallback: mouthLine)
        
        // Step 4: Construct drawing guides
        let constructionElements = createFaceConstructionElements(
            headCenter: headCenter,
            headRadius: headRadius,
            faceWidth: faceWidth,
            faceHeight: faceHeight,
            eyeLine: eyeLine,
            noseLine: noseLine,
            mouthLine: mouthLine,
            chinLine: chinLine
        )
        
        let featureElements = createFaceFeatureElements(
            leftEye: leftEyePos,
            rightEye: rightEyePos,
            nose: nosePos,
            mouth: mouthPos,
            faceWidth: faceWidth
        )
        
        return ProportionData(
            category: .faces,
            boundingBox: faceBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: headCenter, label: "Head Center"),
                KeyPoint(type: .guideline, position: eyeLine, label: "Eye Line"),
                KeyPoint(type: .guideline, position: noseLine, label: "Nose Line"),
                KeyPoint(type: .guideline, position: mouthLine, label: "Mouth Line"),
                KeyPoint(type: .feature, position: leftEyePos, label: "Left Eye"),
                KeyPoint(type: .feature, position: rightEyePos, label: "Right Eye"),
                KeyPoint(type: .feature, position: nosePos, label: "Nose"),
                KeyPoint(type: .feature, position: mouthPos, label: "Mouth")
            ],
            constructionElements: constructionElements + featureElements,
            confidence: result.confidence
        )
    }
    
    private func createFaceConstructionElements(
        headCenter: CGPoint,
        headRadius: CGFloat,
        faceWidth: CGFloat,
        faceHeight: CGFloat,
        eyeLine: CGPoint,
        noseLine: CGPoint,
        mouthLine: CGPoint,
        chinLine: CGPoint
    ) -> [ProportionElement] {
        
        return [
            // Head circle (Loomis sphere)
            ProportionElement(
                type: .circle,
                points: [headCenter],
                dimensions: CGSize(width: headRadius * 2, height: headRadius * 2),
                strokeWidth: 2.0,
                color: .blue,
                style: .dashed([5, 3]),
                priority: 1,
                description: "Basic head sphere"
            ),
            
            // Face oval
            ProportionElement(
                type: .oval,
                points: [CGPoint(x: headCenter.x, y: headCenter.y + headRadius * 0.3)],
                dimensions: CGSize(width: faceWidth * 0.8, height: faceHeight * 0.9),
                strokeWidth: 2.0,
                color: .blue,
                style: .solid,
                priority: 2,
                description: "Face oval outline"
            ),
            
            // Horizontal guidelines
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: headCenter.x - faceWidth * 0.5, y: eyeLine.y),
                    CGPoint(x: headCenter.x + faceWidth * 0.5, y: eyeLine.y)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .green,
                style: .dashed([3, 2]),
                priority: 3,
                description: "Eye guideline"
            ),
            
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: headCenter.x - faceWidth * 0.4, y: noseLine.y),
                    CGPoint(x: headCenter.x + faceWidth * 0.4, y: noseLine.y)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .green,
                style: .dashed([3, 2]),
                priority: 4,
                description: "Nose guideline"
            ),
            
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: headCenter.x - faceWidth * 0.3, y: mouthLine.y),
                    CGPoint(x: headCenter.x + faceWidth * 0.3, y: mouthLine.y)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .green,
                style: .dashed([3, 2]),
                priority: 5,
                description: "Mouth guideline"
            ),
            
            // Center line
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: headCenter.x, y: headCenter.y - headRadius),
                    CGPoint(x: headCenter.x, y: chinLine.y)
                ],
                dimensions: .zero,
                strokeWidth: 1.0,
                color: .orange,
                style: .dotted,
                priority: 6,
                description: "Center line"
            )
        ]
    }
    
    private func createFaceFeatureElements(
        leftEye: CGPoint,
        rightEye: CGPoint,
        nose: CGPoint,
        mouth: CGPoint,
        faceWidth: CGFloat
    ) -> [ProportionElement] {
        
        let eyeWidth = faceWidth * FaceProportions.eyeWidthRatio
        let eyeHeight = eyeWidth * 0.6
        
        return [
            // Left eye
            ProportionElement(
                type: .oval,
                points: [leftEye],
                dimensions: CGSize(width: eyeWidth, height: eyeHeight),
                strokeWidth: 1.5,
                color: .purple,
                style: .solid,
                priority: 7,
                description: "Left eye shape"
            ),
            
            // Right eye
            ProportionElement(
                type: .oval,
                points: [rightEye],
                dimensions: CGSize(width: eyeWidth, height: eyeHeight),
                strokeWidth: 1.5,
                color: .purple,
                style: .solid,
                priority: 8,
                description: "Right eye shape"
            ),
            
            // Nose
            ProportionElement(
                type: .triangle,
                points: [
                    CGPoint(x: nose.x, y: nose.y - eyeHeight * 0.5),
                    CGPoint(x: nose.x - faceWidth * 0.08, y: nose.y + eyeHeight * 0.5),
                    CGPoint(x: nose.x + faceWidth * 0.08, y: nose.y + eyeHeight * 0.5)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .purple,
                style: .solid,
                priority: 9,
                description: "Nose shape"
            ),
            
            // Mouth
            ProportionElement(
                type: .oval,
                points: [mouth],
                dimensions: CGSize(width: faceWidth * FaceProportions.mouthWidthRatio, height: eyeHeight * 0.8),
                strokeWidth: 1.5,
                color: .purple,
                style: .solid,
                priority: 10,
                description: "Mouth shape"
            )
        ]
    }
    
    // MARK: - Hand Proportions
    private func calculateHandProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let handBounds = result.boundingBoxes.first?.boundingBox else {
            return createDefaultHandProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        let handCenter = CGPoint(x: handBounds.midX, y: handBounds.midY)
        let handWidth = handBounds.width
        let handHeight = handBounds.height
        
        // Hand proportions: palm is roughly square, fingers are about 3/4 of palm height
        let palmHeight = handHeight * 0.6
        let fingerLength = handHeight * 0.4
        let palmWidth = handWidth * 0.8
        
        let constructionElements = createHandConstructionElements(
            center: handCenter,
            palmWidth: palmWidth,
            palmHeight: palmHeight,
            fingerLength: fingerLength
        )
        
        return ProportionData(
            category: .hands,
            boundingBox: handBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: handCenter, label: "Palm Center"),
                KeyPoint(type: .guideline, position: CGPoint(x: handCenter.x, y: handCenter.y - palmHeight/2), label: "Finger Base"),
                KeyPoint(type: .guideline, position: CGPoint(x: handCenter.x, y: handCenter.y + palmHeight/2), label: "Wrist Line")
            ],
            constructionElements: constructionElements,
            confidence: result.confidence
        )
    }
    
    private func createHandConstructionElements(
        center: CGPoint,
        palmWidth: CGFloat,
        palmHeight: CGFloat,
        fingerLength: CGFloat
    ) -> [ProportionElement] {
        
        return [
            // Palm rectangle
            ProportionElement(
                type: .rectangle,
                points: [center],
                dimensions: CGSize(width: palmWidth, height: palmHeight),
                strokeWidth: 2.0,
                color: .blue,
                style: .solid,
                priority: 1,
                description: "Palm outline"
            ),
            
            // Finger guidelines
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: center.x, y: center.y - palmHeight/2),
                    CGPoint(x: center.x, y: center.y - palmHeight/2 - fingerLength)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .green,
                style: .dashed([3, 2]),
                priority: 2,
                description: "Middle finger guideline"
            )
        ]
    }
    
    // MARK: - Animal Proportions
    private func calculateAnimalProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let animalBounds = result.boundingBoxes.first?.boundingBox else {
            return createDefaultAnimalProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        // Generic animal proportions - head, body, legs
        let bodyCenter = CGPoint(x: animalBounds.midX, y: animalBounds.midY)
        let bodyWidth = animalBounds.width * 0.7
        let bodyHeight = animalBounds.height * 0.4
        
        let constructionElements = createAnimalConstructionElements(
            bodyCenter: bodyCenter,
            bodyWidth: bodyWidth,
            bodyHeight: bodyHeight,
            totalBounds: animalBounds
        )
        
        return ProportionData(
            category: .animals,
            boundingBox: animalBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: bodyCenter, label: "Body Center"),
                KeyPoint(type: .feature, position: CGPoint(x: bodyCenter.x, y: animalBounds.minY + animalBounds.height * 0.2), label: "Head Position")
            ],
            constructionElements: constructionElements,
            confidence: result.confidence
        )
    }
    
    private func createAnimalConstructionElements(
        bodyCenter: CGPoint,
        bodyWidth: CGFloat,
        bodyHeight: CGFloat,
        totalBounds: CGRect
    ) -> [ProportionElement] {
        
        return [
            // Body oval
            ProportionElement(
                type: .oval,
                points: [bodyCenter],
                dimensions: CGSize(width: bodyWidth, height: bodyHeight),
                strokeWidth: 2.0,
                color: .blue,
                style: .solid,
                priority: 1,
                description: "Body shape"
            ),
            
            // Head circle
            ProportionElement(
                type: .circle,
                points: [CGPoint(x: bodyCenter.x, y: totalBounds.minY + totalBounds.height * 0.2)],
                dimensions: CGSize(width: bodyWidth * 0.4, height: bodyWidth * 0.4),
                strokeWidth: 2.0,
                color: .blue,
                style: .solid,
                priority: 2,
                description: "Head shape"
            )
        ]
    }
    
    // MARK: - Perspective Proportions
    private func calculatePerspectiveProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let objectBounds = result.boundingBoxes.first?.boundingBox else {
            return createDefaultPerspectiveProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        // One-point perspective guidelines
        let vanishingPoint = CGPoint(x: result.imageSize.width / 2, y: result.imageSize.height * 0.4)
        let horizonLine = vanishingPoint.y
        
        let constructionElements = createPerspectiveConstructionElements(
            vanishingPoint: vanishingPoint,
            horizonLine: horizonLine,
            objectBounds: objectBounds,
            imageSize: result.imageSize
        )
        
        return ProportionData(
            category: .perspective,
            boundingBox: objectBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: vanishingPoint, label: "Vanishing Point"),
                KeyPoint(type: .guideline, position: CGPoint(x: result.imageSize.width / 2, y: horizonLine), label: "Horizon Line")
            ],
            constructionElements: constructionElements,
            confidence: result.confidence
        )
    }
    
    private func createPerspectiveConstructionElements(
        vanishingPoint: CGPoint,
        horizonLine: CGFloat,
        objectBounds: CGRect,
        imageSize: CGSize
    ) -> [ProportionElement] {
        
        return [
            // Horizon line
            ProportionElement(
                type: .line,
                points: [
                    CGPoint(x: 0, y: horizonLine),
                    CGPoint(x: imageSize.width, y: horizonLine)
                ],
                dimensions: .zero,
                strokeWidth: 1.5,
                color: .orange,
                style: .dashed([5, 3]),
                priority: 1,
                description: "Horizon line"
            ),
            
            // Vanishing point
            ProportionElement(
                type: .circle,
                points: [vanishingPoint],
                dimensions: CGSize(width: 8, height: 8),
                strokeWidth: 2.0,
                color: .red,
                style: .solid,
                priority: 2,
                description: "Vanishing point"
            ),
            
            // Perspective guidelines
            ProportionElement(
                type: .line,
                points: [
                    vanishingPoint,
                    CGPoint(x: objectBounds.minX, y: objectBounds.maxY)
                ],
                dimensions: .zero,
                strokeWidth: 1.0,
                color: .green,
                style: .dashed([3, 2]),
                priority: 3,
                description: "Perspective guideline"
            ),
            
            ProportionElement(
                type: .line,
                points: [
                    vanishingPoint,
                    CGPoint(x: objectBounds.maxX, y: objectBounds.maxY)
                ],
                dimensions: .zero,
                strokeWidth: 1.0,
                color: .green,
                style: .dashed([3, 2]),
                priority: 4,
                description: "Perspective guideline"
            )
        ]
    }
    
    // MARK: - Nature/Flower Proportions
    private func calculateNatureProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let natureBounds = result.boundingBoxes.first?.boundingBox else {
            return createDefaultNatureProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        // Flower/plant proportions using golden spiral
        let center = CGPoint(x: natureBounds.midX, y: natureBounds.midY)
        let radius = min(natureBounds.width, natureBounds.height) * 0.4
        
        let constructionElements = createNatureConstructionElements(
            center: center,
            radius: radius,
            bounds: natureBounds
        )
        
        return ProportionData(
            category: .nature,
            boundingBox: natureBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: center, label: "Center"),
                KeyPoint(type: .feature, position: CGPoint(x: center.x, y: center.y - radius), label: "Top")
            ],
            constructionElements: constructionElements,
            confidence: result.confidence
        )
    }
    
    private func createNatureConstructionElements(
        center: CGPoint,
        radius: CGFloat,
        bounds: CGRect
    ) -> [ProportionElement] {
        
        return [
            // Main circle
            ProportionElement(
                type: .circle,
                points: [center],
                dimensions: CGSize(width: radius * 2, height: radius * 2),
                strokeWidth: 2.0,
                color: .green,
                style: .solid,
                priority: 1,
                description: "Main shape"
            ),
            
            // Golden ratio divisions
            ProportionElement(
                type: .circle,
                points: [center],
                dimensions: CGSize(width: radius * 2 / goldenRatio, height: radius * 2 / goldenRatio),
                strokeWidth: 1.5,
                color: .green,
                style: .dashed([3, 2]),
                priority: 2,
                description: "Golden ratio guide"
            )
        ]
    }
    
    // MARK: - Object Proportions
    private func calculateObjectProportions(from result: ImageAnalysisResult) -> ProportionData {
        guard let objectBounds = result.boundingBoxes.first?.boundingBox else {
            return createDefaultObjectProportions(in: CGRect(origin: .zero, size: result.imageSize))
        }
        
        // Basic geometric object proportions
        let center = CGPoint(x: objectBounds.midX, y: objectBounds.midY)
        
        let constructionElements = createObjectConstructionElements(
            center: center,
            bounds: objectBounds
        )
        
        return ProportionData(
            category: .objects,
            boundingBox: objectBounds,
            keyPoints: [
                KeyPoint(type: .construction, position: center, label: "Object Center")
            ],
            constructionElements: constructionElements,
            confidence: result.confidence
        )
    }
    
    private func createObjectConstructionElements(
        center: CGPoint,
        bounds: CGRect
    ) -> [ProportionElement] {
        
        return [
            // Bounding rectangle
            ProportionElement(
                type: .rectangle,
                points: [center],
                dimensions: CGSize(width: bounds.width * 0.8, height: bounds.height * 0.8),
                strokeWidth: 2.0,
                color: .blue,
                style: .solid,
                priority: 1,
                description: "Basic shape outline"
            )
        ]
    }
    
    // MARK: - Generic Proportions
    private func calculateGenericProportions(from result: ImageAnalysisResult) -> ProportionData {
        let bounds = CGRect(origin: .zero, size: result.imageSize)
        return createDefaultObjectProportions(in: bounds)
    }
    
    // MARK: - Helper Methods
    
    private func findOptimalEyePosition(_ eyeType: LandmarkType, from landmarks: [DetectedLandmark], fallback: CGPoint) -> CGPoint {
        return landmarks.first { $0.type == eyeType }?.point ?? fallback
    }
    
    private func findOptimalLandmarkPosition(_ landmarkType: LandmarkType, from landmarks: [DetectedLandmark], fallback: CGPoint) -> CGPoint {
        return landmarks.first { $0.type == landmarkType }?.point ?? fallback
    }
    
    // MARK: - Default Proportions
    
    private func createDefaultFaceProportions(in bounds: CGRect) -> ProportionData {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let faceWidth = bounds.width * 0.6
        let faceHeight = bounds.height * 0.8
        
        return ProportionData(
            category: .faces,
            boundingBox: CGRect(x: center.x - faceWidth/2, y: center.y - faceHeight/2, width: faceWidth, height: faceHeight),
            keyPoints: [
                KeyPoint(type: .construction, position: center, label: "Face Center")
            ],
            constructionElements: [
                ProportionElement(
                    type: .oval,
                    points: [center],
                    dimensions: CGSize(width: faceWidth, height: faceHeight),
                    strokeWidth: 2.0,
                    color: .blue,
                    style: .solid,
                    priority: 1,
                    description: "Basic face outline"
                )
            ],
            confidence: 0.5
        )
    }
    
    private func createDefaultHandProportions(in bounds: CGRect) -> ProportionData {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return ProportionData(
            category: .hands,
            boundingBox: bounds,
            keyPoints: [KeyPoint(type: .construction, position: center, label: "Hand Center")],
            constructionElements: [],
            confidence: 0.5
        )
    }
    
    private func createDefaultAnimalProportions(in bounds: CGRect) -> ProportionData {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return ProportionData(
            category: .animals,
            boundingBox: bounds,
            keyPoints: [KeyPoint(type: .construction, position: center, label: "Animal Center")],
            constructionElements: [],
            confidence: 0.5
        )
    }
    
    private func createDefaultPerspectiveProportions(in bounds: CGRect) -> ProportionData {
        let vanishingPoint = CGPoint(x: bounds.midX, y: bounds.height * 0.4)
        return ProportionData(
            category: .perspective,
            boundingBox: bounds,
            keyPoints: [KeyPoint(type: .construction, position: vanishingPoint, label: "Vanishing Point")],
            constructionElements: [],
            confidence: 0.5
        )
    }
    
    private func createDefaultNatureProportions(in bounds: CGRect) -> ProportionData {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return ProportionData(
            category: .nature,
            boundingBox: bounds,
            keyPoints: [KeyPoint(type: .construction, position: center, label: "Nature Center")],
            constructionElements: [],
            confidence: 0.5
        )
    }
    
    private func createDefaultObjectProportions(in bounds: CGRect) -> ProportionData {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        return ProportionData(
            category: .objects,
            boundingBox: bounds,
            keyPoints: [KeyPoint(type: .construction, position: center, label: "Object Center")],
            constructionElements: [],
            confidence: 0.5
        )
    }
}

// MARK: - Supporting Data Models

struct ProportionData {
    let category: LessonCategory
    let boundingBox: CGRect
    let keyPoints: [KeyPoint]
    let constructionElements: [ProportionElement]
    let confidence: Float
}

struct KeyPoint {
    let type: KeyPointType
    let position: CGPoint
    let label: String
}

enum KeyPointType {
    case construction  // Basic construction points
    case guideline    // Helper guidelines
    case feature      // Specific features (eyes, nose, etc.)
}

struct ProportionElement {
    let type: ElementType
    let points: [CGPoint]
    let dimensions: CGSize
    let strokeWidth: CGFloat
    let color: Color
    let style: StrokeStyle
    let priority: Int // Lower numbers drawn first
    let description: String
    
    enum ElementType {
        case circle
        case oval
        case rectangle
        case line
        case curve
        case triangle
        case polygon
    }
    
    enum StrokeStyle {
        case solid
        case dashed([CGFloat])
        case dotted
    }
}

