import Foundation
import SwiftUI
import CoreGraphics

// MARK: - Guide Generator
class GuideGenerator {
    
    // MARK: - Main Generation Method
    func generateGuides(from proportionData: ProportionData, category: LessonCategory) -> [DrawingGuide] {
        switch category {
        case .faces:
            return generateFaceGuides(from: proportionData)
        case .animals:
            return generateAnimalGuides(from: proportionData)
        case .objects:
            return generateObjectGuides(from: proportionData)
        case .hands:
            return generateHandGuides(from: proportionData)
        case .perspective:
            return generatePerspectiveGuides(from: proportionData)
        case .nature:
            return generateNatureGuides(from: proportionData)
        }
    }
    
    // MARK: - Face Guides (Loomis Method)
    private func generateFaceGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Step 1: Basic head construction
        guides.append(createHeadConstructionGuide(from: data))
        
        // Step 2: Face guidelines
        guides.append(createFaceGuidelinesGuide(from: data))
        
        // Step 3: Eye placement
        guides.append(createEyePlacementGuide(from: data))
        
        // Step 4: Nose construction
        guides.append(createNoseConstructionGuide(from: data))
        
        // Step 5: Mouth placement
        guides.append(createMouthPlacementGuide(from: data))
        
        // Step 6: Face outline refinement
        guides.append(createFaceOutlineGuide(from: data))
        
