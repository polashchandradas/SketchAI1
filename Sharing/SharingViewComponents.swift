import SwiftUI

// MARK: - Header Section
struct HeaderSection: View {
    let drawing: UserDrawing
    let lesson: Lesson?
    
    var body: some View {
        VStack(spacing: 16) {
            // Drawing preview
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("Drawing Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            VStack(spacing: 8) {
                Text(drawing.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let lesson = lesson {
                    HStack {
                        Image(systemName: lesson.category.iconName)
                            .foregroundColor(lesson.category.color)
                        
                        Text(lesson.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if lesson.isPremium {
                            lesson.premiumBadge
                        }
                    }
                }
                
                Text("Created \(drawing.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Content Type Selection
struct ContentTypeSection: View {
    @Binding var selectedType: SharingContentType
    let hasOriginalImage: Bool
    let onViralTemplatesSelected: () -> Void // NEW: Callback for viral templates
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share Format")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(SharingContentType.allCases, id: \.self) { type in
                    ContentTypeCard(
                        type: type,
                        isSelected: selectedType == type,
                        isEnabled: type == .finalImage || hasOriginalImage,
                        onSelect: { selectedType = type }
                    )
                }
            }
            
            // NEW: Viral Templates Button
            ViralTemplatesCard(onSelect: onViralTemplatesSelected)
        }
    }
}

struct ContentTypeCard: View {
    let type: SharingContentType
    let isSelected: Bool
    let isEnabled: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: isEnabled ? onSelect : {}) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isEnabled ? (isSelected ? .white : .blue) : .gray)
                
                VStack(spacing: 4) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? (isSelected ? .white : .primary) : .gray)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isEnabled ? (isSelected ? .white.opacity(0.8) : .secondary) : .gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Viral Templates Card
struct ViralTemplatesCard: View {
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon section
                VStack {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🔥 Viral Templates")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("NEW")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    
                    Text("Create TikTok-ready videos with proven viral formats")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text("Classic Reveal")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        Text("Progress Glow-Up")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                        
                        Text("Meme Format")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Configuration Section
struct ConfigurationSection: View {
    let selectedType: SharingContentType
    @Binding var selectedTransition: TransitionType
    @Binding var sliderPosition: Double
    let originalImage: UIImage?
    let finalImage: UIImage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selectedType != .finalImage {
                Text("Configuration")
                    .font(.headline)
            }
            
            switch selectedType {
            case .finalImage:
                EmptyView()
                
            case .beforeAfter:
                BeforeAfterPreview(
                    beforeImage: originalImage,
                    afterImage: finalImage
                )
                
            case .slider:
                SliderConfigurationView(
                    sliderPosition: $sliderPosition,
                    beforeImage: originalImage,
                    afterImage: finalImage
                )
                
            case .transition:
                TransitionConfigurationView(
                    selectedTransition: $selectedTransition,
                    beforeImage: originalImage,
                    afterImage: finalImage
                )
            }
        }
    }
}

struct BeforeAfterPreview: View {
    let beforeImage: UIImage?
    let afterImage: UIImage
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack {
                    Text("BEFORE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 80)
                        .overlay(
                            Group {
                                if let beforeImage = beforeImage {
                                    Image(uiImage: beforeImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(8)
                                } else {
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                }
                
                VStack {
                    Text("AFTER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 80)
                        .overlay(
                            Image(uiImage: afterImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                        )
                }
            }
        }
    }
}

struct SliderConfigurationView: View {
    @Binding var sliderPosition: Double
    let beforeImage: UIImage?
    let afterImage: UIImage
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Slider Position")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(spacing: 12) {
                // Slider preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                    .overlay(
                        SliderPreviewView(
                            sliderPosition: sliderPosition,
                            beforeImage: beforeImage,
                            afterImage: afterImage
                        )
                    )
                
                // Slider control
                HStack {
                    Text("Before")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $sliderPosition, in: 0...1)
                        .accentColor(.blue)
                    
                    Text("After")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct SliderPreviewView: View {
    let sliderPosition: Double
    let beforeImage: UIImage?
    let afterImage: UIImage
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Before image (background)
                if let beforeImage = beforeImage {
                    Image(uiImage: beforeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                
                // After image (clipped)
                Image(uiImage: afterImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(
                        Rectangle()
                            .offset(x: -geometry.size.width * (1 - sliderPosition))
                    )
                
                // Slider line
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .position(x: geometry.size.width * sliderPosition, y: geometry.size.height / 2)
                    .shadow(radius: 2)
            }
        }
        .cornerRadius(8)
    }
}

struct TransitionConfigurationView: View {
    @Binding var selectedTransition: TransitionType
    let beforeImage: UIImage?
    let afterImage: UIImage
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Transition Effect")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(TransitionType.allCases, id: \.self) { transition in
                    TransitionCard(
                        transition: transition,
                        isSelected: selectedTransition == transition,
                        onSelect: { selectedTransition = transition }
                    )
                }
            }
        }
    }
}

struct TransitionCard: View {
    let transition: TransitionType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .frame(height: 40)
                    .overlay(
                        Text(transition.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white : .primary)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Platform Section
struct PlatformSection: View {
    @Binding var selectedPlatform: SharingPlatform
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share To")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(SharingPlatform.allCases, id: \.self) { platform in
                    PlatformCard(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        onSelect: { selectedPlatform = platform }
                    )
                }
            }
        }
    }
}

