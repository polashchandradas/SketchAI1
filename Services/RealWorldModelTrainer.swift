import Foundation
import CreateML
import CoreML
import Vision
import UIKit

/// Service for training Core ML models with real human drawing data
/// This replaces synthetic "perfect" data with actual human imperfections
class RealWorldModelTrainer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var trainingProgress: Double = 0.0
    @Published var trainingStatus: TrainingStatus = .idle
    @Published var currentModel: MLModel?
    @Published var trainingMetrics: TrainingMetrics?
    
    // MARK: - Private Properties
    private let dataProcessor: DataProcessor
    private let realDataPipeline: RealDataPipelineManager
    private let modelTrainer: CoreMLModelTrainer
    
    // MARK: - Configuration
    private struct Config {
        static let minimumSamplesPerShape = 100 // Reduced from 500 for faster iteration
        static let maxTrainingIterations = 50 // Balanced for mobile training
        static let validationSplit: Double = 0.2
        static let augmentationMultiplier = 3 // 3x data augmentation
    }
    
    init() {
        self.dataProcessor = DataProcessor()
        self.realDataPipeline = RealDataPipelineManager(
            privacyManager: PrivacyCompliantDataCollectionManager(),
            encryptionService: DataEncryptionService(),
            consentManager: ConsentManager()
        )
        
        // Initialize model trainer with paths for base and updated models
        let baseModelURL = Bundle.main.url(forResource: "UpdatableDrawingClassifier", withExtension: "mlmodelc")!
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let updatedModelURL = documentsPath.appendingPathComponent("UpdatedDrawingClassifier.mlmodelc")
        
        self.modelTrainer = CoreMLModelTrainer(baseModelURL: baseModelURL, updatedModelURL: updatedModelURL)
    }
    
    // MARK: - Main Training Method
    
    /// Train a new Core ML model using real human drawing data
    func trainModelWithRealData() async throws {
        await MainActor.run {
            trainingStatus = .preparing
            trainingProgress = 0.0
        }
        
        do {
            // Step 1: Collect and prepare real training data
            print("🎯 Phase 2: Starting real data model training...")
            let trainingData = try await prepareRealTrainingData()
            
            await MainActor.run {
                trainingProgress = 0.3
            }
            
            // Step 2: Create enhanced dataset with augmentation
            let enhancedData = try await enhanceTrainingData(trainingData)
            
            await MainActor.run {
                trainingProgress = 0.5
            }
            
            // Step 3: Train the model
            let trainedModel = try await trainCoreMLModel(with: enhancedData)
            
            await MainActor.run {
                trainingProgress = 0.8
            }
            
            // Step 4: Validate and save
            let metrics = try await validateModel(trainedModel, with: enhancedData)
            
            await MainActor.run {
                currentModel = trainedModel
                trainingMetrics = metrics
                trainingProgress = 1.0
                trainingStatus = .completed
            }
            
            print("✅ Real data model training completed successfully!")
            print("📊 Final metrics: Accuracy: \(metrics.accuracy), Training samples: \(metrics.trainingDataCount)")
            
        } catch {
            await MainActor.run {
                trainingStatus = .failed
            }
            print("❌ Training failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Data Preparation
    
    private func prepareRealTrainingData() async throws -> [ProcessedDrawingData] {
        print("📂 Collecting real human drawing data...")
        
        // Try to load real user data first
        if let realData = try await loadRealUserData() {
            print("✅ Using \(realData.count) real human drawing samples")
            return realData
        }
        
        // Fallback: Create human-like synthetic data with imperfections
        print("⚠️ Real data insufficient, generating human-like synthetic data...")
        return try await generateHumanLikeSyntheticData()
    }
    
    private func loadRealUserData() async throws -> [ProcessedDrawingData]? {
        // Load real drawing data from our privacy-compliant pipeline
        let dataDirectory = getRealDataDirectory()
        let shapeTypes = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        
        var allData: [ProcessedDrawingData] = []
        var hasMinimumData = true
        
        for shapeType in shapeTypes {
            let shapeDirectory = dataDirectory.appendingPathComponent(shapeType)
            
            // Load processed drawing files for this shape
            guard let files = try? FileManager.default.contentsOfDirectory(at: shapeDirectory, includingPropertiesForKeys: nil),
                  files.count >= Config.minimumSamplesPerShape else {
                print("⚠️ Insufficient real data for \(shapeType): need \(Config.minimumSamplesPerShape)+ samples")
                hasMinimumData = false
                break
            }
            
            // Load and process each file
            for file in files.prefix(Config.minimumSamplesPerShape * 2) {
                if let data = try? Data(contentsOf: file),
                   let drawingData = try? JSONDecoder().decode(ProcessedDrawingData.self, from: data) {
                    allData.append(drawingData)
                }
            }
        }
        
        return hasMinimumData ? allData : nil
    }
    
    private func generateHumanLikeSyntheticData() async throws -> [ProcessedDrawingData] {
        print("🎨 Generating human-like synthetic data with imperfections...")
        
        var syntheticData: [ProcessedDrawingData] = []
        let shapeTypes = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        
        for shapeType in shapeTypes {
            for i in 0..<Config.minimumSamplesPerShape {
                // Generate human-like stroke data with imperfections
                let humanLikeStroke = generateHumanLikeStroke(shape: shapeType, variation: i)
                
                let drawingData = ProcessedDrawingData(
                    stroke: humanLikeStroke,
                    label: shapeType,
                    metadata: [
                        "source": "human_like_synthetic",
                        "variation": i,
                        "generated_date": Date()
                    ]
                )
                
                syntheticData.append(drawingData)
            }
        }
        
        print("✅ Generated \(syntheticData.count) human-like synthetic samples")
        return syntheticData
    }
    
    private func generateHumanLikeStroke(shape: String, variation: Int) -> ProcessedStroke {
        // Generate strokes with human-like characteristics:
        // - Slight tremor/shake
        // - Inconsistent speed
        // - Imperfect geometry
        // - Variable pressure
        
        let basePoints = generateBaseShapePoints(shape: shape, variation: variation)
        let humanizedPoints = addHumanImperfections(to: basePoints)
        
        return ProcessedStroke(
            points: humanizedPoints,
            duration: TimeInterval(humanizedPoints.count) * 0.05, // ~50ms per point
            boundingBox: calculateBoundingBox(for: humanizedPoints)
        )
    }
    
    private func generateBaseShapePoints(shape: String, variation: Int) -> [ProcessedPoint] {
        let pointCount = 50 + (variation % 20) // 50-70 points
        var points: [ProcessedPoint] = []
        
        switch shape {
        case "circle":
            points = generateCirclePoints(count: pointCount, variation: variation)
        case "rectangle":
            points = generateRectanglePoints(count: pointCount, variation: variation)
        case "line":
            points = generateLinePoints(count: pointCount, variation: variation)
        case "oval":
            points = generateOvalPoints(count: pointCount, variation: variation)
        case "curve":
            points = generateCurvePoints(count: pointCount, variation: variation)
        case "polygon":
            points = generatePolygonPoints(count: pointCount, variation: variation)
        default:
            points = generateCirclePoints(count: pointCount, variation: variation)
        }
        
        return points
    }
    
    private func addHumanImperfections(to points: [ProcessedPoint]) -> [ProcessedPoint] {
        return points.enumerated().map { index, point in
            // Add human-like imperfections
            let tremor = Double.random(in: -2...2) // Hand tremor
            let speedVariation = Double.random(in: 0.8...1.2) // Speed variation
            let pressureVariation = Double.random(in: 0.6...1.0) // Pressure variation
            
            return ProcessedPoint(
                x: point.x + tremor,
                y: point.y + tremor,
                timestamp: point.timestamp * speedVariation,
                pressure: point.pressure * pressureVariation
            )
        }
    }
    
    // MARK: - Shape Point Generation
    
    private func generateCirclePoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let center = CGPoint(x: 112, y: 112) // Center of 224x224 canvas
        let radius = 60.0 + Double(variation % 20) // Vary radius
        
        var points: [ProcessedPoint] = []
        
        for i in 0..<count {
            let angle = 2 * Double.pi * Double(i) / Double(count)
            let radiusNoise = Double.random(in: -5...5) // Imperfect radius
            let angleNoise = Double.random(in: -0.1...0.1) // Imperfect angle
            
            let adjustedRadius = radius + radiusNoise
            let adjustedAngle = angle + angleNoise
            
            let x = center.x + adjustedRadius * cos(adjustedAngle)
            let y = center.y + adjustedRadius * sin(adjustedAngle)
            
            points.append(ProcessedPoint(
                x: Double(x),
                y: Double(y),
                timestamp: Double(i) * 0.05,
                pressure: Double.random(in: 0.3...0.9)
            ))
        }
        
        return points
    }
    
    private func generateRectanglePoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let center = CGPoint(x: 112, y: 112)
        let width = 80.0 + Double(variation % 20)
        let height = 60.0 + Double(variation % 15)
        
        let corners = [
            CGPoint(x: center.x - width/2, y: center.y - height/2),
            CGPoint(x: center.x + width/2, y: center.y - height/2),
            CGPoint(x: center.x + width/2, y: center.y + height/2),
            CGPoint(x: center.x - width/2, y: center.y + height/2)
        ]
        
        var points: [ProcessedPoint] = []
        let pointsPerSide = count / 4
        
        for side in 0..<4 {
            let startCorner = corners[side]
            let endCorner = corners[(side + 1) % 4]
            
            for i in 0..<pointsPerSide {
                let t = Double(i) / Double(pointsPerSide)
                let x = Double(startCorner.x) + t * Double(endCorner.x - startCorner.x)
                let y = Double(startCorner.y) + t * Double(endCorner.y - startCorner.y)
                
                // Add slight curvature to simulate human drawing
                let noise = Double.random(in: -2...2)
                
                points.append(ProcessedPoint(
                    x: x + noise,
                    y: y + noise,
                    timestamp: Double(side * pointsPerSide + i) * 0.05,
                    pressure: Double.random(in: 0.4...0.8)
                ))
            }
        }
        
        return points
    }
    
    private func generateLinePoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let startX = 50.0 + Double(variation % 20)
        let startY = 112.0 + Double.random(in: -20...20)
        let endX = 174.0 - Double(variation % 20)
        let endY = 112.0 + Double(variation % 20) - 10.0 + Double.random(in: -20...20)
        
        var points: [ProcessedPoint] = []
        
        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            let x = startX + t * (endX - startX)
            let y = startY + t * (endY - startY)
            
            // Add line wobble (humans can't draw perfectly straight lines)
            let wobble = Double.random(in: -3...3)
            
            points.append(ProcessedPoint(
                x: x,
                y: y + wobble,
                timestamp: Double(i) * 0.05,
                pressure: Double.random(in: 0.3...0.7)
            ))
        }
        
        return points
    }
    
    private func generateOvalPoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let center = CGPoint(x: 112, y: 112)
        let radiusX = 70.0 + Double(variation % 15)
        let radiusY = 45.0 + Double(variation % 10)
        
        var points: [ProcessedPoint] = []
        
        for i in 0..<count {
            let angle = 2 * Double.pi * Double(i) / Double(count)
            let radiusXNoise = Double.random(in: -3...3)
            let radiusYNoise = Double.random(in: -3...3)
            
            let x = center.x + (radiusX + radiusXNoise) * cos(angle)
            let y = center.y + (radiusY + radiusYNoise) * sin(angle)
            
            points.append(ProcessedPoint(
                x: Double(x),
                y: Double(y),
                timestamp: Double(i) * 0.05,
                pressure: Double.random(in: 0.3...0.9)
            ))
        }
        
        return points
    }
    
    private func generateCurvePoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let startPoint = CGPoint(x: 50 + variation % 20, y: 112)
        let endPoint = CGPoint(x: 174 - variation % 20, y: 112 + variation % 30 - 15)
        let controlPoint1 = CGPoint(x: 112/3 + variation % 20, y: 112/3 + variation % 20)
        let controlPoint2 = CGPoint(x: 2*112/3 - variation % 20, y: 2*112/3 - variation % 20)
        
        var points: [ProcessedPoint] = []
        
        for i in 0..<count {
            let t = Double(i) / Double(count - 1)
            
            // Bezier curve calculation
            let oneMinusT = 1.0 - t
            let oneMinusTSquared = oneMinusT * oneMinusT
            let oneMinusTCubed = oneMinusTSquared * oneMinusT
            let tSquared = t * t
            let tCubed = tSquared * t
            
            let x = oneMinusTCubed * Double(startPoint.x) +
                   3 * oneMinusTSquared * t * Double(controlPoint1.x) +
                   3 * oneMinusT * tSquared * Double(controlPoint2.x) +
                   tCubed * Double(endPoint.x)
            
            let y = oneMinusTCubed * Double(startPoint.y) +
                   3 * oneMinusTSquared * t * Double(controlPoint1.y) +
                   3 * oneMinusT * tSquared * Double(controlPoint2.y) +
                   tCubed * Double(endPoint.y)
            
            // Add curve smoothness variation
            let smoothnessNoise = Double.random(in: -1.5...1.5)
            
            points.append(ProcessedPoint(
                x: x + smoothnessNoise,
                y: y + smoothnessNoise,
                timestamp: Double(i) * 0.05,
                pressure: Double.random(in: 0.4...0.8)
            ))
        }
        
        return points
    }
    
    private func generatePolygonPoints(count: Int, variation: Int) -> [ProcessedPoint] {
        let sides = 5 + (variation % 3) // 5-7 sides
        let center = CGPoint(x: 112, y: 112)
        let radius = 60.0 + Double(variation % 20)
        
        var corners: [CGPoint] = []
        
        // Generate polygon corners with imperfections
        for i in 0..<sides {
            let angle = 2 * Double.pi * Double(i) / Double(sides)
            let radiusNoise = Double.random(in: -5...5)
            let angleNoise = Double.random(in: -0.1...0.1)
            
            let adjustedRadius = radius + radiusNoise
            let adjustedAngle = angle + angleNoise
            
            let x = center.x + adjustedRadius * cos(adjustedAngle)
            let y = center.y + adjustedRadius * sin(adjustedAngle)
            
            corners.append(CGPoint(x: x, y: y))
        }
        
        var points: [ProcessedPoint] = []
        let pointsPerSide = count / sides
        
        for side in 0..<sides {
            let startCorner = corners[side]
            let endCorner = corners[(side + 1) % sides]
            
            for i in 0..<pointsPerSide {
                let t = Double(i) / Double(pointsPerSide)
                let x = Double(startCorner.x) + t * Double(endCorner.x - startCorner.x)
                let y = Double(startCorner.y) + t * Double(endCorner.y - startCorner.y)
                
                points.append(ProcessedPoint(
                    x: x,
                    y: y,
                    timestamp: Double(side * pointsPerSide + i) * 0.05,
                    pressure: Double.random(in: 0.3...0.8)
                ))
            }
        }
        
        return points
    }
    
    // MARK: - Data Enhancement
    
    private func enhanceTrainingData(_ baseData: [ProcessedDrawingData]) async throws -> [ProcessedDrawingData] {
        print("🔄 Enhancing training data with augmentation...")
        
        var enhancedData = baseData
        
        // Add augmented versions
        for originalData in baseData {
            for i in 0..<Config.augmentationMultiplier {
                let augmentedStroke = try await dataProcessor.augmentStroke(
                    originalData.stroke,
                    augmentationType: AugmentationType.allCases[i % AugmentationType.allCases.count]
                )
                
                let augmentedData = ProcessedDrawingData(
                    stroke: augmentedStroke,
                    label: originalData.label,
                    metadata: originalData.metadata.merging([
                        "augmentation_type": AugmentationType.allCases[i % AugmentationType.allCases.count].rawValue,
                        "augmentation_index": i
                    ]) { _, new in new }
                )
                
                enhancedData.append(augmentedData)
            }
        }
        
        print("✅ Enhanced dataset: \(enhancedData.count) total samples")
        return enhancedData
    }
    
    // MARK: - Model Training
    
    private func trainCoreMLModel(with data: [ProcessedDrawingData]) async throws -> MLModel {
        print("🧠 Training Core ML model with real data...")
        
        // Convert processed data to ML feature providers
        let featureProviders = data.map { drawingData in
            // Convert stroke to feature vector
            let features = strokeToFeatureVector(drawingData.stroke)
            let labelValue = MLFeatureValue(string: drawingData.label)
            let featureValue = try! MLFeatureValue(multiArray: MLMultiArray(features))
            
            return try! MLDictionaryFeatureProvider(dictionary: [
                "stroke_features": featureValue,
                "shape_label": labelValue
            ])
        }
        
        // Use our CoreMLModelTrainer for the actual training
        let trainedModelURL = try await modelTrainer.trainModel(with: featureProviders)
        let trainedModel = try MLModel(contentsOf: trainedModelURL)
        
        return trainedModel
    }
    
    private func strokeToFeatureVector(_ stroke: ProcessedStroke) -> [Double] {
        // Convert stroke to a fixed-size feature vector for ML training
        let maxPoints = 100
        var features: [Double] = []
        
        // Normalize and pad/truncate to fixed size
        let normalizedPoints = normalizeStrokePoints(stroke.points, targetCount: maxPoints)
        
        for point in normalizedPoints {
            features.append(point.x)
            features.append(point.y)
            features.append(point.pressure)
        }
        
        // Pad to fixed size if needed
        while features.count < maxPoints * 3 {
            features.append(0.0)
        }
        
        return features
    }
    
    private func normalizeStrokePoints(_ points: [ProcessedPoint], targetCount: Int) -> [ProcessedPoint] {
        guard points.count != targetCount else { return points }
        
        if points.count < targetCount {
            // Interpolate to add more points
            return interpolatePoints(points, to: targetCount)
        } else {
            // Sample down to target count
            return samplePoints(points, to: targetCount)
        }
    }
    
    private func interpolatePoints(_ points: [ProcessedPoint], to targetCount: Int) -> [ProcessedPoint] {
        guard points.count > 1 else { return points }
        
        var result: [ProcessedPoint] = []
        let stepSize = Double(points.count - 1) / Double(targetCount - 1)
        
        for i in 0..<targetCount {
            let index = Double(i) * stepSize
            let lowerIndex = Int(floor(index))
            let upperIndex = min(lowerIndex + 1, points.count - 1)
            let t = index - Double(lowerIndex)
            
            let lowerPoint = points[lowerIndex]
            let upperPoint = points[upperIndex]
            
            let interpolatedPoint = ProcessedPoint(
                x: lowerPoint.x + t * (upperPoint.x - lowerPoint.x),
                y: lowerPoint.y + t * (upperPoint.y - lowerPoint.y),
                timestamp: lowerPoint.timestamp + t * (upperPoint.timestamp - lowerPoint.timestamp),
                pressure: lowerPoint.pressure + t * (upperPoint.pressure - lowerPoint.pressure)
            )
            
            result.append(interpolatedPoint)
        }
        
        return result
    }
    
    private func samplePoints(_ points: [ProcessedPoint], to targetCount: Int) -> [ProcessedPoint] {
        let stepSize = Double(points.count) / Double(targetCount)
        var result: [ProcessedPoint] = []
        
        for i in 0..<targetCount {
            let index = Int(Double(i) * stepSize)
            result.append(points[min(index, points.count - 1)])
        }
        
        return result
    }
    
    // MARK: - Model Validation
    
    private func validateModel(_ model: MLModel, with data: [ProcessedDrawingData]) async throws -> TrainingMetrics {
        print("📊 Validating trained model...")
        
        let validationData = Array(data.suffix(Int(Double(data.count) * Config.validationSplit)))
        var correctPredictions = 0
        
        for sample in validationData {
            let features = strokeToFeatureVector(sample.stroke)
            let featureValue = try MLFeatureValue(multiArray: MLMultiArray(features))
            let input = try MLDictionaryFeatureProvider(dictionary: ["stroke_features": featureValue])
            
            let prediction = try model.prediction(from: input)
            if let predictedLabel = prediction.featureValue(for: "shape_label")?.stringValue,
               predictedLabel == sample.label {
                correctPredictions += 1
            }
        }
        
        let accuracy = Double(correctPredictions) / Double(validationData.count)
        
        return TrainingMetrics(
            accuracy: accuracy,
            trainingDataCount: data.count - validationData.count,
            validationDataCount: validationData.count,
            trainingTime: 0 // Would be measured in real implementation
        )
    }
    
    // MARK: - Helper Methods
    
    private func getRealDataDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("RealDrawingData")
    }
    
    private func calculateBoundingBox(for points: [ProcessedPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        let xs = points.map { $0.x }
        let ys = points.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 0
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

// MARK: - Supporting Types

enum TrainingStatus {
    case idle
    case preparing
    case training
    case completed
    case failed
}
