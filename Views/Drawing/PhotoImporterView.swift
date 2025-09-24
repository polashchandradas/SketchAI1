import SwiftUI
import PhotosUI
import Vision
import UIKit

// MARK: - Photo Importer View
struct PhotoImporterView: View {
    let onPhotoSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPhoto: PhotosPickerItem? {
        didSet {
            print("🔍 [PhotoImporter] selectedPhoto didSet: \(selectedPhoto != nil)")
        }
    }
    @State private var selectedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisResult: String = ""
    @State private var showAnalysisResult = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Import Photo for Drawing Practice")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose a photo to trace or use as reference for your drawing lesson")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .onChange(of: selectedPhoto) { newPhoto in
                        print("🔍 [PhotoImporter] onChange triggered with newPhoto: \(newPhoto != nil)")
                        loadPhoto(from: newPhoto)
                    }
                    .padding(.top)
                    
                    // Photo Picker
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(radius: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .frame(height: 200)
                                    .foregroundColor(.blue)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 40))
                                            Text("Tap to select photo")
                                                .font(.headline)
                                        }
                                        .foregroundColor(.blue)
                                    )
                            }
                            
                            Text(selectedImage == nil ? "Choose Photo" : "Change Photo")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Analysis Result
                    if showAnalysisResult {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "eye.fill")
                                    .foregroundColor(.green)
                                Text("AI Analysis")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                            
                            Text(analysisResult)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                    
                    // Analysis Progress
                    if isAnalyzing {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Analyzing photo with AI...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    // Action Buttons with safe area handling
                    VStack(spacing: 12) {
                        if selectedImage != nil {
                            Button {
                                if let image = selectedImage {
                                    print("🔍 [PhotoImporter] 'Use This Photo' button tapped")
                                    print("🔍 [PhotoImporter] Calling onPhotoSelected with image size: \(image.size)")
                                    onPhotoSelected(image)
                                    print("🔍 [PhotoImporter] Photo selected callback completed, dismissing view")
                                    dismiss()
                                } else {
                                    print("❌ [PhotoImporter] 'Use This Photo' button tapped but selectedImage is nil")
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Use This Photo")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                if let image = selectedImage {
                                    analyzePhoto(image)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "eye.fill")
                                    Text(isAnalyzing ? "Analyzing..." : "Analyze Photo")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(isAnalyzing)
                        }
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20) // Add safe area bottom padding
                }
            }
            .navigationTitle("Import Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: selectedPhoto) { newPhoto in
            print("🔍 [PhotoImporter] onChange triggered with newPhoto: \(newPhoto != nil)")
            loadPhoto(from: newPhoto)
        }
    }
    
    // MARK: - Photo Loading
    
    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item = item else { 
            print("🔍 [PhotoImporter] No photo item provided")
            return 
        }
        
        print("🔍 [PhotoImporter] Starting to load photo from PhotosPickerItem")
        
        Task { @MainActor in
            do {
                print("🔍 [PhotoImporter] Loading transferable data...")
                if let data = try await item.loadTransferable(type: Data.self) {
                    print("🔍 [PhotoImporter] Data loaded successfully, size: \(data.count) bytes")
                    
                    if let image = UIImage(data: data) {
                        print("🔍 [PhotoImporter] Image created successfully, size: \(image.size)")
                        selectedImage = image
                        showAnalysisResult = false
                        print("🔍 [PhotoImporter] Photo loaded and set as selectedImage")
                    } else {
                        print("❌ [PhotoImporter] Failed to create UIImage from data")
                    }
                } else {
                    print("❌ [PhotoImporter] Failed to load transferable data")
                }
            } catch {
                print("❌ [PhotoImporter] Error loading photo: \(error)")
            }
        }
    }
    
    // MARK: - Photo Analysis
    
    private func analyzePhoto(_ image: UIImage) {
        isAnalyzing = true
        showAnalysisResult = false
        
        Task { @MainActor in
            let result = await performVisionAnalysis(image)
            
            analysisResult = result
            showAnalysisResult = true
            isAnalyzing = false
        }
    }
    
    private func performVisionAnalysis(_ image: UIImage) async -> String {
        guard let cgImage = image.cgImage else {
            return "Unable to analyze image"
        }
        
        var analysisResults: [String] = []
        
        // Face Detection
        if let faceResults = await detectFaces(in: cgImage) {
            analysisResults.append(faceResults)
        }
        
        // Object Detection
        if let objectResults = await detectObjects(in: cgImage) {
            analysisResults.append(objectResults)
        }
        
        // Text Detection
        if let textResults = await detectText(in: cgImage) {
            analysisResults.append(textResults)
        }
        
        // Rectangle Detection for perspective
        if let rectangleResults = await detectRectangles(in: cgImage) {
            analysisResults.append(rectangleResults)
        }
        
        if analysisResults.isEmpty {
            return "This image contains general content suitable for drawing practice."
        } else {
            return analysisResults.joined(separator: " ")
        }
    }
    
    private func detectFaces(in cgImage: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let observations = request.results as? [VNFaceObservation], !observations.isEmpty {
                    let count = observations.count
                    let result = count == 1 ? "Found 1 face - perfect for portrait drawing practice!" : "Found \(count) faces - great for group portrait practice!"
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
    
    private func detectObjects(in cgImage: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNGenerateObjectnessBasedSaliencyImageRequest { request, error in
                if let observations = request.results as? [VNSaliencyImageObservation], !observations.isEmpty {
                    continuation.resume(returning: "Found interesting objects - excellent for still life drawing!")
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
    
    private func detectText(in cgImage: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let observations = request.results as? [VNRecognizedTextObservation], !observations.isEmpty {
                    continuation.resume(returning: "Contains text - good for lettering and calligraphy practice!")
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
    
    private func detectRectangles(in cgImage: CGImage) async -> String? {
        return await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let observations = request.results as? [VNRectangleObservation], !observations.isEmpty {
                    continuation.resume(returning: "Found geometric shapes - perfect for perspective drawing practice!")
                } else {
                    continuation.resume(returning: nil)
                }
            }
            
            // OFFICIAL APPLE RECOMMENDATION: Use CPU-only in Simulator
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

#Preview {
    PhotoImporterView { image in
        print("Photo selected: \(image.size)")
    }
}
