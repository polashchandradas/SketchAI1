import SwiftUI
import PencilKit
import UIKit

struct ExportOptionsView: View {
    var canvasView: PKCanvasView?
    var drawing: UserDrawing?
    var lesson: Lesson?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var monetizationService: MonetizationService
    @StateObject private var exportService = ExportService()
    @State private var selectedFormat: ExportFormat = .image
    @State private var includeWatermark = true
    @State private var isExporting = false
    @State private var exportCompleted = false
    @State private var showViralSharing = false
    @State private var exportedImage: UIImage?
    @State private var exportedVideoURL: URL?
    @State private var showShareSheet = false
    @State private var showSaveToPhotosAlert = false
    
    
    init(canvasView: PKCanvasView) {
        self.canvasView = canvasView
        self.drawing = nil
        self.lesson = nil
    }
    
    init(drawing: UserDrawing) {
        self.canvasView = nil
        self.drawing = drawing
        self.lesson = nil
    }
    
    init(canvasView: PKCanvasView, lesson: Lesson) {
        self.canvasView = canvasView
        self.drawing = nil
        self.lesson = lesson
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                        VStack(spacing: 24) {
                            // Preview section
                            ExportPreviewSection(
                                canvasView: canvasView,
                                drawing: drawing,
                                selectedFormat: selectedFormat
                            )
                            
                            // Format selection
                            FormatSelectionSection(selectedFormat: $selectedFormat)
                    
                    // Options
                    ExportOptionsSection(includeWatermark: $includeWatermark)
                    
                    // Viral Sharing Section (New Feature)
                    ViralSharingSection(
                        showViralSharing: $showViralSharing,
                        drawing: drawing,
                        lesson: lesson
                    )
                    
                    // Social media shortcuts
                    SocialMediaSection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Export Drawing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportDrawing()
                    }
                    .fontWeight(.semibold)
                    .disabled(isExporting)
                }
            }
        }
                .alert("Export Completed!", isPresented: $exportCompleted) {
                    Button("Share") {
                        if let exportedImage = exportedImage {
                            let shareSheet = exportService.createShareSheet(for: exportedImage)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController?.present(shareSheet, animated: true)
                            }
                        } else if let exportedVideoURL = exportedVideoURL {
                            let shareSheet = exportService.createShareSheet(for: exportedVideoURL)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let window = windowScene.windows.first {
                                window.rootViewController?.present(shareSheet, animated: true)
                            }
                        }
                        dismiss()
                    }
                    Button("Save to Gallery") {
                        Task {
                            if let exportedImage = exportedImage {
                                let result = await exportService.saveToPhotos(exportedImage)
                                await MainActor.run {
                                    if case .failure = result {
                                        // Handle error
                                    }
                                }
                            } else if let exportedVideoURL = exportedVideoURL {
                                let result = await exportService.saveVideoToPhotos(exportedVideoURL)
                                await MainActor.run {
                                    if case .failure = result {
                                        // Handle error
                                    }
                                }
                            }
                            dismiss()
                        }
                    }
                    Button("Done") {
                        dismiss()
                    }
                } message: {
                    Text("Your drawing has been exported successfully!")
                }
        .sheet(isPresented: $showViralSharing) {
            if let drawing = drawing {
                ViralSharingViewController(
                    drawing: drawing,
                    originalImage: nil, // Would get from drawing data in real implementation
                    finalImage: UIImage(systemName: "photo")!, // Would get from drawing data
                    lesson: lesson
                )
            }
        }
    }
    
    private func exportDrawing() {
        isExporting = true
        
        Task {
            switch selectedFormat {
            case .image:
                let result = await exportService.exportImage(
                    from: canvasView,
                    drawing: drawing,
                    format: selectedFormat,
                    includeWatermark: includeWatermark
                )
                
                if case .success(let image) = result {
                    await MainActor.run {
                        self.exportedImage = image
                        self.isExporting = false
                        self.exportCompleted = true
                    }
                } else {
                    await MainActor.run {
                        self.isExporting = false
                        // Handle error
                    }
                }
                
            case .timelapse:
                guard let drawing = drawing else {
                    await MainActor.run {
                        self.isExporting = false
                    }
                    return
                }
                
                let result = await exportService.exportTimelapse(
                    from: drawing,
                    includeWatermark: includeWatermark
                )
                
                if case .success(let videoURL) = result {
                    await MainActor.run {
                        self.exportedVideoURL = videoURL
                        self.isExporting = false
                        self.exportCompleted = true
                    }
                } else {
                    await MainActor.run {
                        self.isExporting = false
                        // Handle error
                    }
                }
                
            case .beforeAfter:
                // For before/after, we need the original lesson image
                guard let lesson = lesson,
                      let originalImage = UIImage(named: lesson.referenceImageName) else {
                    await MainActor.run {
                        self.isExporting = false
                    }
                    return
                }
                
                guard let finalImage = await getFinalImage() else {
                    await MainActor.run {
                        self.isExporting = false
                    }
                    return
                }
                
                let result = await exportService.exportBeforeAfter(
                    originalImage: originalImage,
                    finalImage: finalImage,
                    format: selectedFormat,
                    includeWatermark: includeWatermark
                )
                
                if case .success(let image) = result {
                    await MainActor.run {
                        self.exportedImage = image
                        self.isExporting = false
                        self.exportCompleted = true
                    }
                } else {
                    await MainActor.run {
                        self.isExporting = false
                        // Handle error
                    }
                }
                
            case .story:
                let result = await exportService.exportStory(
                    from: canvasView,
                    drawing: drawing,
                    includeWatermark: includeWatermark
                )
                
                if case .success(let image) = result {
                    await MainActor.run {
                        self.exportedImage = image
                        self.isExporting = false
                        self.exportCompleted = true
                    }
                } else {
                    await MainActor.run {
                        self.isExporting = false
                        // Handle error
                    }
                }
            }
        }
    }
    
    private func getFinalImage() async -> UIImage? {
        if let canvasView = canvasView {
            return await getImageFromCanvas(canvasView)
        } else if let drawing = drawing {
            return UIImage(data: drawing.imageData)
        }
        return nil
    }
    
    private func getImageFromCanvas(_ canvasView: PKCanvasView) async -> UIImage? {
        return await Task.detached {
            let bounds = canvasView.bounds
            
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            return renderer.image { context in
                // Fill with white background
                UIColor.white.setFill()
                context.fill(bounds)
                
                // Draw the canvas view hierarchy (includes PencilKit drawing)
                canvasView.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
        }.value
    }
}

