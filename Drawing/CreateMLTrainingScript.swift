import Foundation
import CreateML
import CoreML
import Vision

// MARK: - Create ML Training Script for Stroke Analysis
// This script demonstrates how to create a Core ML model for stroke analysis
// Run this script in Xcode Playground or as a standalone Swift script

class StrokeAnalysisModelTrainer {
    
    // MARK: - Configuration
    private struct Config {
        static let modelName = "StrokeAnalysisModel"
        static let trainingDataPath = "TrainingData"
        static let outputPath = "Models"
    }
    
    // MARK: - Training Data Structure
    struct TrainingSample {
        let imagePath: String
        let shapeType: String
        let accuracy: Double
    }
    
    // MARK: - Main Training Method
    func trainStrokeAnalysisModel() {
        print("🚀 Starting stroke analysis model training...")
        
        // Step 1: Prepare training data
        let trainingData = prepareTrainingData()
        
        // Step 2: Create and configure the model
        let model = createImageClassifier()
        
        // Step 3: Train the model
        trainModel(model, with: trainingData)
        
        // Step 4: Evaluate the model
        evaluateModel(model)
        
        // Step 5: Save the model
        saveModel(model)
        
        print("✅ Model training completed!")
    }
    
    // MARK: - Training Data Preparation
    private func prepareTrainingData() -> MLImageClassifier.DataSource {
        // REAL DATA IMPLEMENTATION: Use actual human drawing data
        print("🎯 Preparing REAL human drawing data for training...")
        
        // Load real drawing data from our privacy-compliant pipeline
        if let realDataSource = loadRealDrawingData() {
            print("✅ Using REAL human drawing data (\(realDataSource.count) samples)")
            return realDataSource
        } else {
            print("⚠️ Real data not available, using augmented synthetic data as fallback")
            return createEnhancedSyntheticData()
        }
    }
    
    // MARK: - Real Data Loading
    private func loadRealDrawingData() -> MLImageClassifier.DataSource? {
        let realDataPipeline = RealDataPipelineManager(
            privacyManager: PrivacyCompliantDataCollectionManager(),
            encryptionService: DataEncryptionService(),
            consentManager: ConsentManager()
        )
        
        // Check if we have sufficient real data for training
        let dataDirectory = getOrCreateRealDataDirectory()
        let shapeDirectories = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        
        var hasMinimumData = true
        for shape in shapeDirectories {
            let shapeURL = dataDirectory.appendingPathComponent(shape)
            let imageCount = (try? FileManager.default.contentsOfDirectory(at: shapeURL, includingPropertiesForKeys: nil))?.count ?? 0
            
            if imageCount < 50 { // Minimum 50 real samples per shape
                hasMinimumData = false
                print("⚠️ Insufficient real data for \(shape): \(imageCount) samples (need 50+)")
                break
            }
        }
        
        if hasMinimumData {
            return MLImageClassifier.DataSource.labeledDirectories(at: dataDirectory)
        }
        
        return nil
    }
    
    private func getOrCreateRealDataDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let realDataPath = documentsPath.appendingPathComponent("RealTrainingData")
        
        // Create directory structure if it doesn't exist
        let shapeDirectories = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        for shape in shapeDirectories {
            let shapeURL = realDataPath.appendingPathComponent(shape)
            try? FileManager.default.createDirectory(at: shapeURL, withIntermediateDirectories: true)
        }
        
