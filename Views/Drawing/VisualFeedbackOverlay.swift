import SwiftUI
import CoreGraphics

// MARK: - Visual Feedback Overlay System
struct VisualFeedbackOverlay: View {
    let strokeFeedback: StrokeFeedback?
    let currentGuide: DrawingGuide?
    let showFeedback: Bool
    let showCelebration: Bool
    let stepProgress: Double
    let canvasSize: CGSize
    
    @State private var animationPhase: Double = 0
    @State private var celebrationScale: Double = 0.5
    @State private var pulseAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // Guide overlay
            if let guide = currentGuide {
                GuideShapesOverlay(
                    guide: guide,
                    canvasSize: canvasSize,
                    animationPhase: animationPhase
                )
            }
            
            // Correction points overlay
            if showFeedback, let feedback = strokeFeedback, !feedback.isCorrect {
                CorrectionPointsOverlay(
                    correctionPoints: feedback.correctionPoints,
                    canvasSize: canvasSize
                )
            }
            
            // Progress indicators
            ProgressIndicatorsOverlay(
                progress: stepProgress,
                showCelebration: showCelebration,
                celebrationScale: celebrationScale
            )
            
            // Feedback messages
            if showFeedback, let feedback = strokeFeedback {
                FeedbackMessagesOverlay(
                    feedback: feedback,
                    showFeedback: showFeedback
                )
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: showCelebration) { celebrating in
            if celebrating {
                startCelebrationAnimation()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
        
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation.toggle()
        }
    }
    
    private func startCelebrationAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            celebrationScale = 1.2
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                celebrationScale = 1.0
            }
        }
    }
}

// MARK: - Guide Shapes Overlay
struct GuideShapesOverlay: View {
    let guide: DrawingGuide
    let canvasSize: CGSize
    let animationPhase: Double
    
