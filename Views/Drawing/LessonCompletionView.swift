import SwiftUI
import PencilKit
import UIKit

// MARK: - Lesson Completion View
struct LessonCompletionView: View {
    let lesson: Lesson
    let finalDrawing: PKDrawing
    let accuracy: Double
    let completionTime: TimeInterval
    let recordedVideoURL: URL?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userProfileService: UserProfileService
    @EnvironmentObject var lessonService: LessonService
    
    @State private var showConfetti = false
    @State private var showSharingOptions = false
    @State private var showVideoSharingOptions = false
    @State private var drawingImage: UIImage?
    
    var completionGrade: String {
        switch accuracy {
        case 0.9...1.0: return "Excellent!"
        case 0.8..<0.9: return "Great Job!"
        case 0.7..<0.8: return "Good Work!"
        case 0.6..<0.7: return "Nice Try!"
        default: return "Keep Practicing!"
        }
    }
    
    var completionColor: Color {
        switch accuracy {
        case 0.9...1.0: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        default: return .red
        }
    }
    
    var formattedTime: String {
        let minutes = Int(completionTime) / 60
        let seconds = Int(completionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Celebration Header
                    VStack(spacing: 16) {
                        // Confetti animation
                        if showConfetti {
                            ConfettiView()
                                .frame(height: 100)
                                .transition(.opacity)
                        }
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(completionColor)
                            .scaleEffect(showConfetti ? 1.2 : 1.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showConfetti)
                        
                        VStack(spacing: 8) {
                            Text("Lesson Complete!")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text(completionGrade)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(completionColor)
                        }
                    }
                    .padding(.top)
                    
                    // Drawing Preview
                    VStack(spacing: 12) {
                        Text("Your Creation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let image = drawingImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(height: 200)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                        }
                    }
                    
                    // Statistics
                    VStack(spacing: 16) {
                        Text("Lesson Statistics")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            LessonStatCard(
                                icon: "target",
                                title: "Accuracy",
                                value: "\(Int(accuracy * 100))%",
                                color: completionColor
                            )
                            
                            LessonStatCard(
                                icon: "clock",
                                title: "Time",
                                value: formattedTime,
                                color: .blue
                            )
                            
                            LessonStatCard(
                                icon: "paintbrush",
                                title: "Strokes",
                                value: "\(finalDrawing.strokes.count)",
                                color: .purple
                            )
                            
                            LessonStatCard(
                                icon: "star.fill",
                                title: "Category",
                                value: lesson.category.rawValue.capitalized,
                                color: .orange
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Achievements (if any)
                    if let achievements = getEarnedAchievements() {
                        VStack(spacing: 12) {
                            Text("New Achievements!")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(achievements, id: \.title) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Share Drawing
                        Button {
                            showSharingOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Your Drawing")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // Try Another Lesson
                        Button {
                            // Navigate to lessons view
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "paintbrush.pointed.fill")
                                Text("Try Another Lesson")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Continue Learning
                        if let nextLesson = getNextRecommendedLesson() {
                            Button {
                                // Navigate to next lesson
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Continue: \(nextLesson.title)")
                                }
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Lesson Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupCompletionView()
        }
        .sheet(isPresented: $showSharingOptions) {
            if let image = drawingImage {
                ShareSheet(items: [image])
            }
        }
        .sheet(isPresented: $showVideoSharingOptions) {
            if let videoURL = recordedVideoURL {
                VideoSharingIntegrationView(
                    recordedVideoURL: videoURL,
                    lesson: lesson
                )
            }
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupCompletionView() {
        // Generate drawing image
        generateDrawingImage()
        
        // Show celebration animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showConfetti = true
            }
        }
        
        // Save completion data
        saveCompletionData()
    }
    
    private func generateDrawingImage() {
        let bounds = CGRect(x: 0, y: 0, width: 512, height: 512)
        drawingImage = finalDrawing.image(from: bounds, scale: 1.0)
    }
    
    private func saveCompletionData() {
        // Update user statistics
        userProfileService.updateLessonStats(
            lessonId: lesson.id,
            accuracy: accuracy,
            completionTime: completionTime
        )
        
        // Check for new achievements
        userProfileService.checkForNewAchievements()
    }
    
    // MARK: - Helper Methods
    
    private func getEarnedAchievements() -> [Achievement]? {
        // Get achievements earned from this lesson completion
        return userProfileService.getRecentAchievements()
    }
    
    private func getNextRecommendedLesson() -> Lesson? {
        // Get next recommended lesson based on progress
        return lessonService.getNextRecommendedLesson(after: lesson)
    }
}

// MARK: - Lesson Stat Card
struct LessonStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.yellow.opacity(0.2)))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("NEW!")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red)
                .cornerRadius(4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Confetti Animation
struct ConfettiView: View {
    @State private var animate = false
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(colors.randomElement() ?? .blue)
                    .frame(width: 6, height: 6)
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -100...100) : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2.0)
                        .delay(Double.random(in: 0...0.5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    LessonCompletionView(
        lesson: LessonData.sampleLessons[0],
        finalDrawing: PKDrawing(),
        accuracy: 0.85,
        completionTime: 180,
        recordedVideoURL: nil
    )
    .environmentObject(UserProfileService(persistenceService: PersistenceService()))
    .environmentObject(LessonService(persistenceService: PersistenceService()))
}
