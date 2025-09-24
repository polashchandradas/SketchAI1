import SwiftUI

// MARK: - Viral Template Selection View
// Integrates with existing ViralSharingViewController to provide template selection

struct ViralTemplateSelectionView: View {
    @StateObject private var templateEngine = ViralVideoTemplateEngine()
    @Environment(\.dismiss) private var dismiss
    
    // Input data
    let originalImage: UIImage
    let finalDrawing: UIImage
    let drawingProcess: [UIImage]
    let onVideoGenerated: (URL) -> Void
    
    // State
    @State private var selectedTemplate: ViralTemplate = .classicReveal
    @State private var showingPreview = false
    @State private var generatedVideoURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var includeWatermark = false
    @State private var customMemeText = "Me trying to draw|SketchAI to the rescue!"
    @State private var clumsyAttemptImage: UIImage?
    @State private var selectedMemeImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imagePickerType: ImagePickerType = .clumsyAttempt
    
    enum ImagePickerType {
        case clumsyAttempt
        case memeImage
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Template Selection
                    templateSelectionSection
                    
                    // Template Configuration
                    templateConfigurationSection
                    
                    // Preview Button
                    previewSection
                    
                    // Generate Button
                    generateSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Reduced excessive padding
            }
            .navigationTitle("Viral Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: bindingForImagePicker(), sourceType: .photoLibrary)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            // Processing overlay
            processingOverlay
        )
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Create Amazing Content")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Choose a template that'll make your art shine on social media! Each template is designed to showcase your creativity.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Template Selection Section
    private var templateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Template")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(ViralTemplate.allCases, id: \.self) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate == template
                    ) {
                        selectedTemplate = template
                    }
                }
            }
        }
    }
    
    // MARK: - Template Configuration Section
    private var templateConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Watermark toggle
                Toggle("Include Watermark", isOn: $includeWatermark)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                // Template-specific configuration
                templateSpecificConfiguration
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var templateSpecificConfiguration: some View {
        switch selectedTemplate {
        case .progressGlowUp:
            progressGlowUpConfiguration
        case .memeFormat:
            memeFormatConfiguration
        case .classicReveal:
            classicRevealConfiguration
        }
    }
    
    private var progressGlowUpConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Glow-Up Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: {
                imagePickerType = .clumsyAttempt
                showingImagePicker = true
            }) {
                HStack {
                    if let clumsyImage = clumsyAttemptImage {
                        Image(uiImage: clumsyImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(clumsyAttemptImage == nil ? "Add \"Before\" Image" : "Change \"Before\" Image")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Your first attempt or a simple sketch")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var memeFormatConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meme Format Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Meme image selection
            Button(action: {
                imagePickerType = .memeImage
                showingImagePicker = true
            }) {
                HStack {
                    if let memeImage = selectedMemeImage {
                        Image(uiImage: memeImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "face.smiling")
                            .font(.title2)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(selectedMemeImage == nil ? "Add Meme Image" : "Change Meme Image")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Frustrated character or reaction image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Meme text input
            VStack(alignment: .leading, spacing: 8) {
                Text("Meme Text")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                TextField("Top text | Bottom text", text: $customMemeText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
                
                Text("Separate top and bottom text with |")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var classicRevealConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Classic Reveal Settings")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Ready to generate! This template uses your drawing process automatically.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showPreview()
            }) {
                HStack {
                    Image(systemName: "play.circle")
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Preview Template")
                            .fontWeight(.medium)
                        Text("See how your video will look")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingPreview) {
            TemplatePreviewView(
                template: selectedTemplate,
                originalImage: originalImage,
                finalDrawing: finalDrawing,
                drawingProcess: drawingProcess,
                includeWatermark: includeWatermark,
                clumsyAttemptImage: clumsyAttemptImage,
                memeImage: selectedMemeImage,
                memeText: customMemeText
            )
        }
    }
    
    // MARK: - Generate Section
    private var generateSection: some View {
        VStack(spacing: 16) {
            Button(action: generateVideo) {
                HStack {
                    if templateEngine.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "video.badge.plus")
                    }
                    
                    Text(templateEngine.isProcessing ? "Generating..." : "Generate Video")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canGenerate ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!canGenerate || templateEngine.isProcessing)
            
            if templateEngine.isProcessing {
                ProgressView(value: templateEngine.processingProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Text("\(Int(templateEngine.processingProgress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Processing Overlay
    @ViewBuilder
    private var processingOverlay: some View {
        if templateEngine.isProcessing {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .overlay(
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Creating your amazing video...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(selectedTemplate.displayName) • \(Int(selectedTemplate.duration))s")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ProgressView(value: templateEngine.processingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                )
        }
    }
    
    // MARK: - Computed Properties
    private var canGenerate: Bool {
        switch selectedTemplate {
        case .classicReveal:
            return true
        case .progressGlowUp:
            return clumsyAttemptImage != nil
        case .memeFormat:
            return selectedMemeImage != nil && !customMemeText.isEmpty
        }
    }
    
    // MARK: - Helper Methods
    private func bindingForImagePicker() -> Binding<UIImage?> {
        switch imagePickerType {
        case .clumsyAttempt:
            return $clumsyAttemptImage
        case .memeImage:
            return $selectedMemeImage
        }
    }
    
    private func generateVideo() {
        Task {
            let result: Result<URL, ViralTemplateError>
            
            switch selectedTemplate {
            case .classicReveal:
                result = await templateEngine.generateClassicRevealVideo(
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark
                )
                
            case .progressGlowUp:
                guard let clumsyImage = clumsyAttemptImage else {
                    showError("Please add a \"before\" image for the Progress Glow-Up template")
                    return
                }
                
                result = await templateEngine.generateProgressGlowUpVideo(
                    clumsyAttempt: clumsyImage,
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark
                )
                
            case .memeFormat:
                guard let memeImage = selectedMemeImage else {
                    showError("Please add a meme image for the Meme Format template")
                    return
                }
                
                result = await templateEngine.generateMemeFormatVideo(
                    memeImage: memeImage,
                    memeText: customMemeText,
                    originalImage: originalImage,
                    finalDrawing: finalDrawing,
                    drawingProcess: drawingProcess,
                    includeWatermark: includeWatermark
                )
            }
            
            switch result {
            case .success(let videoURL):
                onVideoGenerated(videoURL)
                dismiss()
                
            case .failure(let error):
                showError(error.localizedDescription)
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showPreview() {
        // Validate that we have the required data for the selected template
        switch selectedTemplate {
        case .classicReveal:
            // Classic Reveal only needs the basic images
            showingPreview = true
        case .progressGlowUp:
            if clumsyAttemptImage == nil {
                showError("Please add a \"before\" image to preview the Progress Glow-Up template")
                return
            }
            showingPreview = true
        case .memeFormat:
            if selectedMemeImage == nil {
                showError("Please add a meme image to preview the Meme Format template")
                return
            }
            if customMemeText.isEmpty {
                showError("Please add meme text to preview the Meme Format template")
                return
            }
            showingPreview = true
        }
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let template: ViralTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Template icon
                templateIcon
                    .frame(width: 60, height: 60)
                    .background(template.accentColor.opacity(0.1))
                    .cornerRadius(12)
                
                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(Int(template.duration))s")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(template.accentColor.opacity(0.2))
                            .foregroundColor(template.accentColor)
                            .cornerRadius(6)
                    }
                    
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    // Template features
                    HStack(spacing: 8) {
                        ForEach(template.features, id: \.self) { feature in
                            Text(feature)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var templateIcon: some View {
        switch template {
        case .classicReveal:
            Image(systemName: "eye.circle")
                .font(.title)
                .foregroundColor(.blue)
        case .progressGlowUp:
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.title)
                .foregroundColor(.green)
        case .memeFormat:
            Image(systemName: "face.smiling.inverse")
                .font(.title)
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Extensions
extension ViralTemplate {
    var accentColor: Color {
        switch self {
        case .classicReveal: return .blue
        case .progressGlowUp: return .green
        case .memeFormat: return .orange
        }
    }
    
    var features: [String] {
        switch self {
        case .classicReveal:
            return ["Hook", "Process", "Reveal", "TikTok"]
        case .progressGlowUp:
            return ["Bob Ross", "Before/After", "Inspiring", "15s"]
        case .memeFormat:
            return ["Humor", "Relatable", "Sharp Cut", "Viral"]
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Template Preview View
struct TemplatePreviewView: View {
    let template: ViralTemplate
    let originalImage: UIImage
    let finalDrawing: UIImage
    let drawingProcess: [UIImage]
    let includeWatermark: Bool
    let clumsyAttemptImage: UIImage?
    let memeImage: UIImage?
    let memeText: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentFrameIndex = 0
    @State private var previewFrames: [UIImage] = []
    @State private var isGeneratingPreview = true
    @State private var previewError: String?
    
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("\(template.displayName) Preview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Duration: \(Int(template.duration))s • \(template.features.joined(separator: " • "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Preview Content
                if isGeneratingPreview {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Generating preview...")
                            .font(.headline)
                        Text("Creating key frames from your content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = previewError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Preview Error")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Preview frames
                    VStack(spacing: 16) {
                        // Current frame display
                        if !previewFrames.isEmpty {
                            Image(uiImage: previewFrames[currentFrameIndex])
                                .resizable()
                                .aspectRatio(9/16, contentMode: .fit)
                                .frame(maxHeight: 400)
                                .cornerRadius(12)
                                .shadow(radius: 8)
                        }
                        
                        // Frame navigation
                        if previewFrames.count > 1 {
                            HStack(spacing: 16) {
                                Button(action: previousFrame) {
                                    Image(systemName: "chevron.left.circle.fill")
                                        .font(.title2)
                                }
                                .disabled(currentFrameIndex == 0)
                                
                                Text("Frame \(currentFrameIndex + 1) of \(previewFrames.count)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Button(action: nextFrame) {
                                    Image(systemName: "chevron.right.circle.fill")
                                        .font(.title2)
                                }
                                .disabled(currentFrameIndex == previewFrames.count - 1)
                            }
                            
                            // Auto-play indicator
                            HStack {
                                Image(systemName: "play.circle")
                                    .foregroundColor(.blue)
                                Text("Auto-playing every 0.5s")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Template description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What you'll get:")
                                .font(.headline)
                            
                            Text(template.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            generatePreviewFrames()
        }
        .onReceive(timer) { _ in
            if !previewFrames.isEmpty && !isGeneratingPreview {
                currentFrameIndex = (currentFrameIndex + 1) % previewFrames.count
            }
        }
    }
    
    private func generatePreviewFrames() {
        Task {
            do {
                let frames = try await createPreviewFrames()
                await MainActor.run {
                    self.previewFrames = frames
                    self.isGeneratingPreview = false
                }
            } catch {
                await MainActor.run {
                    self.previewError = error.localizedDescription
                    self.isGeneratingPreview = false
                }
            }
        }
    }
    
    private func createPreviewFrames() async throws -> [UIImage] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var frames: [UIImage] = []
                
                switch self.template {
                case .classicReveal:
                    frames = self.createClassicRevealPreviewFrames()
                case .progressGlowUp:
                    frames = self.createProgressGlowUpPreviewFrames()
                case .memeFormat:
                    frames = self.createMemeFormatPreviewFrames()
                }
                
                continuation.resume(returning: frames)
            }
        }
    }
    
    private func createClassicRevealPreviewFrames() -> [UIImage] {
        var frames: [UIImage] = []
        let outputSize = CGSize(width: 1080, height: 1920)
        
        // Frame 1: Hook - Show original photo
        let hookFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: originalImage.size, in: outputSize, padding: 60)
            originalImage.draw(in: imageRect)
            
            drawText("Look at this photo...", in: CGRect(x: 40, y: 100, width: outputSize.width - 80, height: 80), context: context, fontSize: 36, color: .white)
        }
        frames.append(hookFrame)
        
        // Frame 2: Solution - AI guides appear
        let solutionFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: originalImage.size, in: outputSize, padding: 60)
            originalImage.draw(in: imageRect)
            
            // Draw simulated AI guides
            drawSimulatedAIGuides(in: imageRect, context: context)
            
            drawText("SketchAI breaks it down!", in: CGRect(x: 40, y: outputSize.height - 200, width: outputSize.width - 80, height: 80), context: context, fontSize: 36, color: .yellow)
        }
        frames.append(solutionFrame)
        
        // Frame 3: Process - Drawing in progress
        let processFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: finalDrawing.size, in: outputSize, padding: 60)
            finalDrawing.draw(in: imageRect)
            
            drawProgressIndicator(progress: 0.6, context: context, outputSize: outputSize)
        }
        frames.append(processFrame)
        
        // Frame 4: Reveal - Before/After comparison
        let revealFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageWidth = outputSize.width / 2
            let imageHeight = outputSize.height * 0.6
            let yOffset = (outputSize.height - imageHeight) / 2
            
            // Draw original (left)
            let originalRect = CGRect(x: 0, y: yOffset, width: imageWidth, height: imageHeight)
            var originalFitRect = calculateAspectFitRect(for: originalImage.size, in: originalRect.size)
            originalFitRect.origin.x += originalRect.origin.x
            originalFitRect.origin.y += originalRect.origin.y
            originalImage.draw(in: originalFitRect)
            
            // Draw final (right)
            let finalRect = CGRect(x: imageWidth, y: yOffset, width: imageWidth, height: imageHeight)
            var finalFitRect = calculateAspectFitRect(for: finalDrawing.size, in: finalRect.size)
            finalFitRect.origin.x += finalRect.origin.x
            finalFitRect.origin.y += finalRect.origin.y
            finalDrawing.draw(in: finalFitRect)
            
            // Center divider
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(3.0)
            context.move(to: CGPoint(x: imageWidth, y: yOffset))
            context.addLine(to: CGPoint(x: imageWidth, y: yOffset + imageHeight))
            context.strokePath()
            
            drawText("BEFORE", in: CGRect(x: 20, y: yOffset - 60, width: imageWidth - 40, height: 40), context: context, fontSize: 24, color: .white)
            drawText("AFTER", in: CGRect(x: imageWidth + 20, y: yOffset - 60, width: imageWidth - 40, height: 40), context: context, fontSize: 24, color: .white)
        }
        frames.append(revealFrame)
        
        return frames
    }
    
    private func createProgressGlowUpPreviewFrames() -> [UIImage] {
        var frames: [UIImage] = []
        let outputSize = CGSize(width: 1080, height: 1920)
        
        guard let clumsyImage = clumsyAttemptImage else { return frames }
        
        // Frame 1: Intro text
        let introFrame = createFrame(size: outputSize) { context in
            let colors = [UIColor.purple.cgColor, UIColor.blue.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: outputSize.height), options: [])
            
            drawText("\"Talent is a\npursued interest\"", in: CGRect(x: 60, y: outputSize.height / 2 - 100, width: outputSize.width - 120, height: 200), context: context, fontSize: 48, color: .white, alignment: .center)
            drawText("- Bob Ross", in: CGRect(x: 60, y: outputSize.height / 2 + 120, width: outputSize.width - 120, height: 60), context: context, fontSize: 24, color: UIColor.white.withAlphaComponent(0.8), alignment: .center)
        }
        frames.append(introFrame)
        
        // Frame 2: Before state
        let beforeFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.systemGray6.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: clumsyImage.size, in: outputSize, padding: 80)
            clumsyImage.draw(in: imageRect)
            
            drawText("My first attempt... 😅", in: CGRect(x: 40, y: 120, width: outputSize.width - 80, height: 80), context: context, fontSize: 36, color: .systemRed)
        }
        frames.append(beforeFrame)
        
        // Frame 3: Process state
        let processFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: finalDrawing.size, in: outputSize, padding: 60)
            finalDrawing.draw(in: imageRect)
            
            drawProgressIndicator(progress: 0.7, context: context, outputSize: outputSize)
        }
        frames.append(processFrame)
        
        // Frame 4: After state
        let afterFrame = createFrame(size: outputSize) { context in
            let colors = [UIColor.yellow.cgColor, UIColor.orange.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0])!
            context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: outputSize.height), options: [])
            
            let imageRect = calculateAspectFitRect(for: finalDrawing.size, in: outputSize, padding: 100)
            finalDrawing.draw(in: imageRect)
            
            drawText("With SketchAI! 🎉", in: CGRect(x: 40, y: 120, width: outputSize.width - 80, height: 80), context: context, fontSize: 42, color: .white)
        }
        frames.append(afterFrame)
        
        return frames
    }
    
    private func createMemeFormatPreviewFrames() -> [UIImage] {
        var frames: [UIImage] = []
        let outputSize = CGSize(width: 1080, height: 1920)
        
        guard let memeImg = memeImage else { return frames }
        
        // Frame 1: Meme frame
        let memeFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: memeImg.size, in: outputSize, padding: 60)
            memeImg.draw(in: imageRect)
            
            let textLines = memeText.components(separatedBy: "|")
            
            if textLines.count > 0 {
                drawMemeText(textLines[0], in: CGRect(x: 20, y: 60, width: outputSize.width - 40, height: 120), context: context, position: .top)
            }
            
            if textLines.count > 1 {
                drawMemeText(textLines[1], in: CGRect(x: 20, y: outputSize.height - 180, width: outputSize.width - 40, height: 120), context: context, position: .bottom)
            }
        }
        frames.append(memeFrame)
        
        // Frame 2: Transition
        let transitionFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            let imageRect = calculateAspectFitRect(for: originalImage.size, in: outputSize, padding: 60)
            originalImage.draw(in: imageRect)
            
            drawText("Then I found SketchAI...", in: CGRect(x: 40, y: 100, width: outputSize.width - 80, height: 80), context: context, fontSize: 36, color: .white)
        }
        frames.append(transitionFrame)
        
        // Frame 3: Solution process
        let solutionFrame = createFrame(size: outputSize) { context in
            context.setFillColor(UIColor.systemGray6.cgColor)
            context.fill(CGRect(origin: .zero, size: outputSize))
            
            // Draw mock app interface
            drawMockAppInterface(context: context, outputSize: outputSize)
            
            let canvasRect = CGRect(x: 40, y: 200, width: outputSize.width - 80, height: outputSize.height - 400)
            let imageRect = calculateAspectFitRect(for: finalDrawing.size, in: canvasRect.size)
            let finalRect = CGRect(
                x: canvasRect.origin.x + imageRect.origin.x,
                y: canvasRect.origin.y + imageRect.origin.y,
                width: imageRect.width,
                height: imageRect.height
            )
            finalDrawing.draw(in: finalRect)
        }
        frames.append(solutionFrame)
        
        return frames
    }
    
    // MARK: - Helper Methods
    
    private func createFrame(size: CGSize, drawing: (CGContext) -> Void) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            drawing(context.cgContext)
        }
    }
    
    private func calculateAspectFitRect(for imageSize: CGSize, in containerSize: CGSize, padding: CGFloat = 0) -> CGRect {
        let availableSize = CGSize(
            width: containerSize.width - padding * 2,
            height: containerSize.height - padding * 2
        )
        
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = availableSize.width / availableSize.height
        
        var rect = CGRect.zero
        
        if imageAspect > containerAspect {
            rect.size.width = availableSize.width
            rect.size.height = availableSize.width / imageAspect
        } else {
            rect.size.height = availableSize.height
            rect.size.width = availableSize.height * imageAspect
        }
        
        rect.origin.x = (containerSize.width - rect.size.width) / 2
        rect.origin.y = (containerSize.height - rect.size.height) / 2
        
        return rect
    }
    
    private func drawText(_ text: String, in rect: CGRect, context: CGContext, fontSize: CGFloat, color: UIColor, alignment: NSTextAlignment = .center) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            .foregroundColor: color,
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    private func drawMemeText(_ text: String, in rect: CGRect, context: CGContext, position: MemeTextPosition) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Impact", size: 48) ?? UIFont.systemFont(ofSize: 48, weight: .black),
            .foregroundColor: UIColor.white,
            .strokeColor: UIColor.black,
            .strokeWidth: -4.0,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedString = NSAttributedString(string: text.uppercased(), attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    private func drawSimulatedAIGuides(in rect: CGRect, context: CGContext) {
        context.saveGState()
        
        context.setStrokeColor(UIColor.cyan.cgColor)
        context.setLineWidth(2.0)
        context.setLineDash(phase: 0, lengths: [5, 5])
        
        context.move(to: CGPoint(x: rect.minX, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.strokePath()
        
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.strokePath()
        
        context.restoreGState()
    }
    
    private func drawProgressIndicator(progress: Float, context: CGContext, outputSize: CGSize) {
        let barRect = CGRect(x: 40, y: outputSize.height - 80, width: outputSize.width - 80, height: 20)
        
        context.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        context.fill(barRect)
        
        let progressRect = CGRect(x: barRect.minX, y: barRect.minY, width: barRect.width * CGFloat(progress), height: barRect.height)
        context.setFillColor(UIColor.green.cgColor)
        context.fill(progressRect)
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2.0)
        context.stroke(barRect)
    }
    
    private func drawMockAppInterface(context: CGContext, outputSize: CGSize) {
        let headerRect = CGRect(x: 0, y: 0, width: outputSize.width, height: 120)
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fill(headerRect)
        
        drawText("SketchAI", in: CGRect(x: 40, y: 40, width: outputSize.width - 80, height: 40), context: context, fontSize: 28, color: .white)
        
        let toolbarRect = CGRect(x: 0, y: outputSize.height - 120, width: outputSize.width, height: 120)
        context.setFillColor(UIColor.systemGray5.cgColor)
        context.fill(toolbarRect)
    }
    
    private func previousFrame() {
        if currentFrameIndex > 0 {
            currentFrameIndex -= 1
        }
    }
    
    private func nextFrame() {
        if currentFrameIndex < previewFrames.count - 1 {
            currentFrameIndex += 1
        }
    }
}

#Preview {
    ViralTemplateSelectionView(
        originalImage: UIImage(systemName: "photo") ?? UIImage(),
        finalDrawing: UIImage(systemName: "pencil") ?? UIImage(),
        drawingProcess: [],
        onVideoGenerated: { _ in }
    )
}




