import SwiftUI

// MARK: - Video Recording Overlay
struct VideoRecordingOverlay: View {
    let isRecording: Bool
    let recordingProgress: Double
    let recordingDuration: TimeInterval
    let frameCount: Int
    let estimatedFileSize: String
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var showRecordingStats = false
    
    var body: some View {
        ZStack {
            if isRecording {
                // Recording status overlay
                VStack {
                    HStack {
                        // Recording indicator
                        HStack(spacing: 8) {
                            // Pulsing red dot
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true),
                                    value: pulseScale
                                )
                                .onAppear {
                                    pulseScale = 1.4
                                }
                            
                            // Recording text and duration
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RECORDING")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                
                                Text(formatDuration(recordingDuration))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .monospacedDigit()
                            }
                        }
                        
                        Spacer()
                        
                        // Recording stats toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showRecordingStats.toggle()
                            }
                        } label: {
                            Image(systemName: showRecordingStats ? "info.circle.fill" : "info.circle")
                                .font(.title3)
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.3)).frame(width: 32, height: 32))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Recording statistics (expandable)
                    if showRecordingStats {
                        RecordingStatsView(
                            frameCount: frameCount,
                            estimatedFileSize: estimatedFileSize,
                            recordingProgress: recordingProgress
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                
                // Progress indicator at bottom
                VStack {
                    Spacer()
                    
                    RecordingProgressBar(progress: recordingProgress)
                        .padding(.bottom, 20)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Recording Statistics View
struct RecordingStatsView: View {
    let frameCount: Int
    let estimatedFileSize: String
    let recordingProgress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Frames", value: "\(frameCount)")
            StatRow(label: "File Size", value: estimatedFileSize)
            StatRow(label: "Progress", value: "\(Int(recordingProgress * 100))%")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .monospacedDigit()
        }
    }
}

// MARK: - Recording Progress Bar
struct RecordingProgressBar: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.red)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.1), value: progress)
                }
            }
            .frame(height: 4)
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Recording State Indicator
struct RecordingStateIndicator: View {
    let isRecording: Bool
    let isPaused: Bool
    let isProcessing: Bool
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 8) {
            // State icon
            Group {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.8)
                } else if isPaused {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange)
                } else if isRecording {
                    Image(systemName: "record.circle.fill")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .font(.title2)
            
            // State text
            Text(stateText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(stateColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .scaleEffect(isRecording ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
    
    private var stateText: String {
        if isProcessing {
            return "Processing..."
        } else if isPaused {
            return "Paused"
        } else if isRecording {
            return "Recording"
        } else {
            return "Ready"
        }
    }
    
    private var stateColor: Color {
        if isProcessing {
            return .blue
        } else if isPaused {
            return .orange
        } else if isRecording {
            return .red
        } else {
            return .gray
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VideoRecordingOverlay(
            isRecording: true,
            recordingProgress: 0.65,
            recordingDuration: 45.3,
            frameCount: 1359,
            estimatedFileSize: "12.4 MB"
        )
    }
}

