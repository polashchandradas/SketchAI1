import SwiftUI
import UIKit

// MARK: - Enhanced Loading States and Progress Indicators
// Beautiful, engaging loading animations that make waiting feel premium

// MARK: - Pulse Loading Indicator
struct PulseLoadingIndicator: View {
    let color: Color
    let size: CGFloat
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.6
    
    init(color: Color = .blue, size: CGFloat = 60) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(color.opacity(opacity), lineWidth: 2)
                    .scaleEffect(scale + CGFloat(index) * 0.2)
                    .opacity(1.0 - Double(index) * 0.3)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(index) * 0.2),
                        value: scale
                    )
            }
            
            Circle()
                .fill(color)
                .frame(width: size * 0.3, height: size * 0.3)
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: scale
                )
        }
        .frame(width: size, height: size)
        .onAppear {
            scale = 1.2
            opacity = 0.2
        }
    }
}

// MARK: - Morphing Dots Loader
struct MorphingDotsLoader: View {
    let color: Color
    let dotSize: CGFloat
    
    @State private var animationPhase: Double = 0
    
    init(color: Color = .blue, dotSize: CGFloat = 12) {
        self.color = color
        self.dotSize = dotSize
    }
    
    var body: some View {
        HStack(spacing: dotSize * 0.5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(calculateScale(for: index))
                    .opacity(calculateOpacity(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1.0
        }
    }
    
    private func calculateScale(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 0.3).truncatingRemainder(dividingBy: 1.0)
        return 0.5 + sin(phase * .pi) * 0.5
    }
    
    private func calculateOpacity(for index: Int) -> Double {
        let phase = (animationPhase + Double(index) * 0.3).truncatingRemainder(dividingBy: 1.0)
        return 0.3 + sin(phase * .pi) * 0.7
    }
}

// MARK: - Gradient Ring Loader
struct GradientRingLoader: View {
    let colors: [Color]
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var rotation: Double = 0
    
    init(colors: [Color] = [.blue, .purple, .pink], size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.colors = colors
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1.0)
            .stroke(
                AngularGradient(
                    colors: colors,
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Bouncing Bars Loader
struct BouncingBarsLoader: View {
    let color: Color
    let barCount: Int
    let barWidth: CGFloat
    let maxHeight: CGFloat
    
    @State private var animationPhase: Double = 0
    
    init(color: Color = .blue, barCount: Int = 5, barWidth: CGFloat = 4, maxHeight: CGFloat = 40) {
        self.color = color
        self.barCount = barCount
        self.barWidth = barWidth
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        HStack(spacing: barWidth * 0.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: barWidth / 2)
                    .fill(color)
                    .frame(width: barWidth, height: calculateHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .onAppear {
            animationPhase = 1.0
        }
    }
    
    private func calculateHeight(for index: Int) -> CGFloat {
        let phase = (animationPhase + Double(index) * 0.2).truncatingRemainder(dividingBy: 1.0)
        let height = maxHeight * 0.3 + (sin(phase * .pi) * maxHeight * 0.7)
        return max(height, maxHeight * 0.2)
    }
}

// MARK: - Progress Ring with Percentage
struct EnhancedProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let showPercentage: Bool
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        color: Color = .blue,
        size: CGFloat = 80,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [color.opacity(0.8), color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animatedProgress)
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    
                    Text("%")
                        .font(.caption)
                        .foregroundColor(color.opacity(0.8))
                }
                .animation(.easeInOut(duration: 0.3), value: animatedProgress)
            }
        }
        .frame(width: size, height: size)
        .onChange(of: progress) { newProgress in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = newProgress
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerLoadingView<Content: View>: View {
    let content: Content
    let isLoading: Bool
    
    @State private var shimmerOffset: CGFloat = -200
    
    init(isLoading: Bool, @ViewBuilder content: () -> Content) {
        self.isLoading = isLoading
        self.content = content()
    }
    
    var body: some View {
        content
            .overlay(
                shimmerOverlay
                    .opacity(isLoading ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
    
    private var shimmerOverlay: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .rotationEffect(.degrees(15))
            .offset(x: shimmerOffset)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 200
                }
            }
    }
}

// MARK: - Skeleton Loading Placeholders
struct SkeletonLoadingView: View {
    let lines: Int
    let cornerRadius: CGFloat
    
    @State private var opacity: Double = 0.3
    
    init(lines: Int = 3, cornerRadius: CGFloat = 8) {
        self.lines = lines
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lines, id: \.self) { index in
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(opacity))
                    .frame(height: 16)
                    .frame(maxWidth: index == lines - 1 ? .infinity * 0.7 : .infinity)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.1),
                        value: opacity
                    )
            }
        }
        .onAppear {
            opacity = 0.8
        }
    }
}

// MARK: - Loading State Container
struct LoadingStateContainer<Content: View, LoadingContent: View>: View {
    let isLoading: Bool
    let content: Content
    let loadingContent: LoadingContent
    
    init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder loadingContent: () -> LoadingContent
    ) {
        self.isLoading = isLoading
        self.content = content()
        self.loadingContent = loadingContent()
    }
    
    var body: some View {
        ZStack {
            content
                .opacity(isLoading ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: isLoading)
            
            if isLoading {
                loadingContent
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Success Animation
struct SuccessAnimation: View {
    @Binding var isVisible: Bool
    let color: Color
    let size: CGFloat
    
    @State private var checkmarkProgress: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -180
    
    init(isVisible: Binding<Bool>, color: Color = .green, size: CGFloat = 60) {
        self._isVisible = isVisible
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            if isVisible {
                // Background circle
                Circle()
                    .fill(color.opacity(0.1))
                    .scaleEffect(scale)
                
                Circle()
                    .stroke(color, lineWidth: 3)
                    .scaleEffect(scale)
                
                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(color)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
            }
        }
        .frame(width: size, height: size)
        .onChange(of: isVisible) { visible in
            if visible {
                playSuccessAnimation()
            } else {
                resetAnimation()
            }
        }
    }
    
    private func playSuccessAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.2
            rotation = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                scale = 1.0
            }
        }
        
        withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
            checkmarkProgress = 1.0
        }
    }
    
    private func resetAnimation() {
        scale = 0.8
        rotation = -180
        checkmarkProgress = 0
    }
}

// MARK: - View Extensions
extension View {
    func shimmerLoading(isLoading: Bool) -> some View {
        ShimmerLoadingView(isLoading: isLoading) {
            self
        }
    }
    
    func loadingState<LoadingContent: View>(
        isLoading: Bool,
        @ViewBuilder loadingContent: () -> LoadingContent
    ) -> some View {
        LoadingStateContainer(
            isLoading: isLoading,
            content: { self },
            loadingContent: loadingContent
        )
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 40) {
            Group {
                VStack(spacing: 20) {
                    Text("Loading Indicators")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 30) {
                        PulseLoadingIndicator()
                        MorphingDotsLoader()
                        GradientRingLoader()
                    }
                    
                    BouncingBarsLoader()
                }
                
                VStack(spacing: 20) {
                    Text("Progress Indicators")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 30) {
                        EnhancedProgressRing(progress: 0.3)
                        EnhancedProgressRing(progress: 0.7, color: .orange)
                        EnhancedProgressRing(progress: 0.9, color: .green)
                    }
                }
                
                VStack(spacing: 20) {
                    Text("Skeleton Loading")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        SkeletonLoadingView(lines: 3)
                        SkeletonLoadingView(lines: 2, cornerRadius: 12)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
            
            VStack(spacing: 20) {
                Text("Success Animation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Button("Show Success") {
                    // Success animation would be triggered here
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