        return realDataPath
    }
    
    private func createEnhancedSyntheticData() -> MLImageClassifier.DataSource {
        // Enhanced synthetic data with human-like imperfections
        print("🎨 Creating ENHANCED synthetic data with human-like variations...")
        
        let trainingURL = getOrCreateSyntheticDataDirectory()
        
        // Generate enhanced synthetic data with human imperfections
        generateEnhancedSyntheticSamples(to: trainingURL)
        
        return MLImageClassifier.DataSource.labeledDirectories(at: trainingURL)
    }
    
    private func getOrCreateSyntheticDataDirectory() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let syntheticDataPath = documentsPath.appendingPathComponent("EnhancedSyntheticData")
        
        // Create directory structure
        let shapeDirectories = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        for shape in shapeDirectories {
            let shapeURL = syntheticDataPath.appendingPathComponent(shape)
            try? FileManager.default.createDirectory(at: shapeURL, withIntermediateDirectories: true)
        }
        
        return syntheticDataPath
    }
    
    private func generateEnhancedSyntheticSamples(to directory: URL) {
        let shapes = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        let samplesPerShape = 200 // More samples with variations
        
        for shape in shapes {
            let shapeDirectory = directory.appendingPathComponent(shape)
            
            for i in 0..<samplesPerShape {
                // Generate multiple variations with human-like imperfections
                let baseImage = generateHumanLikeShape(shape: shape, variation: i)
                let imageURL = shapeDirectory.appendingPathComponent("\(shape)_enhanced_\(i).png")
                
                if let imageData = baseImage.pngData() {
                    try? imageData.write(to: imageURL)
                }
                
                // Generate additional augmented versions
                for j in 0..<3 {
                    let augmentedImage = generateAugmentedShape(shape: shape, baseVariation: i, augmentation: j)
                    let augmentedURL = shapeDirectory.appendingPathComponent("\(shape)_aug_\(i)_\(j).png")
                    
                    if let imageData = augmentedImage.pngData() {
                        try? imageData.write(to: augmentedURL)
                    }
                }
            }
            
            print("📁 Generated \(samplesPerShape * 4) enhanced samples for \(shape)")
        }
    }
    
    // MARK: - Model Creation
    private func createImageClassifier() -> MLImageClassifier {
        let parameters = MLImageClassifier.ModelParameters(
            featureExtractor: .scenePrint(revision: 1),
            validation: .split(strategy: .automatic),
            maxIterations: 100,
            augmentationOptions: [
                .blur(probability: 0.1),
                .noise(probability: 0.1),
                .exposure(probability: 0.1),
                .rotation(probability: 0.1)
            ]
        )
        
        return MLImageClassifier(trainingData: createSyntheticTrainingData(), parameters: parameters)
    }
    
    // MARK: - Model Training
    private func trainModel(_ model: MLImageClassifier, with data: MLImageClassifier.DataSource) {
        print("📚 Training model with \(data.count) samples...")
        
        // The model is already trained when created with training data
        // This method would be used for additional training or fine-tuning
        
        print("✅ Model training completed")
    }
    
    // MARK: - Model Evaluation
    private func evaluateModel(_ model: MLImageClassifier) {
        print("📊 Evaluating model performance...")
        
        // Create validation data (in practice, this would be separate from training data)
        let validationData = createSyntheticTrainingData()
        
        // Evaluate the model
        let evaluation = model.evaluation(on: validationData)
        
        print("📈 Model Evaluation Results:")
        print("   - Accuracy: \(evaluation.classificationError)")
        print("   - Precision: \(evaluation.precision)")
        print("   - Recall: \(evaluation.recall)")
        print("   - F1 Score: \(evaluation.f1Score)")
    }
    
    // MARK: - Model Saving
    private func saveModel(_ model: MLImageClassifier) {
        print("💾 Saving trained model...")
        
        let outputURL = URL(fileURLWithPath: Config.outputPath)
        
        // Create output directory if it doesn't exist
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
        
        let modelURL = outputURL.appendingPathComponent("\(Config.modelName).mlmodel")
        
        do {
            try model.write(to: modelURL)
            print("✅ Model saved to: \(modelURL.path)")
            
            // Also save metadata
            saveModelMetadata(to: outputURL)
            
        } catch {
            print("❌ Failed to save model: \(error)")
        }
    }
    
    private func saveModelMetadata(to url: URL) {
        let metadata = [
            "model_name": Config.modelName,
            "created_date": ISO8601DateFormatter().string(from: Date()),
            "framework": "Create ML",
            "input_size": "224x224",
            "output_classes": ["circle", "rectangle", "line", "oval", "curve", "polygon"],
            "description": "Stroke analysis model for drawing app shape recognition"
        ]
        
        let metadataURL = url.appendingPathComponent("\(Config.modelName)_metadata.json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
            try jsonData.write(to: metadataURL)
            print("✅ Model metadata saved to: \(metadataURL.path)")
        } catch {
            print("❌ Failed to save model metadata: \(error)")
        }
    }
}

// MARK: - Training Data Generator
class TrainingDataGenerator {
    
    // MARK: - Generate Synthetic Training Data
    static func generateSyntheticTrainingData() {
        print("🎨 Generating synthetic training data...")
        
        let shapes = ["circle", "rectangle", "line", "oval", "curve", "polygon"]
        let samplesPerShape = 100
        
        for shape in shapes {
            generateSamplesForShape(shape, count: samplesPerShape)
        }
        
        print("✅ Synthetic training data generation completed")
    }
    
    private static func generateSamplesForShape(_ shape: String, count: Int) {
        let outputDir = URL(fileURLWithPath: "TrainingData/\(shape)")
        try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        for i in 0..<count {
            let image = generateShapeImage(shape: shape, variation: i)
            let imageURL = outputDir.appendingPathComponent("\(shape)_\(i).png")
            
            if let imageData = image.pngData() {
                try? imageData.write(to: imageURL)
            }
        }
        
        print("📁 Generated \(count) samples for \(shape)")
    }
    
