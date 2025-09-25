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
    
    // MARK: - Enhanced Face Guides with AI-Powered Analysis
    private func generateFaceGuides(from data: ProportionData) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // ENHANCED: AI-powered face analysis for more sophisticated guides
        let faceAnalysis = analyzeFaceComplexity(from: data)
        
        // Step 1: Advanced head construction with Loomis method
        guides.append(createAdvancedHeadConstructionGuide(from: data, analysis: faceAnalysis))
        
        // Step 2: Sophisticated facial guidelines
        guides.append(createAdvancedFaceGuidelinesGuide(from: data, analysis: faceAnalysis))
        
        // Step 3: Precise eye placement with anatomy
        guides.append(createAdvancedEyePlacementGuide(from: data, analysis: faceAnalysis))
        
        // Step 4: Anatomical nose construction
        guides.append(createAdvancedNoseConstructionGuide(from: data, analysis: faceAnalysis))
        
        // Step 5: Dynamic mouth placement
        guides.append(createAdvancedMouthPlacementGuide(from: data, analysis: faceAnalysis))
        
        // Step 6: Advanced facial features
        guides.append(createAdvancedFacialFeaturesGuide(from: data, analysis: faceAnalysis))
        
        // Step 7: Final refinement with artistic interpretation
        guides.append(createAdvancedFaceRefinementGuide(from: data, analysis: faceAnalysis))
        
        return guides
    }
    
    // MARK: - Content-Specific Template System
    
    /// Generate content-specific guide templates based on detected features
    func generateContentSpecificGuides(from analysis: VisionAnalysisResult, category: LessonCategory) -> [DrawingGuide] {
        let complexity = analyzeContentComplexity(from: analysis)
        let variations = generateContentVariations(from: analysis)
        
        switch category {
        case .faces:
            return generateFaceTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        case .objects:
            return generateObjectTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        case .perspective:
            return generatePerspectiveTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        case .animals:
            return generateAnimalTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        case .hands:
            return generateHandTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        case .nature:
            return generateNatureTemplateGuides(from: analysis, complexity: complexity, variations: variations)
        }
    }
    
    /// Generate face template guides with anatomical accuracy
    private func generateFaceTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Loomis Method Head Construction
        guides.append(createLoomisHeadConstructionGuide(complexity: complexity))
        
        // Template 2: Facial Proportion Guidelines
        guides.append(createFacialProportionGuide(complexity: complexity))
        
        // Template 3: Eye Anatomy Template
        guides.append(createEyeAnatomyTemplate(complexity: complexity))
        
        // Template 4: Nose Construction Template
        guides.append(createNoseConstructionTemplate(complexity: complexity))
        
        // Template 5: Mouth and Expression Template
        guides.append(createMouthExpressionTemplate(complexity: complexity))
        
        // Template 6: Hair and Texture Template
        guides.append(createHairTextureTemplate(complexity: complexity))
        
        return guides
    }
    
    /// Generate object template guides with form analysis
    private func generateObjectTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Basic Geometric Forms
        guides.append(createGeometricFormsTemplate(complexity: complexity))
        
        // Template 2: Light and Shadow Analysis
        guides.append(createLightShadowTemplate(complexity: complexity))
        
        // Template 3: Material Properties Template
        guides.append(createMaterialPropertiesTemplate(complexity: complexity))
        
        // Template 4: Composition and Balance
        guides.append(createCompositionBalanceTemplate(complexity: complexity))
        
        return guides
    }
    
    /// Generate perspective template guides with architectural elements
    private func generatePerspectiveTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Horizon Line and Eye Level
        guides.append(createHorizonLineTemplate(complexity: complexity))
        
        // Template 2: Vanishing Points System
        guides.append(createVanishingPointsTemplate(complexity: complexity))
        
        // Template 3: Ground Plane Construction
        guides.append(createGroundPlaneTemplate(complexity: complexity))
        
        // Template 4: Architectural Elements
        guides.append(createArchitecturalElementsTemplate(complexity: complexity))
        
        return guides
    }
    
    /// Generate animal template guides with anatomical focus
    private func generateAnimalTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Basic Body Structure
        guides.append(createAnimalBodyTemplate(complexity: complexity))
        
        // Template 2: Head and Facial Features
        guides.append(createAnimalHeadTemplate(complexity: complexity))
        
        // Template 3: Limb Construction
        guides.append(createAnimalLimbTemplate(complexity: complexity))
        
        // Template 4: Fur and Texture
        guides.append(createAnimalTextureTemplate(complexity: complexity))
        
        return guides
    }
    
    /// Generate hand template guides with anatomical accuracy
    private func generateHandTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Palm Construction
        guides.append(createPalmConstructionTemplate(complexity: complexity))
        
        // Template 2: Finger Anatomy
        guides.append(createFingerAnatomyTemplate(complexity: complexity))
        
        // Template 3: Thumb Placement
        guides.append(createThumbPlacementTemplate(complexity: complexity))
        
        // Template 4: Gesture and Expression
        guides.append(createHandGestureTemplate(complexity: complexity))
        
        return guides
    }
    
    /// Generate nature template guides with organic forms
    private func generateNatureTemplateGuides(from analysis: VisionAnalysisResult, complexity: ContentComplexity, variations: [ContentVariation]) -> [DrawingGuide] {
        var guides: [DrawingGuide] = []
        
        // Template 1: Organic Shape Construction
        guides.append(createOrganicShapeTemplate(complexity: complexity))
        
        // Template 2: Golden Ratio Proportions
        guides.append(createGoldenRatioTemplate(complexity: complexity))
        
        // Template 3: Natural Texture Patterns
        guides.append(createNaturalTextureTemplate(complexity: complexity))
        
        // Template 4: Atmospheric Perspective
        guides.append(createAtmosphericPerspectiveTemplate(complexity: complexity))
        
        return guides
    }
    
    // MARK: - Enhanced Face Analysis
    
    private func analyzeFaceComplexity(from data: ProportionData) -> FaceAnalysisResult {
        let faceCount = data.keyPoints.filter { $0.label.contains("Face") || $0.label.contains("Eye") || $0.label.contains("Nose") || $0.label.contains("Mouth") }.count
        let hasMultipleFaces = faceCount > 4
        let hasComplexFeatures = data.constructionElements.filter { $0.priority <= 2 }.count > 5
        
        return FaceAnalysisResult(
            faceCount: hasMultipleFaces ? 2 : 1,
            complexity: hasComplexFeatures ? .high : .medium,
            hasProfileView: data.keyPoints.contains { $0.label.contains("Profile") },
            hasThreeQuarterView: data.keyPoints.contains { $0.label.contains("ThreeQuarter") }
        )
    }
    
    // MARK: - Advanced Guide Creation Methods
    
    private func createAdvancedHeadConstructionGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        let headConstructionElements = data.constructionElements.filter { element in
            element.description.contains("head") || element.description.contains("sphere")
        }
        
        let shapes = headConstructionElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let headCenter = data.keyPoints.first { $0.label.contains("Head") }?.position ?? 
                        CGPoint(x: data.boundingBox.midX, y: data.boundingBox.midY)
        
        // ENHANCED: Adaptive instruction based on analysis
        let instruction = analysis.complexity == .high ? 
            "Start with the Loomis method - draw a sphere for the skull, then add the jaw structure. This advanced technique provides a solid foundation for realistic proportions." :
            "Begin with a circle for the basic head shape. This forms the foundation of your portrait."
        
        return DrawingGuide(
            stepNumber: 1,
            instruction: instruction,
            shapes: shapes,
            targetPoints: [headCenter],
            tolerance: analysis.complexity == .high ? 15.0 : 20.0,
            category: data.category
        )
    }
    
    private func createAdvancedFaceGuidelinesGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        let guidelineElements = data.constructionElements.filter { element in
            element.description.contains("guideline") || element.type == .line
        }
        
        let shapes = guidelineElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let guidelinePoints = data.keyPoints.filter { $0.type == .guideline }.map { $0.position }
        
        // ENHANCED: Sophisticated facial guidelines
        let instruction = analysis.complexity == .high ?
            "Add sophisticated facial guidelines - eye line, nose line, and mouth line. These anatomical landmarks ensure proper facial proportions and realistic placement." :
            "Add horizontal guidelines for the eyes, nose, and mouth. These help ensure proper facial proportions."
        
        return DrawingGuide(
            stepNumber: 2,
            instruction: instruction,
            shapes: shapes,
            targetPoints: guidelinePoints,
            tolerance: analysis.complexity == .high ? 12.0 : 15.0,
            category: data.category
        )
    }
    
    private func createAdvancedEyePlacementGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        let eyeElements = data.constructionElements.filter { element in
            element.description.contains("eye") || element.description.contains("Eye")
        }
        
        let shapes = eyeElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let eyePoints = data.keyPoints.filter { $0.label.contains("Eye") }.map { $0.position }
        
        // ENHANCED: Anatomical eye placement
        let instruction = analysis.complexity == .high ?
            "Place the eyes using anatomical proportions - they should be one eye-width apart. Draw almond shapes with proper iris and pupil placement." :
            "Draw the eyes using almond shapes. Position them along the eye guideline with proper spacing."
        
        return DrawingGuide(
            stepNumber: 3,
            instruction: instruction,
            shapes: shapes,
            targetPoints: eyePoints,
            tolerance: analysis.complexity == .high ? 10.0 : 12.0,
            category: data.category
        )
    }
    
    private func createAdvancedNoseConstructionGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        let noseElements = data.constructionElements.filter { element in
            element.description.contains("nose") || element.description.contains("Nose")
        }
        
        let shapes = noseElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let nosePoints = data.keyPoints.filter { $0.label.contains("Nose") }.map { $0.position }
        
        // ENHANCED: Anatomical nose construction
        let instruction = analysis.complexity == .high ?
            "Construct the nose using anatomical planes - bridge, nostrils, and tip. Focus on the three-dimensional structure and shadow placement." :
            "Construct the nose using a simple triangular shape. Start with basic geometry, then refine."
        
        return DrawingGuide(
            stepNumber: 4,
            instruction: instruction,
            shapes: shapes,
            targetPoints: nosePoints,
            tolerance: analysis.complexity == .high ? 12.0 : 15.0,
            category: data.category
        )
    }
    
    private func createAdvancedMouthPlacementGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        let mouthElements = data.constructionElements.filter { element in
            element.description.contains("mouth") || element.description.contains("Mouth")
        }
        
        let shapes = mouthElements.map { element in
            convertProportionElementToGuideShape(element)
        }
        
        let mouthPoints = data.keyPoints.filter { $0.label.contains("Mouth") }.map { $0.position }
        
        // ENHANCED: Dynamic mouth placement
        let instruction = analysis.complexity == .high ?
            "Place the mouth with attention to lip anatomy - upper lip, lower lip, and the philtrum. Consider the expression and mood." :
            "Add the mouth using an oval shape. Pay attention to its width relative to the eyes above."
        
        return DrawingGuide(
            stepNumber: 5,
            instruction: instruction,
            shapes: shapes,
            targetPoints: mouthPoints,
            tolerance: analysis.complexity == .high ? 10.0 : 12.0,
            category: data.category
        )
    }
    
    private func createAdvancedFacialFeaturesGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        // ENHANCED: Advanced facial features
        let instruction = analysis.complexity == .high ?
            "Add sophisticated facial features - eyebrows, ears, and facial hair. Focus on the unique characteristics that make this face distinctive." :
            "Add eyebrows and refine facial features"
        
        return DrawingGuide(
            stepNumber: 6,
            instruction: instruction,
            shapes: [],
            targetPoints: [],
            tolerance: analysis.complexity == .high ? 15.0 : 20.0,
            category: data.category
        )
    }
    
    private func createAdvancedFaceRefinementGuide(from data: ProportionData, analysis: FaceAnalysisResult) -> DrawingGuide {
        // ENHANCED: Final refinement with artistic interpretation
        let instruction = analysis.complexity == .high ?
            "Final refinement with artistic interpretation - add shading, highlights, and personal style. This is where your artistic voice emerges." :
            "Refine the face outline by connecting the features with smooth curves. Erase construction lines."
        
        return DrawingGuide(
            stepNumber: 7,
            instruction: instruction,
            shapes: [],
            targetPoints: [],
            tolerance: analysis.complexity == .high ? 20.0 : 25.0,
            category: data.category
        )
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
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

// MARK: - Enhanced Analysis Data Structures

struct FaceAnalysisResult {
    let faceCount: Int
    let complexity: FaceComplexity
    let hasProfileView: Bool
    let hasThreeQuarterView: Bool
}

enum FaceComplexity {
    case low
    case medium
    case high
}

struct ContentSpecificGuide {
    let type: GuideType
    let shapes: [GuideShape]
    let instruction: String
    let tolerance: CGFloat
    let adaptiveFeatures: [AdaptiveFeature]
}

enum GuideType {
    case anatomical
    case artistic
    case technical
    case expressive
}

struct AdaptiveFeature {
    let name: String
    let description: String
    let difficulty: DifficultyLevel
    let isOptional: Bool
}

// MARK: - Content Analysis Data Structures

enum ContentComplexity {
    case simple
    case moderate
    case complex
}

struct ContentVariation {
    let type: ContentVariationType
    let title: String
    let description: String
    let difficulty: DifficultyLevel
    let estimatedTime: Int
}

enum ContentVariationType {
    case basic
    case intermediate
    case advanced
    case expert
}

// MARK: - Template Creation Methods

/// Analyze content complexity from vision analysis
private func analyzeContentComplexity(from analysis: VisionAnalysisResult) -> ContentComplexity {
    var complexityScore: Double = 0.0
    
    // Face complexity
    if !analysis.faces.isEmpty {
        complexityScore += Double(analysis.faces.count) * 0.3
        if analysis.faces.count > 1 {
            complexityScore += 0.2
        }
    }
    
    // Object complexity
    if !analysis.objects.isEmpty {
        complexityScore += Double(analysis.objects.count) * 0.2
    }
    
    // Text complexity
    if !analysis.text.isEmpty {
        let totalTextLength = analysis.text.map { $0.text.count }.reduce(0, +)
        complexityScore += min(Double(totalTextLength) * 0.01, 0.3)
    }
    
    // Rectangle/perspective complexity
    if !analysis.rectangles.isEmpty {
        complexityScore += Double(analysis.rectangles.count) * 0.25
    }
    
    if complexityScore < 0.5 {
        return .simple
    } else if complexityScore < 1.0 {
        return .moderate
    } else {
        return .complex
    }
}

/// Generate content variations based on analysis
private func generateContentVariations(from analysis: VisionAnalysisResult) -> [ContentVariation] {
    var variations: [ContentVariation] = []
    
    // Face variations
    if !analysis.faces.isEmpty {
        variations.append(ContentVariation(
            type: .basic,
            title: "Basic Portrait",
            description: "Simple portrait drawing with basic proportions",
            difficulty: .beginner,
            estimatedTime: 20
        ))
        
        if analysis.faces.count > 1 {
            variations.append(ContentVariation(
                type: .advanced,
                title: "Group Portrait",
                description: "Multiple faces with composition focus",
                difficulty: .advanced,
                estimatedTime: 45
            ))
        }
    }
    
    // Object variations
    if !analysis.objects.isEmpty {
        variations.append(ContentVariation(
            type: .intermediate,
            title: "Still Life Study",
            description: "Focus on form, light, and composition",
            difficulty: .intermediate,
            estimatedTime: 30
        ))
    }
    
    return variations
}

// MARK: - Template Creation Methods

/// Create Loomis head construction template
private func createLoomisHeadConstructionGuide(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Begin with the Loomis method - draw a sphere for the skull, then add the jaw structure. This advanced technique provides a solid foundation for realistic proportions." :
        "Start with a circle for the basic head shape. This forms the foundation of your portrait."
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .faces
    )
}

