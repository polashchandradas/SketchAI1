import Foundation
import CoreML
import CreateML
import Vision
import Accelerate

/// Service for training Core ML models with real human drawing data
class CoreMLModelTrainer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var trainingProgress: Double = 0.0
    @Published var trainingStatus: TrainingStatus = .idle
    @Published var modelAccuracy: Double = 0.0
    @Published var trainingMetrics: TrainingMetrics?
    
    // MARK: - Private Properties
    private let dataProcessor: DataProcessor
    private let modelValidator: ModelValidator
    private let fileManager = FileManager.default
    
    // MARK: - Training Configuration
    private let maxTrainingIterations = 1000
    private let validationSplit: Double = 0.2
    private let minAccuracyThreshold: Double = 0.8
    
    init(dataProcessor: DataProcessor, modelValidator: ModelValidator) {
        self.dataProcessor = dataProcessor
        self.modelValidator = modelValidator
    }
    
    // MARK: - Model Training
    
    /// Train a new Core ML model with collected data
    func trainModel(
        with trainingData: [ProcessedDrawingData],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> MLModel {
        
        await MainActor.run {
            trainingStatus = .preparing
            trainingProgress = 0.0
        }
        
        do {
            // Prepare training data
            let preparedData = try await prepareTrainingData(trainingData)
            
            // Split data into training and validation sets
            let (trainingSet, validationSet) = splitData(preparedData, validationSplit: validationSplit)
            
            // Train the model
            let trainedModel = try await performTraining(
                trainingSet: trainingSet,
                validationSet: validationSet,
                progressHandler: progressHandler
            )
            
            // Validate the model
            let accuracy = try await validateModel(trainedModel, with: validationSet)
            
            await MainActor.run {
                modelAccuracy = accuracy
                trainingStatus = .completed
                trainingMetrics = TrainingMetrics(
                    accuracy: accuracy,
                    trainingDataCount: trainingSet.count,
                    validationDataCount: validationSet.count,
                    trainingTime: Date().timeIntervalSince1970
                )
            }
            
            return trainedModel
            
        } catch {
            await MainActor.run {
                trainingStatus = .failed
            }
            throw error
        }
    }
    
    /// Prepare training data for model training
    private func prepareTrainingData(_ data: [ProcessedDrawingData]) async throws -> [TrainingExample] {
        await MainActor.run {
            trainingStatus = .preparing
        }
        
        var trainingExamples: [TrainingExample] = []
        
        for (index, drawingData) in data.enumerated() {
            // Convert drawing data to training example
            let example = try await convertToTrainingExample(drawingData)
            trainingExamples.append(example)
            
            // Update progress
            let progress = Double(index + 1) / Double(data.count) * 0.3 // 30% for preparation
            await MainActor.run {
                trainingProgress = progress
            }
        }
        
        return trainingExamples
    }
    
    /// Convert processed drawing data to training example
    private func convertToTrainingExample(_ data: ProcessedDrawingData) async throws -> TrainingExample {
        // Extract features from drawing data
        let features = try await extractFeatures(from: data)
        
        // Create training example
        return TrainingExample(
            features: features,
            label: data.label,
            metadata: data.metadata
        )
    }
    
    /// Extract features from drawing data
    private func extractFeatures(from data: ProcessedDrawingData) async throws -> [Double] {
        var features: [Double] = []
        
        // Geometric features
        features.append(contentsOf: extractGeometricFeatures(data.stroke))
        
        // Temporal features
        features.append(contentsOf: extractTemporalFeatures(data.stroke))
        
        // Pressure features
        features.append(contentsOf: extractPressureFeatures(data.stroke))
        
        // Shape features
        features.append(contentsOf: extractShapeFeatures(data.stroke))
        
        return features
    }
    
    /// Extract geometric features from stroke
    private func extractGeometricFeatures(_ stroke: ProcessedStroke) -> [Double] {
        var features: [Double] = []
        
        // Stroke length
        let length = calculateStrokeLength(stroke.points)
        features.append(length)
        
        // Stroke width and height
        let width = stroke.boundingBox.width
        let height = stroke.boundingBox.height
        features.append(width)
        features.append(height)
        features.append(width / height) // Aspect ratio
        
        // Stroke complexity (curvature)
        let complexity = calculateStrokeComplexity(stroke.points)
        features.append(complexity)
        
        return features
    }
    
    /// Extract temporal features from stroke
    private func extractTemporalFeatures(_ stroke: ProcessedStroke) -> [Double] {
        var features: [Double] = []
        
        // Stroke duration
        features.append(stroke.duration)
        
        // Average speed
        let speed = calculateAverageSpeed(stroke.points)
        features.append(speed)
        
        // Speed variance
        let speedVariance = calculateSpeedVariance(stroke.points)
        features.append(speedVariance)
        
        return features
    }
    
    /// Extract pressure features from stroke
    private func extractPressureFeatures(_ stroke: ProcessedStroke) -> [Double] {
        var features: [Double] = []
        
        // Average pressure
        let avgPressure = stroke.points.map { $0.pressure }.reduce(0, +) / Double(stroke.points.count)
        features.append(avgPressure)
        
        // Pressure variance
        let pressureVariance = calculatePressureVariance(stroke.points)
        features.append(pressureVariance)
        
        // Pressure range
        let pressures = stroke.points.map { $0.pressure }
        let minPressure = pressures.min() ?? 0
        let maxPressure = pressures.max() ?? 0
        features.append(maxPressure - minPressure)
        
        return features
    }
    
    /// Extract shape features from stroke
    private func extractShapeFeatures(_ stroke: ProcessedStroke) -> [Double] {
        var features: [Double] = []
        
        // Bounding box features
        let bbox = stroke.boundingBox
        features.append(bbox.width)
        features.append(bbox.height)
        features.append(bbox.width / bbox.height)
        
        // Centroid
        let centroid = calculateCentroid(stroke.points)
        features.append(centroid.x)
        features.append(centroid.y)
        
        // Compactness (perimeter^2 / area)
        let perimeter = calculatePerimeter(stroke.points)
        let area = calculateArea(stroke.points)
        let compactness = (perimeter * perimeter) / area
        features.append(compactness)
        
        return features
    }
    
    /// Split data into training and validation sets
    private func splitData(_ data: [TrainingExample], validationSplit: Double) -> ([TrainingExample], [TrainingExample]) {
        let shuffledData = data.shuffled()
        let splitIndex = Int(Double(data.count) * (1.0 - validationSplit))
        
        let trainingSet = Array(shuffledData[0..<splitIndex])
        let validationSet = Array(shuffledData[splitIndex..<data.count])
        
        return (trainingSet, validationSet)
    }
    
    /// Perform the actual model training
    private func performTraining(
        trainingSet: [TrainingExample],
        validationSet: [TrainingExample],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> MLModel {
        
        await MainActor.run {
            trainingStatus = .training
        }
        
        // Create training data table
        let trainingTable = try await createTrainingTable(trainingSet)
        
        // Configure training parameters
        let parameters = MLClassifierParameters()
        parameters.trainingAlgorithm = .logisticRegression
        parameters.validationData = try await createTrainingTable(validationSet)
        
        // Train the model
        let classifier = try await MLClassifier(trainingData: trainingTable, parameters: parameters)
        
        // Update progress
        progressHandler(1.0)
        
        return classifier.model
    }
    
    /// Create training data table for CreateML
    private func createTrainingTable(_ examples: [TrainingExample]) async throws -> MLDataTable {
        var dataTable = MLDataTable()
        
        for example in examples {
            let row: [String: MLDataValue] = [
                "features": .array(example.features.map { .double($0) }),
                "label": .string(example.label)
            ]
            dataTable.append(row)
        }
        
        return dataTable
    }
    
    /// Validate the trained model
    private func validateModel(_ model: MLModel, with validationSet: [TrainingExample]) async throws -> Double {
        var correctPredictions = 0
        var totalPredictions = 0
        
        for example in validationSet {
            let prediction = try await makePrediction(model: model, features: example.features)
            
            if prediction == example.label {
                correctPredictions += 1
            }
            totalPredictions += 1
        }
        
        return Double(correctPredictions) / Double(totalPredictions)
    }
    
    /// Make a prediction with the model
    private func makePrediction(model: MLModel, features: [Double]) async throws -> String {
        // Convert features to MLMultiArray
        let featureArray = try MLMultiArray(shape: [NSNumber(value: features.count)], dataType: .double)
        for (index, value) in features.enumerated() {
            featureArray[index] = NSNumber(value: value)
        }
        
        // Make prediction
        let input = DrawingClassifierInput(features: featureArray)
        let output = try model.prediction(from: input)
        
        // Extract prediction result
        if let classifierOutput = output as? DrawingClassifierOutput {
            return classifierOutput.label
        }
        
        throw TrainingError.predictionFailed
    }
    
    // MARK: - Model Management
    
    /// Save the trained model
    func saveModel(_ model: MLModel, name: String) async throws -> URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelURL = documentsPath.appendingPathComponent("\(name).mlmodelc")
        
        try model.write(to: modelURL)
        
        return modelURL
    }
    
    /// Load a saved model
    func loadModel(from url: URL) async throws -> MLModel {
        return try MLModel(contentsOf: url)
    }
    
    // MARK: - Feature Calculation Helpers
    
    private func calculateStrokeLength(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        
        var totalLength: Double = 0
        for i in 1..<points.count {
            let p1 = points[i-1]
            let p2 = points[i]
            let distance = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
            totalLength += distance
        }
        
        return totalLength
    }
    
    private func calculateStrokeComplexity(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        
        var totalAngleChange: Double = 0
        for i in 1..<points.count - 1 {
            let p1 = points[i-1]
            let p2 = points[i]
            let p3 = points[i+1]
            
            let angle1 = atan2(p2.y - p1.y, p2.x - p1.x)
            let angle2 = atan2(p3.y - p2.y, p3.x - p2.x)
            
            let angleChange = abs(angle2 - angle1)
            totalAngleChange += min(angleChange, 2 * .pi - angleChange)
        }
        
        return totalAngleChange / Double(points.count - 2)
    }
    
    private func calculateAverageSpeed(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        
        var totalSpeed: Double = 0
        for i in 1..<points.count {
            let p1 = points[i-1]
            let p2 = points[i]
            let distance = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
            let timeDelta = p2.timestamp - p1.timestamp
            let speed = distance / timeDelta
            totalSpeed += speed
        }
        
        return totalSpeed / Double(points.count - 1)
    }
    
    private func calculateSpeedVariance(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        
        let speeds = (1..<points.count).map { i in
            let p1 = points[i-1]
            let p2 = points[i]
            let distance = sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
            let timeDelta = p2.timestamp - p1.timestamp
            return distance / timeDelta
        }
        
        let meanSpeed = speeds.reduce(0, +) / Double(speeds.count)
        let variance = speeds.map { pow($0 - meanSpeed, 2) }.reduce(0, +) / Double(speeds.count)
        
        return sqrt(variance)
    }
    
    private func calculatePressureVariance(_ points: [ProcessedPoint]) -> Double {
        let pressures = points.map { $0.pressure }
        let mean = pressures.reduce(0, +) / Double(pressures.count)
        let variance = pressures.map { pow($0 - mean, 2) }.reduce(0, +) / Double(pressures.count)
        return sqrt(variance)
    }
    
    private func calculateCentroid(_ points: [ProcessedPoint]) -> CGPoint {
        let sumX = points.map { $0.x }.reduce(0, +)
        let sumY = points.map { $0.y }.reduce(0, +)
        return CGPoint(x: sumX / Double(points.count), y: sumY / Double(points.count))
    }
    
    private func calculatePerimeter(_ points: [ProcessedPoint]) -> Double {
        return calculateStrokeLength(points)
    }
    
    private func calculateArea(_ points: [ProcessedPoint]) -> Double {
        guard points.count > 2 else { return 0 }
        
        var area: Double = 0
        for i in 0..<points.count {
            let p1 = points[i]
            let p2 = points[(i + 1) % points.count]
            area += p1.x * p2.y - p2.x * p1.y
        }
        
        return abs(area) / 2.0
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

enum TrainingError: Error {
    case insufficientData
    case trainingFailed
    case validationFailed
    case predictionFailed
    case modelSaveFailed
}

struct TrainingExample {
    let features: [Double]
    let label: String
    let metadata: [String: Any]
}

struct TrainingMetrics {
    let accuracy: Double
    let trainingDataCount: Int
    let validationDataCount: Int
    let trainingTime: TimeInterval
}

struct ProcessedDrawingData {
    let stroke: ProcessedStroke
    let label: String
    let metadata: [String: Any]
}

struct ProcessedStroke {
    let points: [ProcessedPoint]
    let duration: TimeInterval
    let boundingBox: CGRect
}

struct ProcessedPoint {
    let x: Double
    let y: Double
    let timestamp: TimeInterval
    let pressure: Double
}
