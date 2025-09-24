import SwiftUI
import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var profileImageURL: String?
    var joinDate: Date
    var totalLessonsCompleted: Int
    var currentStreak: Int
    var totalXP: Int
    var level: Int
    var isPro: Bool
    
    init(name: String, email: String, profileImageURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.joinDate = Date()
        self.totalLessonsCompleted = 0
        self.currentStreak = 0
        self.totalXP = 0
        self.level = 1
        self.isPro = false
    }
}

// MARK: - Lesson Model
struct Lesson: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let category: LessonCategory
    let difficulty: DifficultyLevel
    let thumbnailImageName: String
    let referenceImageName: String
    let estimatedTime: Int // in minutes
    let isPremium: Bool
    let steps: [LessonStep]
    let tags: [String]
    var isCompleted: Bool = false
    var isFavorite: Bool = false
    
    // Computed property for backward compatibility
    var estimatedDuration: Int {
        return estimatedTime * 60 // Convert minutes to seconds
    }
    
    init(title: String, description: String, category: LessonCategory, difficulty: DifficultyLevel, 
         thumbnailImageName: String, referenceImageName: String, estimatedTime: Int, 
         isPremium: Bool, steps: [LessonStep], tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.thumbnailImageName = thumbnailImageName
        self.referenceImageName = referenceImageName
        self.estimatedTime = estimatedTime
        self.isPremium = isPremium
        self.steps = steps
        self.tags = tags
        self.isCompleted = false
        self.isFavorite = false
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, difficulty, thumbnailImageName, referenceImageName, estimatedTime, isPremium, steps, tags, isCompleted, isFavorite
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(LessonCategory.self, forKey: .category)
        difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        thumbnailImageName = try container.decode(String.self, forKey: .thumbnailImageName)
        referenceImageName = try container.decode(String.self, forKey: .referenceImageName)
        estimatedTime = try container.decode(Int.self, forKey: .estimatedTime)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        steps = try container.decode([LessonStep].self, forKey: .steps)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(thumbnailImageName, forKey: .thumbnailImageName)
        try container.encode(referenceImageName, forKey: .referenceImageName)
        try container.encode(estimatedTime, forKey: .estimatedTime)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encode(steps, forKey: .steps)
        try container.encode(tags, forKey: .tags)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
    
    static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Lesson Category
enum LessonCategory: String, CaseIterable, Codable {
    case faces = "Faces & Portraits"
    case animals = "Animals"
    case objects = "Objects"
    case hands = "Hands & Poses"
    case perspective = "Perspective Basics"
    case nature = "Nature"
    
    var iconName: String {
        switch self {
        case .faces: return "person.crop.circle"
        case .animals: return "pawprint"
        case .objects: return "cube"
        case .hands: return "hand.raised"
        case .perspective: return "rectangle.3.group"
        case .nature: return "leaf"
        }
    }
    
    var color: Color {
        switch self {
        case .faces: return .blue
        case .animals: return .green
        case .objects: return .orange
        case .hands: return .purple
        case .perspective: return .red
        case .nature: return .mint
        }
    }
}

// MARK: - Difficulty Level
enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: Color {
        switch self {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .beginner: return "star"
        case .intermediate: return "star.leadinghalf.filled"
        case .advanced: return "star.fill"
        }
    }
}

// MARK: - Lesson Step
struct LessonStep: Identifiable, Codable {
    var id = UUID()
    let stepNumber: Int
    let instruction: String
    let guidancePoints: [CGPoint]
    let shapeType: ShapeType
    
    init(stepNumber: Int, instruction: String, guidancePoints: [CGPoint], shapeType: ShapeType) {
        self.id = UUID()
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.guidancePoints = guidancePoints
        self.shapeType = shapeType
    }
}

// MARK: - Shape Type for AI Guidance
enum ShapeType: String, Codable {
    case circle
    case oval
    case rectangle
    case line
    case curve
    case polygon
}

// MARK: - User Drawing
struct UserDrawing: Identifiable, Codable {
    let id: UUID
    let lessonId: UUID?
    let title: String
    let imageData: Data
    let timelapseData: Data?
    let createdDate: Date
    let completionTime: TimeInterval // in seconds
    let category: LessonCategory?
    let authorId: String? // Author identifier for UGC safety features
    var isFavorite: Bool = false
    var isShared: Bool = false
    
    init(lessonId: UUID?, title: String, imageData: Data, timelapseData: Data? = nil, category: LessonCategory? = nil, authorId: String? = nil) {
        self.id = UUID()
        self.lessonId = lessonId
        self.title = title
        self.imageData = imageData
        self.timelapseData = timelapseData
        self.createdDate = Date()
        self.completionTime = 0
        self.category = category
        self.authorId = authorId
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, lessonId, title, imageData, timelapseData, createdDate, completionTime, category, authorId, isFavorite, isShared
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        lessonId = try container.decodeIfPresent(UUID.self, forKey: .lessonId)
        title = try container.decode(String.self, forKey: .title)
        imageData = try container.decode(Data.self, forKey: .imageData)
        timelapseData = try container.decodeIfPresent(Data.self, forKey: .timelapseData)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        completionTime = try container.decode(TimeInterval.self, forKey: .completionTime)
        category = try container.decodeIfPresent(LessonCategory.self, forKey: .category)
        authorId = try container.decodeIfPresent(String.self, forKey: .authorId)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isShared = try container.decodeIfPresent(Bool.self, forKey: .isShared) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(lessonId, forKey: .lessonId)
        try container.encode(title, forKey: .title)
        try container.encode(imageData, forKey: .imageData)
        try container.encodeIfPresent(timelapseData, forKey: .timelapseData)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(completionTime, forKey: .completionTime)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(authorId, forKey: .authorId)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(isShared, forKey: .isShared)
    }
}