        return guides
    }
    
    private func createHeadConstructionGuide(from data: ProportionData) -> DrawingGuide {
        let headConstructionElements = data.constructionElements.filter { element in
            element.description.contains("head") || element.description.contains("sphere")
        }
        
        let shapes = headConstructionElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let headCenter = data.keyPoints.first { $0.label.contains("Head") }?.position ?? 
                        CGPoint(x: data.boundingBox.midX, y: data.boundingBox.midY)
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Start by drawing a circle for the basic head shape. This forms the foundation of your portrait.",
            shapes: shapes,
            targetPoints: [headCenter],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    private func createFaceGuidelinesGuide(from data: ProportionData) -> DrawingGuide {
        let guidelineElements = data.constructionElements.filter { element in
            element.description.contains("guideline") || element.type == .line
        }
        
        let shapes = guidelineElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let guidelinePoints = data.keyPoints.filter { $0.type == .guideline }.map { $0.position }
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Add horizontal guidelines for the eyes, nose, and mouth. These help ensure proper facial proportions.",
            shapes: shapes,
            targetPoints: guidelinePoints,
            tolerance: 15.0,
            category: data.category
        )
    }
    
    private func createEyePlacementGuide(from data: ProportionData) -> DrawingGuide {
        let eyeElements = data.constructionElements.filter { element in
            element.description.contains("eye") || element.description.contains("Eye")
        }
        
        let shapes = eyeElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let eyePoints = data.keyPoints.filter { $0.label.contains("Eye") }.map { $0.position }
        
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Draw the eyes using almond shapes. Position them along the eye guideline with proper spacing.",
            shapes: shapes,
            targetPoints: eyePoints,
            tolerance: 12.0,
            category: data.category
        )
    }
    
    private func createNoseConstructionGuide(from data: ProportionData) -> DrawingGuide {
        let noseElements = data.constructionElements.filter { element in
            element.description.contains("nose") || element.description.contains("Nose")
        }
        
        let shapes = noseElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let nosePoints = data.keyPoints.filter { $0.label.contains("Nose") }.map { $0.position }
        
        return DrawingGuide(
            stepNumber: 4,
            instruction: "Construct the nose using a simple triangular shape. Start with basic geometry, then refine.",
            shapes: shapes,
            targetPoints: nosePoints,
            tolerance: 15.0,
            category: data.category
        )
    }
    
    private func createMouthPlacementGuide(from data: ProportionData) -> DrawingGuide {
        let mouthElements = data.constructionElements.filter { element in
            element.description.contains("mouth") || element.description.contains("Mouth")
        }
        
        let shapes = mouthElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let mouthPoints = data.keyPoints.filter { $0.label.contains("Mouth") }.map { $0.position }
        
        return DrawingGuide(
            stepNumber: 5,
            instruction: "Add the mouth using an oval shape. Pay attention to its width relative to the eyes above.",
            shapes: shapes,
            targetPoints: mouthPoints,
            tolerance: 12.0,
            category: data.category
        )
    }
    
    private func createFaceOutlineGuide(from data: ProportionData) -> DrawingGuide {
        let outlineElements = data.constructionElements.filter { element in
            element.description.contains("outline") || element.description.contains("oval")
        }
        
        let shapes = outlineElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 6,
            instruction: "Refine the face outline by connecting the features with smooth curves. Erase construction lines.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    // MARK: - Animal Guides
    private func generateAnimalGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Step 1: Body construction
        guides.append(createAnimalBodyGuide(from: data))
        
        // Step 2: Head placement
        guides.append(createAnimalHeadGuide(from: data))
        
        // Step 3: Limb construction
        guides.append(createAnimalLimbsGuide(from: data))
        
        // Step 4: Feature details
        guides.append(createAnimalFeaturesGuide(from: data))
        
        return guides
    }
    
    private func createAnimalBodyGuide(from data: ProportionData) -> DrawingGuide {
        let bodyElements = data.constructionElements.filter { element in
            element.description.contains("body") || element.description.contains("Body")
        }
        
        let shapes = bodyElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let bodyCenter = data.keyPoints.first { $0.label.contains("Body") }?.position ??
                        CGPoint(x: data.boundingBox.midX, y: data.boundingBox.midY)
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Start with the main body shape using an oval. This establishes the animal's core mass.",
            shapes: shapes,
            targetPoints: [bodyCenter],
            tolerance: 25.0,
            category: data.category
        )
    }
    
    private func createAnimalHeadGuide(from data: ProportionData) -> DrawingGuide {
        let headElements = data.constructionElements.filter { element in
            element.description.contains("head") || element.description.contains("Head")
        }
        
        let shapes = headElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let headPosition = data.keyPoints.first { $0.label.contains("Head") }?.position ??
                          CGPoint(x: data.boundingBox.midX, y: data.boundingBox.minY + data.boundingBox.height * 0.3)
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Add the head using a circle or oval. Consider the animal's proportions relative to the body.",
            shapes: shapes,
            targetPoints: [headPosition],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    private func createAnimalLimbsGuide(from data: ProportionData) -> DrawingGuide {
        // Create simple limb guides
        let limbShapes = createBasicLimbShapes(for: data.boundingBox)
        
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Sketch the basic limb structure using simple lines and ovals for joints.",
            shapes: limbShapes,
            targetPoints: [],
            tolerance: 30.0,
            category: data.category
        )
    }
    
    private func createAnimalFeaturesGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 4,
            instruction: "Add facial features and details like ears, eyes, and distinctive characteristics.",
            shapes: [],
            targetPoints: [],
            tolerance: 15.0,
            category: data.category
        )
    }
    
    // MARK: - Hand Guides
    private func generateHandGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        guides.append(createPalmConstructionGuide(from: data))
        guides.append(createFingerGuidelinesGuide(from: data))
        guides.append(createFingerShapesGuide(from: data))
        guides.append(createHandRefinementGuide(from: data))
        
        return guides
    }
    
    private func createPalmConstructionGuide(from data: ProportionData) -> DrawingGuide {
        let palmElements = data.constructionElements.filter { element in
            element.description.contains("palm") || element.description.contains("Palm")
        }
        
        let shapes = palmElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let palmCenter = data.keyPoints.first { $0.label.contains("Palm") }?.position ??
                        CGPoint(x: data.boundingBox.midX, y: data.boundingBox.midY)
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Start with a rectangular shape for the palm. This forms the foundation of the hand.",
            shapes: shapes,
            targetPoints: [palmCenter],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    private func createFingerGuidelinesGuide(from data: ProportionData) -> DrawingGuide {
        let fingerElements = data.constructionElements.filter { element in
            element.description.contains("finger") || element.description.contains("Finger")
        }
        
        let shapes = fingerElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Add guidelines for finger length and positioning. Fingers have specific proportional relationships.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 25.0,
            category: data.category
        )
    }
    
    private func createFingerShapesGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Draw individual finger shapes using rectangles and ovals. Each finger has three segments.",
            shapes: [],
            targetPoints: [],
            tolerance: 15.0,
            category: data.category
        )
    }
    
    private func createHandRefinementGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 4,
            instruction: "Refine the hand outline, connect the fingers smoothly, and add thumb placement.",
            shapes: [],
            targetPoints: [],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    // MARK: - Object Guides
    private func generateObjectGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        guides.append(createBasicShapeGuide(from: data))
        guides.append(createProportionGuide(from: data))
        guides.append(createDetailGuide(from: data))
        
        return guides
    }
    
    private func createBasicShapeGuide(from data: ProportionData) -> DrawingGuide {
        let basicElements = data.constructionElements.filter { element in
            element.priority <= 2
        }
        
        let shapes = basicElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Begin with the basic geometric shape that defines the object's overall form.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 25.0,
            category: data.category
        )
    }
    
    private func createProportionGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Establish correct proportions and major divisions within the object.",
            shapes: [],
            targetPoints: [],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    private func createDetailGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Add details and refine the object's characteristics and surface features.",
            shapes: [],
            targetPoints: [],
            tolerance: 15.0,
            category: data.category
        )
    }
    
    // MARK: - Perspective Guides
    private func generatePerspectiveGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        guides.append(createHorizonLineGuide(from: data))
        guides.append(createVanishingPointGuide(from: data))
        guides.append(createPerspectiveLinesGuide(from: data))
        guides.append(createDepthConstructionGuide(from: data))
        
        return guides
    }
    
    private func createHorizonLineGuide(from data: ProportionData) -> DrawingGuide {
        let horizonElements = data.constructionElements.filter { element in
            element.description.contains("horizon") || element.description.contains("Horizon")
        }
        
        let shapes = horizonElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Draw the horizon line across your canvas. This represents your eye level.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 10.0,
            category: data.category
        )
    }
    
    private func createVanishingPointGuide(from data: ProportionData) -> DrawingGuide {
        let vpElements = data.constructionElements.filter { element in
            element.description.contains("vanishing") || element.description.contains("Vanishing")
        }
        
        let shapes = vpElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let vpPoint = data.keyPoints.first { $0.label.contains("Vanishing") }?.position ??
                     CGPoint(x: data.boundingBox.midX, y: data.boundingBox.height * 0.4)
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Mark the vanishing point on the horizon line. All perspective lines will converge here.",
            shapes: shapes,
            targetPoints: [vpPoint],
            tolerance: 8.0,
            category: data.category
        )
    }
    
    private func createPerspectiveLinesGuide(from data: ProportionData) -> DrawingGuide {
        let perspectiveElements = data.constructionElements.filter { element in
            element.description.contains("perspective") || element.description.contains("guideline")
        }
        
        let shapes = perspectiveElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Draw perspective guidelines from the vanishing point to establish depth and form.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 15.0,
            category: data.category
        )
    }
    
    private func createDepthConstructionGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 4,
            instruction: "Construct your objects within the perspective framework, maintaining proper depth relationships.",
            shapes: [],
            targetPoints: [],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    // MARK: - Nature Guides
    private func generateNatureGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        guides.append(createNatureCenterGuide(from: data))
        guides.append(createGoldenRatioGuide(from: data))
        guides.append(createOrganicShapeGuide(from: data))
        guides.append(createNatureDetailGuide(from: data))
        
        return guides
    }
    
    private func createNatureCenterGuide(from data: ProportionData) -> DrawingGuide {
        let centerElements = data.constructionElements.filter { element in
            element.priority == 1
        }
        
        let shapes = centerElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let center = data.keyPoints.first { $0.label.contains("Center") }?.position ??
                    CGPoint(x: data.boundingBox.midX, y: data.boundingBox.midY)
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: "Establish the central structure using a circle. This anchors your natural form.",
            shapes: shapes,
            targetPoints: [center],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    private func createGoldenRatioGuide(from data: ProportionData) -> DrawingGuide {
        let goldenElements = data.constructionElements.filter { element in
            element.description.contains("golden") || element.description.contains("ratio")
        }
        
        let shapes = goldenElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: "Apply golden ratio proportions to create natural, pleasing divisions in your composition.",
            shapes: shapes,
            targetPoints: [],
            tolerance: 25.0,
            category: data.category
        )
    }
    
    private func createOrganicShapeGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 3,
            instruction: "Build organic shapes using curved lines and natural forms. Avoid rigid geometric shapes.",
            shapes: [],
            targetPoints: [],
            tolerance: 30.0,
            category: data.category
        )
    }
    
    private func createNatureDetailGuide(from data: ProportionData) -> DrawingGuide {
        return DrawingGuide(
            stepNumber: 4,
            instruction: "Add natural details like texture, patterns, and surface variations found in nature.",
            shapes: [],
            targetPoints: [],
            tolerance: 20.0,
            category: data.category
        )
    }
    
    // MARK: - Lesson to Tutorial Integration
    
    /// Convert a Lesson to DrawingGuides for tutorial system
    func generateGuidesFromLesson(_ lesson: Lesson) -> [DrawingGuide] {
        print("🎯 [TUTORIAL] Generating guides from lesson: \(lesson.title)")
        print("🎯 [TUTORIAL] Lesson has \(lesson.steps.count) steps")
        
        var guides: [DrawingGuide] = []
        
        for (index, step) in lesson.steps.enumerated() {
            let guide = createDrawingGuideFromLessonStep(step, stepIndex: index, lesson: lesson)
            guides.append(guide)
            print("🎯 [TUTORIAL] Created guide for step \(index + 1): \(step.instruction)")
        }
        
        print("🎯 [TUTORIAL] Generated \(guides.count) guides for lesson")
        return guides
    }
    
    private func createDrawingGuideFromLessonStep(_ step: LessonStep, stepIndex: Int, lesson: Lesson) -> DrawingGuide {
        // Create basic guide shapes based on step shape type
        let guideShapes = createGuideShapesForStep(step, lesson: lesson)
        
        return DrawingGuide(
            stepNumber: step.stepNumber,
            instruction: step.instruction,
            shapes: guideShapes,
            targetPoints: step.guidancePoints,
            tolerance: getToleranceForDifficulty(lesson.difficulty),
            category: lesson.category
        )
    }
    
    private func createGuideShapesForStep(_ step: LessonStep, lesson: Lesson) -> [GuideShape] {
        let canvasSize = CGSize(width: 400, height: 400)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        
        switch step.shapeType {
        case .circle:
            return [createCircleGuide(center: center, radius: 80, lesson: lesson)]
        case .oval:
            return [createOvalGuide(center: center, size: CGSize(width: 120, height: 80), lesson: lesson)]
        case .rectangle:
            return [createRectangleGuide(center: center, size: CGSize(width: 100, height: 80), lesson: lesson)]
        case .line:
            return [createLineGuide(start: CGPoint(x: center.x - 60, y: center.y), 
                                  end: CGPoint(x: center.x + 60, y: center.y), lesson: lesson)]
        case .curve:
            return [createCurveGuide(center: center, lesson: lesson)]
        case .polygon:
            return [createPolygonGuide(center: center, lesson: lesson)]
        }
    }
    
    private func createCircleGuide(center: CGPoint, radius: CGFloat, lesson: Lesson) -> GuideShape {
        let points = generateCirclePoints(center: center, radius: radius, pointCount: 32)
        return GuideShape(
            type: .circle,
            points: points,
            center: center,
            dimensions: CGSize(width: radius * 2, height: radius * 2),
            rotation: 0.0,
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func createOvalGuide(center: CGPoint, size: CGSize, lesson: Lesson) -> GuideShape {
        let points = generateOvalPoints(center: center, size: size, pointCount: 32)
        return GuideShape(
            type: .oval,
            points: points,
            center: center,
            dimensions: size,
            rotation: 0.0,
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func createRectangleGuide(center: CGPoint, size: CGSize, lesson: Lesson) -> GuideShape {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        let points = [
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y - halfHeight),
            CGPoint(x: center.x + halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y + halfHeight),
            CGPoint(x: center.x - halfWidth, y: center.y - halfHeight)
        ]
        return GuideShape(
            type: .rectangle,
            points: points,
            center: center,
            dimensions: size,
            rotation: 0.0,
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func createLineGuide(start: CGPoint, end: CGPoint, lesson: Lesson) -> GuideShape {
        let points = [start, end]
        let center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let distance = sqrt(pow(end.x - start.x, 2) + pow(end.y - start.y, 2))
        return GuideShape(
            type: .line,
            points: points,
            center: center,
            dimensions: CGSize(width: distance, height: 2),
            rotation: atan2(end.y - start.y, end.x - start.x),
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func createCurveGuide(center: CGPoint, lesson: Lesson) -> GuideShape {
        let points = generateCurvePoints(center: center, pointCount: 20)
        return GuideShape(
            type: .curve,
            points: points,
            center: center,
            dimensions: CGSize(width: 100, height: 60),
            rotation: 0.0,
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func createPolygonGuide(center: CGPoint, lesson: Lesson) -> GuideShape {
        let points = generatePolygonPoints(center: center, sides: 6, radius: 60)
        return GuideShape(
            type: .polygon,
            points: points,
            center: center,
            dimensions: CGSize(width: 120, height: 120),
            rotation: 0.0,
            strokeWidth: 2.0,
            color: lesson.category.color,
            style: .dashed(pattern: [5, 3])
        )
    }
    
    private func getToleranceForDifficulty(_ difficulty: DifficultyLevel) -> CGFloat {
        switch difficulty {
        case .beginner:
            return 30.0 // More forgiving
        case .intermediate:
            return 20.0 // Standard
        case .advanced:
            return 10.0 // More precise
        }
    }
    
    // MARK: - Helper Methods for Shape Generation
    
    private func generateCirclePoints(center: CGPoint, radius: CGFloat, pointCount: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = 2 * CGFloat.pi / CGFloat(pointCount)
        
        for i in 0..<pointCount {
            let angle = CGFloat(i) * angleStep
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func generateOvalPoints(center: CGPoint, size: CGSize, pointCount: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = 2 * CGFloat.pi / CGFloat(pointCount)
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2
        
        for i in 0..<pointCount {
            let angle = CGFloat(i) * angleStep
            let x = center.x + halfWidth * cos(angle)
            let y = center.y + halfHeight * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func generateCurvePoints(center: CGPoint, pointCount: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        let width: CGFloat = 100
        let height: CGFloat = 60
        
        for i in 0..<pointCount {
            let t = CGFloat(i) / CGFloat(pointCount - 1)
            let x = center.x - width/2 + t * width
            let y = center.y + height * sin(t * CGFloat.pi)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    private func generatePolygonPoints(center: CGPoint, sides: Int, radius: CGFloat) -> [CGPoint] {
        var points: [CGPoint] = []
        let angleStep = 2 * CGFloat.pi / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = CGFloat(i) * angleStep - CGFloat.pi / 2 // Start from top
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
    }
    
    // MARK: - Helper Methods
    
    private func convertProportionElementToGuideShape(_ element: ProportionElement) -> GuideShape {
        let strokeStyle: GuideShape.StrokeStyle
        
        switch element.style {
        case .solid:
            strokeStyle = .solid
        case .dashed(let pattern):
            strokeStyle = .dashed(pattern: pattern)
        case .dotted:
            strokeStyle = .dotted
        }
        
        return GuideShape(
            type: convertElementTypeToShapeType(element.type),
            points: element.points,
            center: element.points.first ?? CGPoint.zero,
            dimensions: element.dimensions,
            rotation: 0.0,
            strokeWidth: element.strokeWidth,
            color: element.color,
            style: strokeStyle
        )
    }
    
    private func convertElementTypeToShapeType(_ elementType: ProportionElement.ElementType) -> ShapeType {
        switch elementType {
        case .circle:
            return .circle
        case .oval:
            return .oval
        case .rectangle:
            return .rectangle
        case .line:
            return .line
        case .curve:
            return .curve
        case .triangle:
            return .polygon
        case .polygon:
            return .polygon
        }
    }
    
    private func createBasicLimbShapes(for bounds: CGRect) -> [GuideShape] {
        let limbWidth = bounds.width * 0.1
        let limbHeight = bounds.height * 0.3
        
        return [
            // Front legs
            GuideShape(
                type: .rectangle,
                points: [CGPoint(x: bounds.midX - bounds.width * 0.2, y: bounds.maxY - limbHeight)],
                center: CGPoint(x: bounds.midX - bounds.width * 0.2, y: bounds.maxY - limbHeight/2),
                dimensions: CGSize(width: limbWidth, height: limbHeight),
                rotation: 0.0,
                strokeWidth: 1.5,
                color: .gray,
                style: .dashed(pattern: [3, 2])
            ),
            
            GuideShape(
                type: .rectangle,
                points: [CGPoint(x: bounds.midX + bounds.width * 0.2, y: bounds.maxY - limbHeight)],
                center: CGPoint(x: bounds.midX + bounds.width * 0.2, y: bounds.maxY - limbHeight/2),
                dimensions: CGSize(width: limbWidth, height: limbHeight),
                rotation: 0.0,
                strokeWidth: 1.5,
                color: .gray,
                style: .dashed(pattern: [3, 2])
            )
        ]
    }
}

