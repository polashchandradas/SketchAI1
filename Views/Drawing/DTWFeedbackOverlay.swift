import SwiftUI

// MARK: - Enhanced Feedback Overlay for Unified Core ML System
struct DTWFeedbackOverlay: View {
    @ObservedObject var coordinator: DrawingCanvasCoordinator
    @State private var showPerformanceIndicator = false
    @State private var hapticFeedbackEnabled = true
    
    var body: some View {
        ZStack {
            // PHASE 2: Performance-aware DTW Insights Panel
            if coordinator.showDTWInsights {
                VStack {
                    Spacer()
                    
                    // Enhanced feedback panel for unified Core ML system
                    EnhancedDTWInsightsPanel(
                        coordinator: coordinator
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: coordinator.showDTWInsights)
                }
            }
            
            // PHASE 2: Enhanced real-time accuracy indicator with adaptive feedback
            if coordinator.currentAccuracy > 0 {
                VStack {
                    HStack {
                        Spacer()
                        
                        // Enhanced accuracy indicator for unified Core ML system
                        AdaptiveAccuracyIndicator(
                            accuracy: coordinator.dtwAccuracy,
                            confidence: coordinator.confidenceScore
                        )
                        .padding(.trailing)
                        .padding(.top, 50) // Below status bar
                        .onTapGesture {
                            showPerformanceIndicator.toggle()
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // PHASE 2: Performance status indicator (optional display)
            if showPerformanceIndicator {
                VStack {
                    HStack {
                        PerformanceStatusCard()
                        .padding(.leading)
                        .padding(.top, 100)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .onTapGesture {
                    showPerformanceIndicator = false
                }
            }
            
            // PHASE 2: Intelligent haptic feedback trigger
            OptimizedHapticFeedbackView(
                coordinator: coordinator,
                enabled: hapticFeedbackEnabled
            )
        }
        .onAppear {
            // Initialize feedback overlay for unified Core ML system
            print("🎯 [DTWFeedbackOverlay] Initialized for unified Core ML system")
        }
    }
}

// MARK: - User-Friendly Drawing Feedback Panel
struct UserFriendlyDrawingFeedback: View {
    @ObservedObject var coordinator: DrawingCanvasCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            // Simplified header with encouraging messaging
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    Text("Drawing Tips")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Simple confidence indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)
                    
                    Text(getConfidenceText())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Main encouraging feedback message
            HStack {
                Text(getUserFriendlyMessage())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(getMessageColor())
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Simplified progress indicators
            HStack(spacing: 12) {
                UserFriendlyMetricCard(
                    title: "Accuracy",
                    value: coordinator.dtwAccuracy,
                    icon: "target",
                    color: .blue,
                    description: getAccuracyDescription()
                )
                
                UserFriendlyMetricCard(
                    title: "Flow",
                    value: coordinator.temporalAccuracy,
                    icon: "waveform",
                    color: .green,
                    description: getFlowDescription()
                )
                
                UserFriendlyMetricCard(
                    title: "Control",
                    value: coordinator.velocityConsistency,
                    icon: "hand.point.up",
                    color: .orange,
                    description: getControlDescription()
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .padding(.bottom, 50) // Above tab bar
    }
    
    private var confidenceColor: Color {
        if coordinator.confidenceScore >= 0.8 {
            return .green
        } else if coordinator.confidenceScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func getConfidenceText() -> String {
        if coordinator.confidenceScore >= 0.8 {
            return "Great!"
        } else if coordinator.confidenceScore >= 0.6 {
            return "Good"
        } else {
            return "Keep going"
        }
    }
    
    private func getUserFriendlyMessage() -> String {
        let accuracy = coordinator.dtwAccuracy
        
        if accuracy >= 0.9 {
            return "🌟 Wow! You're following the guide like a pro artist!"
        } else if accuracy >= 0.8 {
            return "✨ Fantastic! You're really getting the hang of this!"
        } else if accuracy >= 0.6 {
            return "👍 You're doing great! Try to follow the guide a little closer"
        } else if accuracy >= 0.4 {
            return "💪 Keep going! Focus on the guide lines and you'll get it!"
        } else {
            return "🎨 Don't worry! Every amazing artist started right where you are - keep drawing and having fun!"
        }
    }
    
    private func getMessageColor() -> Color {
        let accuracy = coordinator.dtwAccuracy
        
        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .blue
        } else if accuracy >= 0.4 {
            return .orange
        } else {
            return .purple
        }
    }
    
    private func getAccuracyDescription() -> String {
        let accuracy = coordinator.dtwAccuracy
        if accuracy >= 0.8 { return "Perfect!" }
        else if accuracy >= 0.6 { return "Almost there!" }
        else { return "Keep going!" }
    }
    
    private func getFlowDescription() -> String {
        let flow = coordinator.temporalAccuracy
        if flow >= 0.8 { return "So smooth!" }
        else if flow >= 0.6 { return "Nice rhythm!" }
        else { return "Take your time" }
    }
    
    private func getControlDescription() -> String {
        let control = coordinator.velocityConsistency
        if control >= 0.8 { return "Great control!" }
        else if control >= 0.6 { return "Getting better!" }
        else { return "Keep practicing!" }
    }
}

// MARK: - User-Friendly Metric Card
struct UserFriendlyMetricCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            // Friendly icon with encouraging design
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Encouraging value display
            VStack(spacing: 4) {
                Text(getEncouragingPercentage())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Simplified progress indicator
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 3)
                .cornerRadius(1.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
    
    private func getEncouragingPercentage() -> String {
        let percentage = Int(value * 100)
        
        if percentage >= 90 {
            return "\(percentage)%"
        } else if percentage >= 70 {
            return "\(percentage)%"
        } else if percentage >= 50 {
            return "\(percentage)%"
        } else {
            return "\(percentage)%"
        }
    }
}

// MARK: - Legacy DTW Metric Card (for backward compatibility)
struct DTWMetricCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
            }
            
            // Value with progress indicator
            VStack(spacing: 4) {
                Text(String(format: "%.0f%%", value * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Mini progress bar
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Real-time Accuracy Indicator
struct DTWAccuracyIndicator: View {
    let accuracy: Double
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 8) {
            // AI indicator
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
            
            // Accuracy display
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", accuracy * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)
                
                Text("AI Score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var accuracyColor: Color {
        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.opacity(0.3)
        
        DTWFeedbackOverlay(coordinator: {
            let coordinator = DrawingCanvasCoordinator(drawingEngine: DrawingAlgorithmEngine())
            coordinator.showDTWInsights = true
            coordinator.dtwAccuracy = 0.85
            coordinator.temporalAccuracy = 0.78
            coordinator.velocityConsistency = 0.92
            coordinator.confidenceScore = 0.88
            coordinator.dtwFeedbackMessage = "🎯 Perfect path following!"
            coordinator.dtwFeedbackColor = .green
            return coordinator
        }())
    }
}

// MARK: - PHASE 2: Enhanced DTW Components

/// Enhanced Insights Panel for Unified Core ML System
struct EnhancedDTWInsightsPanel: View {
    @ObservedObject var coordinator: DrawingCanvasCoordinator
    
    var body: some View {
        VStack(spacing: 16) {
            // Enhanced header with performance status
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .font(.title3)
                    
                    Text("AI Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    // Core ML system indicator
                    CoreMLSystemBadge()
                }
                
                Spacer()
                
                // Enhanced confidence indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 6, height: 6)
                    
                    Text(String(format: "%.0f%% confident", coordinator.confidenceScore * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Enhanced feedback message for Core ML system
            HStack {
                Text(coordinator.dtwFeedbackMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(coordinator.dtwFeedbackColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            // Enhanced DTW Metrics Grid with real-time indicators
            HStack(spacing: 12) {
                EnhancedDTWMetricCard(
                    title: "Path",
                    value: coordinator.dtwAccuracy,
                    icon: "location.fill",
                    color: .blue,
                    isRealTime: true
                )
                
                EnhancedDTWMetricCard(
                    title: "Timing",
                    value: coordinator.temporalAccuracy,
                    icon: "speedometer",
                    color: .green,
                    isRealTime: true
                )
                
                EnhancedDTWMetricCard(
                    title: "Smoothness",
                    value: coordinator.velocityConsistency,
                    icon: "hand.draw.fill",
                    color: .orange,
                    isRealTime: true
                )
            }
            
            // Core ML system status
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.caption2)
                
                Text("Unified Core ML Analysis Active")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .padding(.bottom, 50) // Above tab bar
    }
    
    private var confidenceColor: Color {
        if coordinator.confidenceScore >= 0.8 {
            return .green
        } else if coordinator.confidenceScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
}

/// Core ML System Badge
struct CoreMLSystemBadge: View {
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(.purple)
                .frame(width: 4, height: 4)
            
            Text("CORE ML")
                .font(.caption2)
                .foregroundColor(.purple)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.purple.opacity(0.1))
        )
    }
}

/// PHASE 2: Enhanced DTW Metric Card with Real-time Indicators
struct EnhancedDTWMetricCard: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color
    let isRealTime: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Enhanced icon with real-time indicator
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                // Real-time pulse indicator
                if isRealTime {
                    Circle()
                        .stroke(color, lineWidth: 1)
                        .frame(width: 34, height: 34)
                        .opacity(0.6)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isRealTime)
                }
            }
            
            // Enhanced value display
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text(String(format: "%.0f%%", value * 100))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    if isRealTime {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.caption2)
                            .foregroundColor(color)
                    }
                }
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Enhanced progress bar
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 2)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Adaptive Accuracy Indicator for Core ML System
struct AdaptiveAccuracyIndicator: View {
    let accuracy: Double
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 8) {
            // Core ML AI indicator
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.caption)
                
                // Core ML system ring
                Circle()
                    .stroke(.purple, lineWidth: 1)
                    .frame(width: 36, height: 36)
                    .opacity(0.6)
            }
            
            // Enhanced accuracy display
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.0f%%", accuracy * 100))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(accuracyColor)
                
                Text("Core ML")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var accuracyColor: Color {
        if accuracy >= 0.8 {
            return .green
        } else if accuracy >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
}

/// Core ML System Status Card
struct PerformanceStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                
                Text("Core ML System")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("Mode:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Unified Analysis")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
            
            HStack {
                Text("Status:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Active")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

/// PHASE 2: Optimized Haptic Feedback View
struct OptimizedHapticFeedbackView: View {
    @ObservedObject var coordinator: DrawingCanvasCoordinator
    let enabled: Bool
    
    @State private var lastHapticTime = Date()
    private let hapticThrottleInterval: TimeInterval = 0.3 // Prevent haptic spam
    
    var body: some View {
        EmptyView()
            .onChange(of: coordinator.dtwAccuracy) { newAccuracy in
                triggerAdaptiveHaptic(for: newAccuracy)
            }
    }
    
    private func triggerAdaptiveHaptic(for accuracy: Double) {
        guard enabled else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastHapticTime) >= hapticThrottleInterval else { return }
        lastHapticTime = now
        
        // Core ML system haptic feedback
        if accuracy >= 0.9 {
            // Perfect - light success feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        } else if accuracy >= 0.7 {
            // Good - medium feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        } else if accuracy < 0.4 {
            // Needs improvement - error feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        }
    }
}

