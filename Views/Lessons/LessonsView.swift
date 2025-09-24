import SwiftUI

struct LessonsView: View {
    @EnvironmentObject var lessonService: LessonService
    @EnvironmentObject var monetizationService: MonetizationService
    
    @State private var searchText = ""
    @State private var selectedCategory: LessonCategory?
    @State private var selectedDifficulty: DifficultyLevel?
    
    var filteredLessons: [Lesson] {
        var lessons = lessonService.lessons
        
        // Apply search filter
        if !searchText.isEmpty {
            lessons = lessons.filter { lesson in
                lesson.title.localizedCaseInsensitiveContains(searchText) ||
                lesson.description.localizedCaseInsensitiveContains(searchText) ||
                lesson.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            lessons = lessons.filter { $0.category == category }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            lessons = lessons.filter { $0.difficulty == difficulty }
        }
        
        return lessons
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                SearchAndFiltersSection(
                    searchText: $searchText,
                    selectedCategory: $selectedCategory,
                    selectedDifficulty: $selectedDifficulty
                )
                
                // Generated Lessons Section (if any exist)
                if !lessonService.generatedLessons.isEmpty {
                    GeneratedLessonsSection(
                        generatedLessons: lessonService.generatedLessons,
                        onDeleteLesson: { lesson in
                            lessonService.removeGeneratedLesson(lesson)
                        }
                    )
                }
                
                // Lessons grid
                LessonsGridSection(filteredLessons: filteredLessons)
            }
            .navigationTitle("Lessons")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SearchAndFiltersSection: View {
    @Binding var searchText: String
    @Binding var selectedCategory: LessonCategory?
    @Binding var selectedDifficulty: DifficultyLevel?
    
    
    var body: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search lessons...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    FilterChip(
                        title: "All Categories",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(LessonCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Difficulty filter
            HStack {
                Text("Difficulty:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                    FilterChip(
                        title: difficulty.rawValue,
                        isSelected: selectedDifficulty == difficulty,
                        color: difficulty.color
                    ) {
                        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                    }
                }
                
                Spacer()
            }
        }
        .padding(16)
    }
}

struct LessonsGridSection: View {
    let filteredLessons: [Lesson]
    
    var body: some View {
        if filteredLessons.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "No lessons found",
                subtitle: "Try adjusting your search or filters"
            )
            .padding(.top, 60)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 2),
                    spacing: 12
                ) {
                    ForEach(filteredLessons) { lesson in
                        LessonCard(lesson: lesson)
                    }
                }
                .padding(16)
                .padding(.bottom, 120) // Space for tab bar
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.15))
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LessonCard: View {
    let lesson: Lesson
    @EnvironmentObject var monetizationService: MonetizationService
    
    var body: some View {
        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
            VStack(alignment: .leading, spacing: 8) {
                // Lesson image
                AsyncImage(url: URL(string: lesson.thumbnailImageName)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .cornerRadius(8)
                .clipped()
                .overlay(
                    // Premium badge
                    Group {
                        if lesson.isPremium && !monetizationService.isPro {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .cornerRadius(4)
                                }
                                Spacer()
                            }
                            .padding(8)
                        }
                    }
                )
                
                // Lesson info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(lesson.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Metadata row
                    HStack {
                        // Difficulty
                        HStack(spacing: 4) {
                            Circle()
                                .fill(lesson.difficulty.color)
                                .frame(width: 8, height: 8)
                            
                            Text(lesson.difficulty.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Duration
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("\(lesson.estimatedDuration / 60)min")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GeneratedLessonsSection: View {
    let generatedLessons: [Lesson]
    let onDeleteLesson: (Lesson) -> Void
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Generated Lessons")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(generatedLessons.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(4)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(generatedLessons) { lesson in
                        GeneratedLessonCard(lesson: lesson, onDelete: {
                            onDeleteLesson(lesson)
                        })
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
    }
}

struct GeneratedLessonCard: View {
    let lesson: Lesson
    let onDelete: () -> Void
    
    
    var body: some View {
        NavigationLink(destination: LessonDetailView(lesson: lesson)) {
            VStack(alignment: .leading, spacing: 8) {
                // Lesson image with delete button
                ZStack {
                    AsyncImage(url: URL(string: lesson.thumbnailImageName)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 160, height: 120)
                    .cornerRadius(8)
                    .clipped()
                    
                    // Delete button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // Lesson info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        
                        Text("AI Generated")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                .frame(width: 160, alignment: .leading)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}


#Preview {
    NavigationView {
        LessonsView()
            .environmentObject(LessonService(persistenceService: PersistenceService()))
            .environmentObject(MonetizationService())
    }
}