/// Create facial proportion guide template
private func createFacialProportionGuide(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add sophisticated facial guidelines - eye line, nose line, and mouth line. These anatomical landmarks ensure proper facial proportions and realistic placement." :
        "Add horizontal guidelines for the eyes, nose, and mouth. These help ensure proper facial proportions."
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .faces
    )
}

/// Create eye anatomy template
private func createEyeAnatomyTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Place the eyes using anatomical proportions - they should be one eye-width apart. Draw almond shapes with proper iris and pupil placement." :
        "Draw the eyes using almond shapes. Position them along the eye guideline with proper spacing."
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .faces
    )
}

/// Create nose construction template
private func createNoseConstructionTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Construct the nose using anatomical planes - bridge, nostrils, and tip. Focus on the three-dimensional structure and shadow placement." :
        "Construct the nose using a simple triangular shape. Start with basic geometry, then refine."
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .faces
    )
}

/// Create mouth expression template
private func createMouthExpressionTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Place the mouth with attention to lip anatomy - upper lip, lower lip, and the philtrum. Consider the expression and mood." :
        "Add the mouth using an oval shape. Pay attention to its width relative to the eyes above."
    
    return DrawingGuide(
        stepNumber: 5,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .faces
    )
}

/// Create hair texture template
private func createHairTextureTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add sophisticated facial features - eyebrows, ears, and facial hair. Focus on the unique characteristics that make this face distinctive." :
        "Add eyebrows and refine facial features"
    
    return DrawingGuide(
        stepNumber: 6,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .faces
    )
}