// MARK: - Achievement Model
class Achievement: Identifiable, ObservableObject {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let requirement: AchievementRequirement
    @Published var isUnlocked: Bool = false
    @Published var progress: Double = 0.0
    
    init(title: String, description: String, iconName: String, requirement: AchievementRequirement) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.requirement = requirement
    }
    
    func checkUnlockCondition(userDrawings: [UserDrawing], streakCount: Int) {
        switch requirement {
        case .firstDrawing:
            if !userDrawings.isEmpty && !isUnlocked {
                isUnlocked = true
            }
        case .streak(let days):
            progress = min(Double(streakCount) / Double(days), 1.0)
            if streakCount >= days && !isUnlocked {
                isUnlocked = true
            }
        case .drawingsCount(let count):
            progress = min(Double(userDrawings.count) / Double(count), 1.0)
            if userDrawings.count >= count && !isUnlocked {
                isUnlocked = true
            }
        case .categoryMastery(let category, let count):
            let categoryDrawings = userDrawings.filter { $0.category == category }
            progress = min(Double(categoryDrawings.count) / Double(count), 1.0)
            if categoryDrawings.count >= count && !isUnlocked {
                isUnlocked = true
            }
        }
    }
}

// MARK: - Achievement Requirements
enum AchievementRequirement {
    case firstDrawing
    case streak(days: Int)
    case drawingsCount(Int)
    case categoryMastery(category: LessonCategory, count: Int)
}

// MARK: - Drawing Tools
enum DrawingTool: CaseIterable {
    case pencil
    case eraser
    case brush
    
    var iconName: String {
        switch self {
        case .pencil: return "pencil"
        case .eraser: return "eraser"
        case .brush: return "paintbrush"
        }
    }
    
    var name: String {
        switch self {
        case .pencil: return "Pencil"
        case .eraser: return "Eraser"
        case .brush: return "Brush"
        }
    }
}

// MARK: - Difficulty Adjustment Enum
enum DifficultyAdjustment: Int, CaseIterable, Codable {
    case easier = 0
    case normal = 1
    case harder = 2
    
    var description: String {
        switch self {
        case .easier: return "Relaxed"
        case .normal: return "Standard"
        case .harder: return "Precise"
        }
    }
}

// MARK: - Category Difficulty Pair (for Codable serialization)
private struct CategoryDifficultyPair: Codable {
    let category: String
    let difficulty: Int
}

