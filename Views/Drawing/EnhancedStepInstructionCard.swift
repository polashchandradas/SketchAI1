import SwiftUI
import UIKit

// MARK: - Enhanced Step Instruction Card with Real-time Feedback
struct EnhancedStepInstructionCard: View {
    let step: LessonStep
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    let accuracy: Double
    let canProgress: Bool
    let showHint: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onDismiss: () -> Void
    let onDismissHint: () -> Void
    let isLastStep: Bool
    
    @State private var showAccuracyDetails = false
    @State private var pulseAccuracy = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with enhanced progress
            EnhancedHeaderSection(
                currentStep: currentStep,
                totalSteps: totalSteps,
                progress: progress,
                accuracy: accuracy,
                onDismiss: onDismiss
            )
            
            // Main instruction with visual enhancements
            InstructionSection(
                instruction: step.instruction,
                shapeType: step.shapeType,
                accuracy: accuracy
            )
            
            // Real-time feedback section
            if accuracy > 0 {
                RealTimeFeedbackSection(
                    accuracy: accuracy,
                    canProgress: canProgress,
                    showDetails: $showAccuracyDetails
                )
            }
            
            // Hint section
            if showHint {
                HintSection(
                    shapeType: step.shapeType,
                    onDismiss: onDismissHint
                )
            }
            
            // Enhanced navigation
            NavigationSection(
                currentStep: currentStep,
                totalSteps: totalSteps,
                canProgress: canProgress,
                isLastStep: isLastStep,
                onNext: onNext,
                onPrevious: onPrevious
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        .scaleEffect(accuracy > 0.8 ? 1.02 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: accuracy)
    }
}

// MARK: - Enhanced Header Section
struct EnhancedHeaderSection: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    let accuracy: Double
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Step \(currentStep) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Drawing Guide")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Accuracy indicator
                if accuracy > 0 {
                    AccuracyBadge(accuracy: accuracy)
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            }
            
            // Enhanced progress bar with segments
            SegmentedProgressBar(
                currentStep: currentStep,
                totalSteps: totalSteps,
                progress: progress
            )
        }
    }
}

// MARK: - Accuracy Badge
struct AccuracyBadge: View {
    let accuracy: Double
    
    var badgeColor: Color {
        switch accuracy {
        case 0.8...: return .green
        case 0.6...: return .orange
        case 0.3...: return .yellow
        default: return .red
        }
    }
    
    var badgeIcon: String {
        switch accuracy {
        case 0.8...: return "checkmark.circle.fill"
        case 0.6...: return "checkmark.circle"
        case 0.3...: return "exclamationmark.circle"
        default: return "xmark.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: badgeIcon)
                .font(.caption)
            Text("\(Int(accuracy * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor)
        .cornerRadius(8)
        .scaleEffect(accuracy > 0.8 ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: accuracy)
    }
}

// MARK: - Segmented Progress Bar
struct SegmentedProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...totalSteps, id: \.self) { stepIndex in
                Rectangle()
                    .fill(stepColor(for: stepIndex))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .cornerRadius(2)
    }
    
    private func stepColor(for stepIndex: Int) -> Color {
        if stepIndex < currentStep {
            return .green
        } else if stepIndex == currentStep {
            return .blue.opacity(min(1.0, progress + 0.3))
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Instruction Section
struct InstructionSection: View {
    let instruction: String
    let shapeType: ShapeType
    let accuracy: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Shape type icon
            ShapeTypeIcon(shapeType: shapeType, accuracy: accuracy)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(instruction)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                if accuracy > 0 {
                    Text(feedbackText)
                        .font(.caption)
                        .foregroundColor(feedbackColor)
                        .animation(.easeInOut(duration: 0.3), value: accuracy)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var feedbackText: String {
        switch accuracy {
        case 0.9...: return "Excellent work! 🌟"
        case 0.8...: return "Great job! ✨"
        case 0.6...: return "Good progress! 👍"
        case 0.4...: return "Keep trying! 💪"
        default: return "Follow the guides 📍"
        }
    }
    
    private var feedbackColor: Color {
        switch accuracy {
        case 0.8...: return .green
        case 0.6...: return .blue
        case 0.4...: return .orange
        default: return .red
        }
    }
}

// MARK: - Shape Type Icon
struct ShapeTypeIcon: View {
    let shapeType: ShapeType
    let accuracy: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 44, height: 44)
            
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.white)
        }
        .scaleEffect(accuracy > 0.7 ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: accuracy)
    }
    