/// Create geometric forms template
private func createGeometricFormsTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Start with advanced geometric construction - use ellipses for cylinders, boxes for rectangular forms, and spheres for round objects. This creates a solid foundation." :
        "Start with basic geometric shapes - circles, rectangles, and ovals"
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .objects
    )
}

/// Create light and shadow template
private func createLightShadowTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Identify and draw the light source and shadow patterns. Consider cast shadows, form shadows, and reflected light for realistic depth." :
        "Identify and draw the light source and shadows"
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .objects
    )
}

/// Create material properties template
private func createMaterialPropertiesTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add surface textures and material properties - consider how different materials reflect light and create visual interest." :
        "Add surface textures and material properties"
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .objects
    )
}

/// Create composition balance template
private func createCompositionBalanceTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Refine details and create depth through value changes, atmospheric perspective, and careful attention to edges and transitions." :
        "Refine details and create depth through value changes"
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .objects
    )
}

/// Create horizon line template
private func createHorizonLineTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Establish the horizon line and your eye level. Consider how this affects the viewer's perspective and the overall composition." :
        "Draw the horizon line across your canvas. This represents your eye level."
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 8.0 : 10.0,
        category: .perspective
    )
}

/// Create vanishing points template
private func createVanishingPointsTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Locate the vanishing point(s) on the horizon. For complex scenes, identify one-point, two-point, or three-point perspective systems." :
        "Mark the vanishing point on the horizon line. All perspective lines will converge here."
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 6.0 : 8.0,
        category: .perspective
    )
}