// MARK: - Tab Types
enum TabType: CaseIterable {
    case home
    case lessons
    case gallery
    case profile
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .lessons: return "Lessons"
        case .gallery: return "Gallery"
        case .profile: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .lessons: return "book"
        case .gallery: return "photo.on.rectangle"
        case .profile: return "person"
        }
    }
    
    var iconNameFilled: String {
        switch self {
        case .home: return "house.fill"
        case .lessons: return "book.fill"
        case .gallery: return "photo.on.rectangle.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Lesson Progress Model
struct LessonProgress: Identifiable, Codable {
    let id: UUID
    let lessonId: UUID
    let userId: String?
    var isCompleted: Bool
    var isFavorite: Bool
    var completionDate: Date?
    var lastAccessedDate: Date?
    var timeSpent: Double // in seconds
    var accuracyScore: Double // 0.0 to 1.0
    var stepProgress: Int // current step number
    var totalSteps: Int // total steps in lesson
    let createdDate: Date
    
    init(lessonId: UUID, userId: String? = nil) {
        self.id = UUID()
        self.lessonId = lessonId
        self.userId = userId
        self.isCompleted = false
        self.isFavorite = false
        self.completionDate = nil
        self.lastAccessedDate = Date()
        self.timeSpent = 0.0
        self.accuracyScore = 0.0
        self.stepProgress = 0
        self.totalSteps = 0
        self.createdDate = Date()
    }
    
    // Full initializer for Core Data conversion
    init(id: UUID, lessonId: UUID, userId: String?, isCompleted: Bool, isFavorite: Bool, 
         completionDate: Date?, lastAccessedDate: Date?, timeSpent: Double, accuracyScore: Double,
         stepProgress: Int, totalSteps: Int, createdDate: Date) {
        self.id = id
        self.lessonId = lessonId
        self.userId = userId
        self.isCompleted = isCompleted
        self.isFavorite = isFavorite
        self.completionDate = completionDate
        self.lastAccessedDate = lastAccessedDate
        self.timeSpent = timeSpent
        self.accuracyScore = accuracyScore
        self.stepProgress = stepProgress
        self.totalSteps = totalSteps
        self.createdDate = createdDate
    }
    
    // Mark lesson as completed
    mutating func markCompleted(accuracyScore: Double = 0.0) {
        self.isCompleted = true
        self.completionDate = Date()
        self.accuracyScore = accuracyScore
        self.lastAccessedDate = Date()
    }
    
    // Toggle favorite status
    mutating func toggleFavorite() {
        self.isFavorite.toggle()
        self.lastAccessedDate = Date()
    }
    
    // Update progress
    mutating func updateProgress(currentStep: Int, totalSteps: Int, timeSpent: Double = 0.0) {
        self.stepProgress = currentStep
        self.totalSteps = totalSteps
        self.timeSpent += timeSpent
        self.lastAccessedDate = Date()
    }
    
    // Calculate completion percentage
    var completionPercentage: Double {
        guard totalSteps > 0 else { return 0.0 }
        return Double(stepProgress) / Double(totalSteps)
    }
}

// MARK: - Artistic Feedback Types
struct ArtisticFeedback: Equatable {
    let overallScore: Double // 0.0 to 1.0
    let composition: CompositionAnalysis
    let style: StyleAnalysis
    let color: ColorAnalysis
    let creativity: CreativityAnalysis
    let suggestions: [String]
    let encouragement: String
    let artisticInsights: [String]
    
    // For backward compatibility with DrawingAlgorithms.swift
    var score: Double { return overallScore }
    var artisticStyleMatch: Double? { return style.overallScore }
    var compositionalBalance: Double? { return composition.overallScore }
    var lineQuality: Double? { return style.lineQuality }
}

struct ArtisticContext {
    let userLevel: UserLevel
    let lessonCategory: LessonCategory
    let previousAttempts: Int
    let timeSpent: TimeInterval
    let userPreferences: UserArtisticPreferences
    
    enum UserLevel {
        case beginner, intermediate, advanced
    }
}

struct UserArtisticPreferences {
    let preferredStyle: String
    let focusAreas: [String]
    let encouragementLevel: EncouragementLevel
    
    enum EncouragementLevel {
        case gentle, moderate, enthusiastic
    }
}

struct CompositionAnalysis: Equatable {
    let balance: Double
    let proportion: Double
    let rhythm: Double
    let emphasis: Double
    let overallScore: Double
}

struct StyleAnalysis: Equatable {
    let lineQuality: Double
    let expressiveness: Double
    let technique: Double
    let overallScore: Double
}

struct ColorAnalysis: Equatable {
    let balance: Double
    let contrast: Double
    let saturation: Double
    let overallScore: Double
}

struct CreativityAnalysis: Equatable {
    let originality: Double
    let innovation: Double
    let artisticVoice: Double
    let overallScore: Double
}

// MARK: - Adaptive Difficulty Settings
struct AdaptiveDifficultySettings: Codable {
    var categoryDifficulties: [LessonCategory: DifficultyAdjustment] = [:]
    var globalDifficultyPreference: DifficultyAdjustment = .normal
    var enableAdaptiveDifficulty: Bool = true
    var lastUpdated: Date = Date()
    
    init() {
        // Initialize with default normal difficulty for all categories
        for category in LessonCategory.allCases {
            categoryDifficulties[category] = .normal
        }
    }
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case categoryDifficulties
        case globalDifficultyPreference
        case enableAdaptiveDifficulty
        case lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode dictionary as array of CategoryDifficultyPair to handle enum keys
        let categoryDifficultiesArray = try container.decodeIfPresent([CategoryDifficultyPair].self, forKey: .categoryDifficulties) ?? []
        self.categoryDifficulties = [:]
        for pair in categoryDifficultiesArray {
            if let category = LessonCategory(rawValue: pair.category),
               let difficulty = DifficultyAdjustment(rawValue: pair.difficulty) {
                self.categoryDifficulties[category] = difficulty
            }
        }
        
        // Fill in missing categories with default values
        for category in LessonCategory.allCases {
            if categoryDifficulties[category] == nil {
                categoryDifficulties[category] = .normal
            }
        }
        
        self.globalDifficultyPreference = try container.decodeIfPresent(DifficultyAdjustment.self, forKey: .globalDifficultyPreference) ?? .normal
        self.enableAdaptiveDifficulty = try container.decodeIfPresent(Bool.self, forKey: .enableAdaptiveDifficulty) ?? true
        self.lastUpdated = try container.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode dictionary as array of CategoryDifficultyPair
        let categoryDifficultiesArray = categoryDifficulties.map { (category, difficulty) in
            CategoryDifficultyPair(category: category.rawValue, difficulty: difficulty.rawValue)
        }
        try container.encode(categoryDifficultiesArray, forKey: .categoryDifficulties)
        
        try container.encode(globalDifficultyPreference, forKey: .globalDifficultyPreference)
        try container.encode(enableAdaptiveDifficulty, forKey: .enableAdaptiveDifficulty)
        try container.encode(lastUpdated, forKey: .lastUpdated)
    }
}