    private var iconName: String {
        switch shapeType {
        case .circle: return "circle"
        case .oval: return "oval"
        case .rectangle: return "rectangle"
        case .line: return "minus"
        case .curve: return "scribble"
        case .polygon: return "triangle"
        }
    }
    
    private var iconBackgroundColor: Color {
        switch accuracy {
        case 0.8...: return .green
        case 0.6...: return .blue
        case 0.3...: return .orange
        default: return .gray
        }
    }
}

// MARK: - Real-time Feedback Section
struct RealTimeFeedbackSection: View {
    let accuracy: Double
    let canProgress: Bool
    @Binding var showDetails: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Drawing Progress")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        showDetails.toggle()
                    }
                } label: {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Progress visualization
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: CGFloat(accuracy) * 200, height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.5), value: accuracy)
            }
            .frame(width: 200)
            
            if showDetails {
                AccuracyDetailsView(accuracy: accuracy, canProgress: canProgress)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Accuracy Details View
struct AccuracyDetailsView: View {
    let accuracy: Double
    let canProgress: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Accuracy: \(Int(accuracy * 100))%")
                    .font(.caption)
                Spacer()
                Text(canProgress ? "Ready to continue!" : "Keep practicing")
                    .font(.caption)
                    .foregroundColor(canProgress ? .green : .orange)
            }
            
            // Visual accuracy breakdown
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(accuracy > Double(index) * 0.2 ? .green : .gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                
                Text("Target: 60%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Hint Section
struct HintSection: View {
    let shapeType: ShapeType
    let onDismiss: () -> Void
    
    @State private var showHintAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .scaleEffect(showHintAnimation ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showHintAnimation)
                
                Text("Helpful Tip")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Got it", action: onDismiss)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            Text(hintText)
                .font(.caption)
                .foregroundColor(.primary)
                .padding(.leading, 24)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            showHintAnimation = true
        }
        .onDisappear {
            showHintAnimation = false
        }
    }
    
    private var hintText: String {
        switch shapeType {
        case .circle:
            return "Try drawing in one smooth motion. Start at the top and go clockwise. Keep your distance from the center consistent."
        case .oval:
            return "Draw like a circle but stretch it. The longer axis should be about 1.5 times the shorter one."
        case .rectangle:
            return "Start with one corner and draw straight lines. Use the guides to keep your corners at 90-degree angles."
        case .line:
            return "Draw confidently from start to finish. Try to complete the line in one smooth stroke."
        case .curve:
            return "Follow the guide smoothly. Don't worry about perfection - focus on the overall flow and direction."
        case .polygon:
            return "Connect the points with straight lines. Take your time to make clean connections at each corner."
        }
    }
}

// MARK: - Navigation Section
struct NavigationSection: View {
    let currentStep: Int
    let totalSteps: Int
    let canProgress: Bool
    let isLastStep: Bool
    let onNext: () -> Void
    let onPrevious: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Previous button
            if currentStep > 1 {
                Button(action: onPrevious) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            // Next/Finish button
            Button(action: onNext) {
                HStack {
                    Text(isLastStep ? "Finish" : "Next")
                    if !isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    LinearGradient(
                        colors: canProgress ? [.green, .blue] : [.gray, .gray.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .scaleEffect(canProgress ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: canProgress)
            }
            .disabled(!canProgress && !isLastStep)
        }
    }
}

#Preview {
    EnhancedStepInstructionCard(
        step: LessonStep(
            stepNumber: 1,
            instruction: "Draw a circle for the basic head shape. This forms the foundation of your portrait.",
            guidancePoints: [],
            shapeType: .circle
        ),
        currentStep: 1,
        totalSteps: 5,
        progress: 0.2,
        accuracy: 0.75,
        canProgress: true,
        showHint: true,
        onNext: {},
        onPrevious: {},
        onDismiss: {},
        onDismissHint: {},
        isLastStep: false
    )
    .padding()
}