/// Create ground plane template
private func createGroundPlaneTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Draw the ground plane and establish depth using perspective guidelines. Consider how objects diminish in size as they recede." :
        "Draw the ground plane and establish depth"
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .perspective
    )
}

/// Create architectural elements template
private func createArchitecturalElementsTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add details and architectural elements while maintaining proper perspective. Consider windows, doors, and decorative features." :
        "Add details and architectural elements"
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .perspective
    )
}

/// Create animal body template
private func createAnimalBodyTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Start with the main body structure using an oval. Consider the animal's natural posture and weight distribution." :
        "Start with the main body shape using an oval. This establishes the animal's core mass."
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .animals
    )
}

/// Create animal head template
private func createAnimalHeadTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add the head using a circle or oval. Consider the animal's proportions relative to the body and its characteristic features." :
        "Add the head using a circle or oval. Consider the animal's proportions relative to the body."
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .animals
    )
}

/// Create animal limb template
private func createAnimalLimbTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Sketch the basic limb structure using simple lines and ovals for joints. Pay attention to the animal's natural stance and movement." :
        "Sketch the basic limb structure using simple lines and ovals for joints."
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .animals
    )
}

/// Create animal texture template
private func createAnimalTextureTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add body details and consider the animal's fur, scales, or skin texture. This brings the drawing to life." :
        "Add body details and consider the animal's fur or skin texture."
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .animals
    )
}