struct ExportPreviewSection: View {
    let canvasView: PKCanvasView?
    let drawing: UserDrawing?
    let selectedFormat: ExportFormat
    
    @State private var previewImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray5))
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    Group {
                        if isLoading {
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading preview...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else if let previewImage = previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("No preview available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                )
                .frame(height: 200)
                .onAppear {
                    loadPreviewImage()
                }
                .onChange(of: selectedFormat) { _ in
                    loadPreviewImage()
                }
        }
    }
    
    private func loadPreviewImage() {
        isLoading = true
        
        Task {
            // Get the source image
            let sourceImage: UIImage?
            if let canvasView = canvasView {
                sourceImage = await getImageFromCanvas(canvasView)
            } else if let drawing = drawing {
                sourceImage = UIImage(data: drawing.imageData)
            } else {
                sourceImage = nil
            }
            
            await MainActor.run {
                self.previewImage = sourceImage
                self.isLoading = false
            }
        }
    }
    
    private func getImageFromCanvas(_ canvasView: PKCanvasView) async -> UIImage? {
        return await Task.detached {
            let bounds = canvasView.bounds
            
            let renderer = UIGraphicsImageRenderer(size: bounds.size)
            return renderer.image { context in
                // Fill with white background
                UIColor.white.setFill()
                context.fill(bounds)
                
                // Draw the canvas view hierarchy (includes PencilKit drawing)
                canvasView.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
        }.value
    }
}

struct FormatSelectionSection: View {
    @Binding var selectedFormat: ExportFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Format")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.rawValue) { format in
                    FormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                    }
                }
            }
        }
    }
}

