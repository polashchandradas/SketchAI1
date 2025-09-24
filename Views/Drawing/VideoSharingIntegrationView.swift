import SwiftUI
@preconcurrency import AVFoundation
import Photos
import UIKit

// MARK: - Video Sharing Integration View
struct VideoSharingIntegrationView: View {
    let recordedVideoURL: URL?
    let lesson: Lesson
    
    @StateObject private var socialSharingManager = EnhancedSocialSharingManager()
    @StateObject private var videoRecordingEngine = OptimizedVideoRecordingEngine()
    
    @State private var isGeneratingVideo = false
    @State private var generationProgress: Double = 0.0
    @State private var showShareSheet = false
    @State private var selectedPlatform: SocialPlatform = .general
    @State private var customCaption = ""
    @State private var selectedHashtags: Set<String> = []
    @State private var showVideoPreview = false
    @State private var finalVideoURL: URL?
    @State private var videoDuration: String = "Loading..."
    
    // Platform-specific settings
    @State private var selectedVideoQuality: VideoQuality = .high
    @State private var selectedAspectRatio: VideoAspectRatio = .vertical
    @State private var includeWatermark = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Video Preview Section
                    if let videoURL = recordedVideoURL {
                        videoPreviewSection(videoURL: videoURL)
                    }
                    
                    // Platform Selection
                    platformSelectionSection
                    
                    // Content Customization
                    contentCustomizationSection
                    
                    // Video Settings
                    videoSettingsSection
                    