/// Create palm construction template
private func createPalmConstructionTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Start with a rectangular shape for the palm. Consider the hand's natural curve and the relationship between palm and fingers." :
        "Start with a rectangular shape for the palm. This forms the foundation of the hand."
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .hands
    )
}

/// Create finger anatomy template
private func createFingerAnatomyTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add guidelines for finger length and positioning. Fingers have specific proportional relationships and natural curves." :
        "Add guidelines for finger length and positioning. Fingers have specific proportional relationships."
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .hands
    )
}

/// Create thumb placement template
private func createThumbPlacementTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add thumb placement and consider its unique range of motion. The thumb is crucial for hand expression and gesture." :
        "Add thumb placement and consider its unique range of motion."
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 10.0 : 12.0,
        category: .hands
    )
}

/// Create hand gesture template
private func createHandGestureTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Refine the hand outline, connect the fingers smoothly, and add final details like knuckles and nail shapes." :
        "Refine the hand outline, connect the fingers smoothly, and add thumb placement."
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .hands
    )
}

/// Create organic shape template
private func createOrganicShapeTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Establish the central structure using a circle. Consider the natural growth patterns and the golden ratio in nature." :
        "Establish the central structure using a circle. This anchors your natural form."
    
    return DrawingGuide(
        stepNumber: 1,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .nature
    )
}