struct FormatCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(format.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(format.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .stroke(isSelected ? Color.blue : Color.secondary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemGray6))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ExportOptionsSection: View {
    @Binding var includeWatermark: Bool
    @EnvironmentObject var monetizationService: MonetizationService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Watermark option (for free users)
                if !monetizationService.isPro {
                    OptionRow(
                        icon: "drop",
                        title: "Include Watermark",
                        subtitle: "Remove with SketchAI Pro",
                        isOn: $includeWatermark,
                        isDisabled: true
                    )
                }
                
                // Quality settings
                OptionRow(
                    icon: "sparkles",
                    title: "High Quality",
                    subtitle: "Best for sharing and printing"
                )
                
                // Save to Photos
                OptionRow(
                    icon: "square.and.arrow.down",
                    title: "Save to Photos",
                    subtitle: "Automatically save to your photo library"
                )
            }
        }
    }
}

struct OptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var isDisabled: Bool = false
    
    init(icon: String, title: String, subtitle: String, isOn: Binding<Bool> = .constant(true), isDisabled: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .disabled(isDisabled)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Viral Sharing Section
struct ViralSharingSection: View {
    @Binding var showViralSharing: Bool
    let drawing: UserDrawing?
    let lesson: Lesson?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🚀 Create Viral Content")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("NEW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.pink)
                        .cornerRadius(8)
                }
                
                Text("Transform your art into engaging TikTok and Instagram content with before/after comparisons, transitions, and time-lapse videos.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { showViralSharing = true }) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open Viral Creator")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Perfect for TikTok & Instagram")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.title3)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(drawing == nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pink.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct SocialMediaSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share To")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                SocialMediaButton(
                    icon: "camera",
                    name: "TikTok",
                    color: .black
                ) {
                    // Share to TikTok
                    if let url = URL(string: "https://www.tiktok.com/upload") {
                        UIApplication.shared.open(url)
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                SocialMediaButton(
                    icon: "camera.circle",
                    name: "Instagram",
                    color: .pink
                ) {
                    // Share to Instagram Stories
                    if let url = URL(string: "instagram-stories://share") {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        } else {
                            // Fallback to Instagram main app
                            if let instagramURL = URL(string: "instagram://app") {
                                UIApplication.shared.open(instagramURL)
                            }
                        }
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                SocialMediaButton(
                    icon: "square.and.arrow.up",
                    name: "Share",
                    color: .blue
                ) {
                    // Open native share sheet
                    let shareText = "Check out my drawing created with SketchAI! 🎨✨"
                    let activityVC = UIActivityViewController(
                        activityItems: [shareText],
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityVC, animated: true)
                    }
                    
                    // Provide haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                
                SocialMediaButton(
                    icon: "square.and.arrow.down",
                    name: "Save",
                    color: .green
                ) {
                    // Save to photos library
                    // Note: In a real implementation, you'd pass the actual drawing image
                    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()
                    UIImageWriteToSavedPhotosAlbum(placeholderImage, nil, nil, nil)
                    
                    // Show success feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                }
            }
        }
    }
}

struct SocialMediaButton: View {
    let icon: String
    let name: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(name)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExportOptionsView(drawing: UserDrawing(
        lessonId: nil,
        title: "Test Drawing",
        imageData: Data(),
        category: .faces
    ))
    .environmentObject(UserProfileService(persistenceService: PersistenceService()))
    .environmentObject(MonetizationService())
}