                    // Share Actions
                    shareActionsSection
                }
                .padding()
            }
            .navigationTitle("Share Your Creation")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showVideoPreview) {
                if let finalVideoURL = finalVideoURL {
                    VideoPreviewSheet(
                        videoURL: finalVideoURL,
                        lesson: lesson,
                        onShare: { platform in
                            shareToSelectedPlatform(platform)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintbrush.pointed.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Lesson Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(lesson.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Difficulty badge
                Text(lesson.difficulty.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(lesson.difficulty.color.opacity(0.2))
                    .foregroundColor(lesson.difficulty.color)
                    .cornerRadius(8)
            }
            
            Text("Share your artistic journey with the world! Choose your platform and customize your video.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Video Preview Section
    private func videoPreviewSection(videoURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Drawing Process")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Video thumbnail with play button
            ZStack {
                AsyncVideoThumbnail(videoURL: videoURL)
                    .frame(height: 200)
                    .cornerRadius(12)
                
                Button(action: {
                    showVideoPreview = true
                    finalVideoURL = videoURL
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
            }
            
            // Video stats
            HStack {
                Label("Duration: \(videoDuration)", systemImage: "clock")
                Spacer()
                Label("Size: \(formatFileSize(videoURL))", systemImage: "doc")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .onAppear {
            Task {
                videoDuration = await formatDuration(videoURL)
            }
        }
    }
    
    // MARK: - Platform Selection Section
    private var platformSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Platform")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(socialSharingManager.supportedPlatforms, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        action: {
                            selectedPlatform = platform
                            updateSettingsForPlatform(platform)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Content Customization Section
    private var contentCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customize Your Post")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Caption input
            VStack(alignment: .leading, spacing: 8) {
                Text("Caption")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: $customCaption)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onAppear {
                        if customCaption.isEmpty {
                            customCaption = socialSharingManager.getDefaultCaption(for: lesson)
                        }
                    }
            }
            
            // Hashtag selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Hashtags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                let suggestedHashtags = socialSharingManager.getDefaultHashtags(for: lesson.category)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(suggestedHashtags, id: \.self) { hashtag in
                        HashtagButton(
                            hashtag: hashtag,
                            isSelected: selectedHashtags.contains(hashtag),
                            action: {
                                if selectedHashtags.contains(hashtag) {
                                    selectedHashtags.remove(hashtag)
                                } else {
                                    selectedHashtags.insert(hashtag)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Video Settings Section
    private var videoSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Quality selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Quality")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Quality", selection: $selectedVideoQuality) {
                    ForEach(VideoQuality.allCases, id: \.self) { quality in
                        Text(quality.displayName).tag(quality)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Aspect ratio selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Format")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Aspect Ratio", selection: $selectedAspectRatio) {
                    ForEach(VideoAspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.displayName).tag(ratio)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Watermark toggle
            Toggle("Include SketchAI Watermark", isOn: $includeWatermark)
        }
    }
    
    // MARK: - Share Actions Section
    private var shareActionsSection: some View {
        VStack(spacing: 12) {
            if isGeneratingVideo {
                VStack(spacing: 8) {
                    ProgressView(value: generationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text("Generating video... \(Int(generationProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Button(action: generateAndShare) {
                    HStack {
                        Image(systemName: selectedPlatform.icon)
                        Text("Share to \(selectedPlatform.name)")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(recordedVideoURL == nil)
                
                Button(action: saveToPhotos) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Save to Photos")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(recordedVideoURL == nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateSettingsForPlatform(_ platform: SocialPlatform) {
        switch platform {
        case .tikTok:
            selectedAspectRatio = .vertical
            selectedVideoQuality = .high
        case .instagram:
            selectedAspectRatio = .square
            selectedVideoQuality = .high
        default:
            selectedAspectRatio = .vertical
            selectedVideoQuality = .medium
        }
    }
    
    private func generateAndShare() {
        guard let videoURL = recordedVideoURL else { return }
        
        isGeneratingVideo = true
        generationProgress = 0.0
        
        // Create optimized video for selected platform
        Task {
            do {
                let optimizedVideoURL = try await optimizeVideoForPlatform(
                    videoURL,
                    platform: selectedPlatform,
                    quality: selectedVideoQuality,
                    aspectRatio: selectedAspectRatio,
                    includeWatermark: includeWatermark
                )
                
                await MainActor.run {
                    isGeneratingVideo = false
                    finalVideoURL = optimizedVideoURL
                    shareToSelectedPlatform(selectedPlatform)
                }
                
            } catch {
                await MainActor.run {
                    isGeneratingVideo = false
                    // Handle error
                    print("Error generating video: \(error)")
                }
            }
        }
    }
    
    private func optimizeVideoForPlatform(
        _ videoURL: URL,
        platform: SocialPlatform,
        quality: VideoQuality,
        aspectRatio: VideoAspectRatio,
        includeWatermark: Bool
    ) async throws -> URL {
        
        // Use existing EnhancedSocialSharingManager for video optimization
        return try await withCheckedThrowingContinuation { continuation in
            socialSharingManager.createTimelapseVideo(
                fromFrames: [videoURL], // Convert existing video to frame URLs if needed
                platform: platform,
                speedMultiplier: 1.0 // Keep original speed for sharing
            ) { result in
                switch result {
                case .success(let optimizedURL):
                    continuation.resume(returning: optimizedURL)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func shareToSelectedPlatform(_ platform: SocialPlatform) {
        guard let videoURL = finalVideoURL else { return }
        
        let content = ShareContentType.video(videoURL)
        let hashtags = Array(selectedHashtags)
        
        Task {
            let result: EnhancedShareResult
            
            switch platform {
            case .tikTok:
                result = await socialSharingManager.shareToTikTok(
                    content: content,
                    caption: customCaption,
                    hashtags: hashtags
                )
            case .instagram:
                result = await socialSharingManager.shareToInstagram(
                    content: content,
                    caption: customCaption,
                    hashtags: hashtags
                )
            case .general:
                // Need a source view for iPad compatibility
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    result = await socialSharingManager.shareGeneral(
                        content: content,
                        sourceView: window,
                        caption: customCaption,
                        hashtags: hashtags
                    )
                } else {
                    return
                }
            case .saveToPhotos:
                saveToPhotos()
                return
            default:
                return
            }
            
            // Handle sharing result
            await MainActor.run {
                handleSharingResult(result)
            }
        }
    }
    
    private func saveToPhotos() {
        guard let videoURL = finalVideoURL ?? recordedVideoURL else { return }
        
        socialSharingManager.saveToPhotos(videoURL: videoURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Show success message
                    print("Video saved to Photos successfully")
                case .failure(let error):
                    // Show error message
                    print("Failed to save video: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleSharingResult(_ result: EnhancedShareResult) {
        switch result {
        case .success(let platform):
            print("Successfully shared to \(platform.name)")
            // Show success message
        case .failure(let error):
            print("Sharing failed: \(error.localizedDescription)")
            // Show error message
        }
    }
    
    private func formatDuration(_ videoURL: URL) async -> String {
        let asset = AVAsset(url: videoURL)
        
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return formatSecondsToString(seconds)
        } catch {
            return "00:00"
        }
    }
    
    private func formatSecondsToString(_ seconds: Double) -> String {
        
        if seconds < 60 {
            return String(format: "%.0fs", seconds)
        } else {
            let minutes = Int(seconds / 60)
            let remainingSeconds = Int(seconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%dm %ds", minutes, remainingSeconds)
        }
    }
    
    private func formatFileSize(_ videoURL: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)
            if let fileSize = attributes[FileAttributeKey.size] as? NSNumber {
                return ByteCountFormatter.string(fromByteCount: fileSize.int64Value, countStyle: .file)
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return "Unknown"
    }
}

// MARK: - Supporting Views

struct PlatformButton: View {
    let platform: SocialPlatform
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(platform.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HashtagButton: View {
    let hashtag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(hashtag)")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// DifficultyBadge is defined in HomeView.swift - using that implementation

struct AsyncVideoThumbnail: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task { @MainActor in
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                thumbnail = UIImage(cgImage: cgImage)
            } catch {
                print("Error generating thumbnail: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

enum VideoQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case ultra = "ultra"
    
    var displayName: String {
        switch self {
        case .low: return "Low (720p)"
        case .medium: return "Medium (1080p)"
        case .high: return "High (1440p)"
        case .ultra: return "Ultra (4K)"
        }
    }
}

enum VideoAspectRatio: String, CaseIterable {
    case square = "1:1"
    case vertical = "9:16"
    case horizontal = "16:9"
    
    var displayName: String {
        switch self {
        case .square: return "Square (1:1)"
        case .vertical: return "Vertical (9:16)"
        case .horizontal: return "Horizontal (16:9)"
        }
    }
}

// MARK: - Extensions
// DifficultyLevel.color extension is defined in DataModels.swift
