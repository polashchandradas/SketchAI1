import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    @EnvironmentObject var monetizationService: MonetizationService
    @Environment(\.dismiss) private var dismiss
    @State private var showCanvas = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero section
                LessonHeroSection(lesson: lesson)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Lesson info
                    LessonInfoSection(lesson: lesson)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About This Lesson")
                            .font(.headline)
                        
                        Text(lesson.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    // Steps preview
                    LessonStepsSection(lesson: lesson)
                    
                    // What you'll learn
                    WhatYoullLearnSection(lesson: lesson)
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 120) // Space for start button
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            StartLessonButton(lesson: lesson) {
                monetizationService.featureGateManager.accessLesson(lesson) { canAccess in
                    if canAccess {
                        showCanvas = true
                    }
                    // Paywall will be shown automatically by FeatureGateManager if needed
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showCanvas) {
            DrawingCanvasView(lesson: lesson)
        }
    }
}

struct LessonHeroSection: View {
    let lesson: Lesson
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [lesson.category.color.opacity(0.3), lesson.category.color.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 250)
            
            VStack(spacing: 16) {
                // Large lesson illustration with reference image
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .frame(width: 150, height: 150)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        AsyncReferenceImage(lesson.referenceImageName, type: .reference)
                            .frame(width: 140, height: 140)
                            .cornerRadius(12)
                            .overlay(
                                // Category icon overlay in corner
                                VStack {
                                    HStack {
                                        Spacer()
                                        Image(systemName: lesson.category.iconName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(lesson.category.color)
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            )
                    )
                
                // Premium badge
                if lesson.isPremium {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Premium Lesson")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct LessonInfoSection: View {
    let lesson: Lesson
    
    var body: some View {
        HStack(spacing: 20) {
            InfoItem(
                icon: "clock",
                value: "\(lesson.estimatedTime) min",
                label: "Duration"
            )
            
            InfoItem(
                icon: lesson.difficulty.iconName,
                value: lesson.difficulty.rawValue,
                label: "Difficulty",
                color: lesson.difficulty.color
            )
            
            InfoItem(
                icon: "list.number",
                value: "\(lesson.steps.count)",
                label: "Steps"
            )
            
            InfoItem(
                icon: lesson.category.iconName,
                value: lesson.category.rawValue,
                label: "Category",
                color: lesson.category.color
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InfoItem: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LessonStepsSection: View {
    let lesson: Lesson
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps (\(lesson.steps.count))")
                .font(.headline)
            
            ForEach(Array(lesson.steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    // Step number
                    Text("\(step.stepNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(lesson.category.color)
                        .clipShape(Circle())
                    
                    // Step instruction
                    Text(step.instruction)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(8)
            }
        }
    }
}

struct WhatYoullLearnSection: View {
    let lesson: Lesson
    
    private var learningPoints: [String] {
        switch lesson.category {
        case .faces:
            return [
                "Fundamental facial proportions",
                "Proper eye and nose placement",
                "Creating realistic expressions",
                "Understanding light and shadow"
            ]
        case .animals:
            return [
                "Animal anatomy basics",
                "Capturing characteristic features",
                "Drawing fur and texture",
                "Creating lifelike poses"
            ]
        case .objects:
            return [
                "3D form construction",
                "Perspective principles",
                "Light and shadow effects",
                "Material representation"
            ]
        case .hands:
            return [
                "Hand anatomy structure",
                "Finger proportions",
                "Various hand poses",
                "Gesture drawing techniques"
            ]
        case .perspective:
            return [
                "Vanishing point theory",
                "Creating depth illusion",
                "Spatial relationships",
                "Environmental perspective"
            ]
        case .nature:
            return [
                "Organic shape construction",
                "Natural texture techniques",
                "Environmental elements",
                "Landscape composition"
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You'll Learn")
                .font(.headline)
            
            ForEach(learningPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                        .padding(.top, 2)
                    
                    Text(point)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
}

struct StartLessonButton: View {
    let lesson: Lesson
    let action: () -> Void
    @EnvironmentObject var monetizationService: MonetizationService
    
    private var buttonText: String {
        if lesson.isCompleted {
            return "Practice Again"
        } else {
            return monetizationService.featureGateManager.getLessonAccessText(lesson)
        }
    }
    
    private var buttonColor: Color {
        if lesson.isCompleted {
            return lesson.category.color
        } else {
            return monetizationService.featureGateManager.getLessonAccessColor(lesson)
        }
    }
    
    private var buttonIcon: String {
        if lesson.isCompleted {
            return "arrow.clockwise"
        } else {
            return monetizationService.featureGateManager.getLessonAccessIcon(lesson)
        }
    }
    
    var body: some View {
        EnhancedPrimaryButton(
            buttonText,
            icon: buttonIcon,
            action: action
        )
    }
}

#Preview {
    NavigationView {
        LessonDetailView(lesson: LessonData.sampleLessons[0])
    }
    .environmentObject(UserProfileService(persistenceService: PersistenceService()))
    .environmentObject(MonetizationService())
}