/// Create golden ratio template
private func createGoldenRatioTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Apply golden ratio proportions to create natural, pleasing divisions in your composition. Nature follows these mathematical principles." :
        "Apply golden ratio proportions to create natural, pleasing divisions in your composition."
    
    return DrawingGuide(
        stepNumber: 2,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .nature
    )
}

/// Create natural texture template
private func createNaturalTextureTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Build organic shapes using curved lines and natural forms. Avoid rigid geometric shapes and embrace the irregular beauty of nature." :
        "Build organic shapes using curved lines and natural forms. Avoid rigid geometric shapes."
    
    return DrawingGuide(
        stepNumber: 3,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 15.0 : 20.0,
        category: .nature
    )
}

/// Create atmospheric perspective template
private func createAtmosphericPerspectiveTemplate(complexity: ContentComplexity) -> DrawingGuide {
    let instruction = complexity == .complex ?
        "Add natural details like texture, patterns, and surface variations found in nature. Consider the unique characteristics of your subject." :
        "Add natural details like texture, patterns, and surface variations found in nature."
    
    return DrawingGuide(
        stepNumber: 4,
        instruction: instruction,
        shapes: [],
        targetPoints: [],
        tolerance: complexity == .complex ? 12.0 : 15.0,
        category: .nature
    )
}

