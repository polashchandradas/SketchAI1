import SwiftUI
import AVFoundation
import AVKit
import Combine

// MARK: - Enhanced Video Preview Sheet
struct VideoPreviewSheet: View {
    let videoURL: URL
    let lesson: Lesson
    let onShare: (SocialPlatform) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var playerManager = VideoPlayerManager()
    @StateObject private var socialSharingManager = EnhancedSocialSharingManager()
    
    @State private var showingControls = true
    @State private var showingShareOptions = false
    @State private var controlsTimer: Timer?
    @State private var isFullScreen = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Video Player Section
                        videoPlayerSection(geometry: geometry)
                        
                        // Controls and Info Section
                        if !isFullScreen {
                            videoInfoSection
                        }
                    }
                    
                    // Overlay Controls
                    if showingControls {
                        videoControlsOverlay
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isFullScreen)
            .onAppear {
                playerManager.setupPlayer(with: videoURL)
                startControlsTimer()
            }
            .onDisappear {
                playerManager.cleanup()
                controlsTimer?.invalidate()
            }
            .onTapGesture {
                toggleControlsVisibility()
            }
            .sheet(isPresented: $showingShareOptions) {
                shareOptionsSheet
            }
        }
    }
    
    // MARK: - Video Player Section
    private func videoPlayerSection(geometry: GeometryProxy) -> some View {
        ZStack {
            // Video Player
            CustomVideoPlayer(playerManager: playerManager)
                .frame(height: isFullScreen ? geometry.size.height : geometry.size.height * 0.6)
                .background(Color.black)
                .cornerRadius(isFullScreen ? 0 : 12)
                .clipped()
            
            // Loading Indicator
            if playerManager.isLoading {
                ProgressView("Loading video...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
            }
            
            // Error State
            if let error = playerManager.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                    
                    Text("Video Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Video Controls Overlay
    private var videoControlsOverlay: some View {
        VStack {
            // Top Controls
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                
                Spacer()
                
                Button(action: { showingShareOptions = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                
                Button(action: toggleFullScreen) {
                    Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
            }
            .padding(.horizontal)
            .padding(.top, isFullScreen ? 50 : 0)
            
            Spacer()
            
            // Center Play/Pause Button
            Button(action: playerManager.togglePlayPause) {
                Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            
            Spacer()
            
            // Bottom Controls
            bottomControls
                .padding(.bottom, isFullScreen ? 50 : 20)
        }
        .opacity(showingControls ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3), value: showingControls)
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 12) {
            // Progress Bar with Scrubbing
            VStack(spacing: 8) {
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatTime(playerManager.duration))
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                // Custom Scrubber
                VideoScrubber(
                    currentTime: playerManager.currentTime,
                    duration: playerManager.duration,
                    onScrub: { time in
                        playerManager.seek(to: time)
                    }
                )
            }
            .padding(.horizontal)
            
            // Playback Controls
            HStack(spacing: 30) {
                // Rewind 10 seconds
                Button(action: { playerManager.seek(to: max(0, playerManager.currentTime - 10)) }) {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Play/Pause
                Button(action: playerManager.togglePlayPause) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
                
                // Forward 10 seconds
                Button(action: { playerManager.seek(to: min(playerManager.duration, playerManager.currentTime + 10)) }) {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Speed Control
                Menu {
                    ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { speed in
                        Button(action: { playerManager.setPlaybackRate(Float(speed)) }) {
                            HStack {
                                Text("\(speed, specifier: "%.2g")x")
                                if playerManager.playbackRate == Float(speed) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text("\(playerManager.playbackRate, specifier: "%.2g")x")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Video Info Section
    private var videoInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Lesson Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(lesson.category.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(lesson.difficulty.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(lesson.difficulty.color.opacity(0.2))
                    .foregroundColor(lesson.difficulty.color)
                    .cornerRadius(8)
            }
            
            // Video Stats
            HStack(spacing: 20) {
                VideoStatItem(
                    icon: "clock",
                    label: "Duration",
                    value: formatTime(playerManager.duration)
                )
                
                VideoStatItem(
                    icon: "doc.text",
                    label: "Size",
                    value: getFileSize()
                )
                
                VideoStatItem(
                    icon: "video",
                    label: "Format",
                    value: "MP4"
                )
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { showingShareOptions = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: saveToPhotos) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Share Options Sheet
    private var shareOptionsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share Your Creation")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(socialSharingManager.supportedPlatforms, id: \.self) { platform in
                        Button(action: {
                            onShare(platform)
                            showingShareOptions = false
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: platform.icon)
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                Text(platform.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(height: 80)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingShareOptions = false
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    private func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingControls.toggle()
        }
        
        if showingControls {
            startControlsTimer()
        } else {
            controlsTimer?.invalidate()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showingControls = false
            }
        }
    }
    
    private func toggleFullScreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFullScreen.toggle()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getFileSize() -> String {
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
    
    private func saveToPhotos() {
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
}

// MARK: - Custom Video Player
struct CustomVideoPlayer: UIViewRepresentable {
    let playerManager: VideoPlayerManager
    
    func makeUIView(context: Context) -> UIView {
        return playerManager.playerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates handled by PlayerManager
    }
}

// MARK: - Video Scrubber
struct VideoScrubber: View {
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onScrub: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress
                Rectangle()
                    .fill(Color.white)
                    .frame(width: progressWidth(geometry.size.width), height: 4)
                    .cornerRadius(2)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .offset(x: thumbOffset(geometry.size.width))
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
            }
        }
        .frame(height: 20)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    
                    let progress = max(0, min(1, value.location.x / 400)) // Fixed width for consistent behavior
                    dragValue = progress
                    onScrub(progress * duration)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        let progress = isDragging ? dragValue : (currentTime / duration)
        return totalWidth * CGFloat(progress)
    }
    
    private func thumbOffset(_ totalWidth: CGFloat) -> CGFloat {
        guard duration > 0 else { return 0 }
        let progress = isDragging ? dragValue : (currentTime / duration)
        return (totalWidth * CGFloat(progress)) - 8 // Adjust for thumb size
    }
}

// MARK: - Video Stat Item
struct VideoStatItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Video Player Manager
class VideoPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var error: Error?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    var playerView: UIView
    private var playerLayer: AVPlayerLayer
    
    init() {
        playerView = UIView()
        playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspect
        playerView.layer.addSublayer(playerLayer)
    }
    
    func setupPlayer(with url: URL) {
        isLoading = true
        player = AVPlayer(url: url)
        playerLayer.player = player
        
        // Add time observer
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.1, preferredTimescale: timeScale)
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
        
        // Observe player status
        player?.currentItem?.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.duration = CMTimeGetSeconds(self?.player?.currentItem?.duration ?? .zero)
                case .failed:
                    self?.isLoading = false
                    self?.error = self?.player?.currentItem?.error
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Layout player layer
        DispatchQueue.main.async {
            self.playerLayer.frame = self.playerView.bounds
        }
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        player?.rate = rate
    }
    
    func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player?.pause()
        player = nil
    }
    
    private var cancellables = Set<AnyCancellable>()
}