struct PlatformCard: View {
    let platform: SharingPlatform
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : platform.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? platform.color : platform.color.opacity(0.1))
                    )
                
                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Caption Section
struct CaptionSection: View {
    @Binding var caption: String
    @Binding var selectedHashtags: Set<String>
    let availableHashtags: [String]
    let lesson: Lesson?
    let socialSharingManager: EnhancedSocialSharingManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Caption & Hashtags")
                .font(.headline)
            
            // Caption input
            VStack(alignment: .leading, spacing: 8) {
                Text("Caption")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextEditor(text: $caption)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Button("Use Default Caption") {
                    if let lesson = lesson {
                        caption = socialSharingManager.getDefaultCaption(for: lesson)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Hashtag selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Hashtags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(availableHashtags, id: \.self) { hashtag in
                        HashtagToggle(
                            hashtag: hashtag,
                            isSelected: selectedHashtags.contains(hashtag),
                            onToggle: {
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
}

struct HashtagToggle: View {
    let hashtag: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text("#\(hashtag)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Watermark Section
struct WatermarkSection: View {
    @Binding var includeWatermark: Bool
    let featureGateManager: FeatureGateManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watermark")
                .font(.headline)
            
            VStack(spacing: 12) {
                Toggle("Include Watermark", isOn: $includeWatermark)
                    .disabled(featureGateManager.canExportWithoutWatermark() != .allowed)
                
                if featureGateManager.canExportWithoutWatermark() != .allowed {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Pro to remove watermarks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    let isProcessing: Bool
    let onPreview: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Preview button
            Button(action: onPreview) {
                HStack {
                    Image(systemName: "eye")
                    Text("Preview")
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .disabled(isProcessing)
            
            // Share button
            Button(action: onShare) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Text(isProcessing ? "Preparing..." : "Share")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isProcessing)
        }
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let progress: Double
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                VStack(spacing: 8) {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(progress * 100))% Complete")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(32)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Preview Controller
struct PreviewViewController: View {
    let content: PreviewContent
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Group {
                    switch content {
                    case .image(let image):
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipped()
                        
                    case .video(let url):
                        // Video player would go here
                        VStack {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Video Preview")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(url.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                    case .beforeAfter(let before, let after):
                        HStack(spacing: 0) {
                            Image(uiImage: before)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                            
                            Image(uiImage: after)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                        .clipped()
                    }
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