    var body: some View {
        Canvas { context, size in
            for (index, shape) in guide.shapes.enumerated() {
                drawGuideShape(context: context, shape: shape, index: index, size: size)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }
    
    private func drawGuideShape(context: GraphicsContext, shape: GuideShape, index: Int, size: CGSize) {
        let path = createShapePath(shape: shape, size: size)
        
        // Animated stroke style
        let strokeStyle = createAnimatedStrokeStyle(shape: shape)
        
        // Apply opacity based on animation phase
        let opacity = 0.3 + (sin(animationPhase * .pi * 2 + Double(index) * 0.5) * 0.2)
        
        context.stroke(
            path,
            with: .color(shape.color.opacity(opacity)),
            style: strokeStyle
        )
        
        // Draw target points if any
        for point in shape.points {
            let targetCircle = Path { path in
                path.addPath(Path(ellipseIn: CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)))
            }
            
            context.fill(
                targetCircle,
                with: .color(shape.color.opacity(0.6))
            )
        }
    }
    
    private func createShapePath(shape: GuideShape, size: CGSize) -> Path {
        var path = Path()
        
        switch shape.type {
        case .circle:
            let radius = shape.dimensions.width / 2
            path.addPath(Path(ellipseIn: CGRect(
                x: shape.center.x - radius,
                y: shape.center.y - radius,
                width: shape.dimensions.width,
                height: shape.dimensions.height
            )))
            
        case .oval:
            path.addPath(Path(ellipseIn: CGRect(
                x: shape.center.x - shape.dimensions.width / 2,
                y: shape.center.y - shape.dimensions.height / 2,
                width: shape.dimensions.width,
                height: shape.dimensions.height
            )))
            
        case .rectangle:
            path.addPath(Path(CGRect(
                x: shape.center.x - shape.dimensions.width / 2,
                y: shape.center.y - shape.dimensions.height / 2,
                width: shape.dimensions.width,
                height: shape.dimensions.height
            )))
            
        case .line:
            if shape.points.count >= 2 {
                path.move(to: shape.points[0])
                path.addLine(to: shape.points[1])
            }
            
        case .curve:
            if shape.points.count >= 3 {
                path.move(to: shape.points[0])
                path.addQuadCurve(to: shape.points[2], control: shape.points[1])
            }
            
        case .polygon:
            if !shape.points.isEmpty {
                path.move(to: shape.points[0])
                for point in shape.points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
        }
        
        return path
    }
    
    private func createAnimatedStrokeStyle(shape: GuideShape) -> StrokeStyle {
        let dashPhase = animationPhase * 20
        
        switch shape.style {
        case .solid:
            return StrokeStyle(lineWidth: shape.strokeWidth, lineCap: .round, lineJoin: .round)
        case .dashed(let pattern):
            return StrokeStyle(
                lineWidth: shape.strokeWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: pattern,
                dashPhase: dashPhase
            )
        case .dotted:
            return StrokeStyle(
                lineWidth: shape.strokeWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: [2, 4],
                dashPhase: dashPhase
            )
        }
    }
}

// MARK: - Correction Points Overlay
struct CorrectionPointsOverlay: View {
    let correctionPoints: [CGPoint]
    let canvasSize: CGSize
    
    @State private var pulseScale: Double = 1.0
    
    var body: some View {
        Canvas { context, size in
            for (index, point) in correctionPoints.enumerated() {
                drawCorrectionPoint(context: context, point: point, index: index)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func drawCorrectionPoint(context: GraphicsContext, point: CGPoint, index: Int) {
        // Outer ring
        let outerCircle = Path { path in
            let radius = 8.0 * pulseScale
            path.addPath(Path(ellipseIn: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )))
        }
        
        context.stroke(
            outerCircle,
            with: .color(.red.opacity(0.8)),
            style: StrokeStyle(lineWidth: 2)
        )
        
        // Inner dot
        let innerCircle = Path { path in
            let radius = 3.0
            path.addPath(Path(ellipseIn: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )))
        }
        
        context.fill(innerCircle, with: .color(.red))
        
        // Arrow pointing to correction (if multiple points)
        if correctionPoints.count > 1 && index < correctionPoints.count - 1 {
            let nextPoint = correctionPoints[index + 1]
            drawArrow(context: context, from: point, to: nextPoint)
        }
    }
    
    private func drawArrow(context: GraphicsContext, from start: CGPoint, to end: CGPoint) {
        let arrowPath = Path { path in
            path.move(to: start)
            path.addLine(to: end)
            
            // Arrow head
            let angle = atan2(end.y - start.y, end.x - start.x)
            let arrowLength: CGFloat = 10
            let arrowAngle: CGFloat = .pi / 6
            
            let arrowPoint1 = CGPoint(
                x: end.x - arrowLength * cos(angle - arrowAngle),
                y: end.y - arrowLength * sin(angle - arrowAngle)
            )
            
            let arrowPoint2 = CGPoint(
                x: end.x - arrowLength * cos(angle + arrowAngle),
                y: end.y - arrowLength * sin(angle + arrowAngle)
            )
            
            path.move(to: end)
            path.addLine(to: arrowPoint1)
            path.move(to: end)
            path.addLine(to: arrowPoint2)
        }
        
        context.stroke(
            arrowPath,
            with: .color(.red.opacity(0.6)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.3
        }
    }
}

// MARK: - Progress Indicators Overlay
struct ProgressIndicatorsOverlay: View {
    let progress: Double
    let showCelebration: Bool
    let celebrationScale: Double
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Step progress indicator
                VStack {
                    CircularProgressView(progress: progress)
                        .frame(width: 60, height: 60)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .scaleEffect(showCelebration ? celebrationScale : 1.0)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(colors: [.blue, .green], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Feedback Messages Overlay
struct FeedbackMessagesOverlay: View {
    let feedback: StrokeFeedback
    let showFeedback: Bool
    
    @State private var messageOffset: CGFloat = 0
    @State private var messageOpacity: Double = 0
    
    var body: some View {
        VStack {
            Spacer()
            
            if showFeedback && !feedback.suggestions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(feedback.suggestions.prefix(2), id: \.self) { suggestion in
                        FeedbackMessageCard(
                            message: suggestion,
                            isPositive: feedback.isCorrect
                        )
                    }
                }
                .offset(y: messageOffset)
                .opacity(messageOpacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messageOffset = -20
                        messageOpacity = 1.0
                    }
                }
                .onDisappear {
                    withAnimation(.easeOut(duration: 0.3)) {
                        messageOffset = 20
                        messageOpacity = 0.0
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Feedback Message Card
struct FeedbackMessageCard: View {
    let message: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "info.circle.fill")
                .foregroundColor(isPositive ? .green : .orange)
                .font(.title3)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Celebration Effect
struct CelebrationEffectOverlay: View {
    let showCelebration: Bool
    
    @State private var particles: [CelebrationParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onChange(of: showCelebration) { celebrating in
            if celebrating {
                createCelebrationParticles()
            }
        }
    }
    
    private func createCelebrationParticles() {
        particles.removeAll()
        
        let colors: [Color] = [.yellow, .orange, .green, .blue, .purple, .pink]
        
        for i in 0..<15 {
            let particle = CelebrationParticle(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 100...300),
                    y: CGFloat.random(in: 200...400)
                ),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...12),
                opacity: 1.0,
                scale: 0.1
            )
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            for i in particles.indices {
                particles[i].scale = 1.0
            }
        }
        
        // Fade out particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 1.0)) {
                for i in particles.indices {
                    particles[i].opacity = 0.0
                    particles[i].position.y -= 50
                }
            }
        }
    }
}

// MARK: - Celebration Particle
struct CelebrationParticle {
    let id: Int
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
}

#Preview {
    VisualFeedbackOverlay(
        strokeFeedback: StrokeFeedback(
            accuracy: 0.7,
            suggestions: ["Great start! Try to make your circle more round."],
            correctionPoints: [CGPoint(x: 100, y: 100), CGPoint(x: 150, y: 150)],
            isCorrect: false
        ),
        currentGuide: nil,
        showFeedback: true,
        showCelebration: false,
        stepProgress: 0.7,
        canvasSize: CGSize(width: 300, height: 400)
    )
}