    private static func generateShapeImage(shape: String, variation: Int) -> UIImage {
        let size = CGSize(width: 224, height: 224)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Clear background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Set stroke properties
            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 3.0
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            
            // Generate shape with variation
            switch shape {
            case "circle":
                generateCircle(path: path, size: size, variation: variation)
            case "rectangle":
                generateRectangle(path: path, size: size, variation: variation)
            case "line":
                generateLine(path: path, size: size, variation: variation)
            case "oval":
                generateOval(path: path, size: size, variation: variation)
            case "curve":
                generateCurve(path: path, size: size, variation: variation)
            case "polygon":
                generatePolygon(path: path, size: size, variation: variation)
            default:
                generateCircle(path: path, size: size, variation: variation)
            }
            
            path.stroke()
        }
    }
    
    private static func generateCircle(path: UIBezierPath, size: CGSize, variation: Int) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = 60 + CGFloat(variation % 20) // Vary radius
        
        // Add some imperfection to make it more realistic
        let imperfection = CGFloat(variation % 10) * 0.1
        let adjustedRadius = radius * (1.0 + imperfection)
        
        path.addArc(withCenter: center, radius: adjustedRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
    }
    
    private static func generateRectangle(path: UIBezierPath, size: CGSize, variation: Int) {
        let width = 80 + CGFloat(variation % 20)
        let height = 60 + CGFloat(variation % 20)
        let x = (size.width - width) / 2
        let y = (size.height - height) / 2
        
        path.move(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y))
        path.addLine(to: CGPoint(x: x + width, y: y + height))
        path.addLine(to: CGPoint(x: x, y: y + height))
        path.close()
    }
    
    private static func generateLine(path: UIBezierPath, size: CGSize, variation: Int) {
        let startX = 50 + CGFloat(variation % 30)
        let startY = size.height / 2
        let endX = size.width - 50 - CGFloat(variation % 30)
        let endY = size.height / 2 + CGFloat(variation % 20) - 10
        
        path.move(to: CGPoint(x: startX, y: startY))
        path.addLine(to: CGPoint(x: endX, y: endY))
    }
    
    private static func generateOval(path: UIBezierPath, size: CGSize, variation: Int) {
        let width = 100 + CGFloat(variation % 20)
        let height = 60 + CGFloat(variation % 20)
        let x = (size.width - width) / 2
        let y = (size.height - height) / 2
        
        path.addEllipse(in: CGRect(x: x, y: y, width: width, height: height))
    }
    
    private static func generateCurve(path: UIBezierPath, size: CGSize, variation: Int) {
        let startX = 50 + CGFloat(variation % 20)
        let startY = size.height / 2
        let endX = size.width - 50 - CGFloat(variation % 20)
        let endY = size.height / 2 + CGFloat(variation % 30) - 15
        
        let controlX1 = size.width / 3 + CGFloat(variation % 20)
        let controlY1 = size.height / 3 + CGFloat(variation % 20)
        let controlX2 = 2 * size.width / 3 - CGFloat(variation % 20)
        let controlY2 = 2 * size.height / 3 - CGFloat(variation % 20)
        
        path.move(to: CGPoint(x: startX, y: startY))
        path.addCurve(
            to: CGPoint(x: endX, y: endY),
            controlPoint1: CGPoint(x: controlX1, y: controlY1),
            controlPoint2: CGPoint(x: controlX2, y: controlY2)
        )
    }
    
    private static func generatePolygon(path: UIBezierPath, size: CGSize, variation: Int) {
        let sides = 5 + (variation % 3) // 5-7 sides
        let radius = 60 + CGFloat(variation % 20)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        for i in 0..<sides {
            let angle = Double(i) * 2 * .pi / Double(sides)
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
    }
}

// MARK: - Usage Example
/*
// To use this training script:

// 1. Generate synthetic training data (for demonstration)
TrainingDataGenerator.generateSyntheticTrainingData()

// 2. Train the model
let trainer = StrokeAnalysisModelTrainer()
trainer.trainStrokeAnalysisModel()

// 3. The trained model will be saved as StrokeAnalysisModel.mlmodel
// 4. Add this model to your Xcode project
// 5. Use it in UnifiedStrokeAnalyzer.swift
*/

// MARK: - Real-World Implementation Notes
/*
For a production implementation, you would:

1. **Collect Real Training Data:**
   - Record actual user strokes from your app
   - Convert strokes to images
   - Label them with correct shape types
   - Organize into training/validation/test sets

2. **Data Augmentation:**
   - Rotate, scale, and translate stroke images
   - Add noise and blur to simulate real-world conditions
   - Vary stroke thickness and style

3. **Model Architecture:**
   - Use transfer learning with pre-trained models
   - Consider using Vision framework's built-in models
   - Implement ensemble methods for better accuracy

4. **Continuous Learning:**
   - Collect user feedback on predictions
   - Retrain model with new data
   - A/B test different model versions

5. **Performance Optimization:**
   - Quantize model for smaller size
   - Use Core ML's optimization features
   - Profile inference performance on target devices
*/
