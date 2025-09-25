import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Entity Extensions

extension CDUserDrawing {
    
    // Convert Core Data entity to our clean UserDrawing struct
    func toUserDrawing() -> UserDrawing? {
        guard let _ = self.id,
              let title = self.title,
              let imageData = self.imageData,
              let _ = self.createdDate else {
            return nil
        }
        
        // Create a UserDrawing and then update its mutable properties
        var drawing = UserDrawing(
            lessonId: self.lessonId,
            title: title,
            imageData: imageData,
            timelapseData: self.timelapseData,
            category: LessonCategory(rawValue: self.category ?? ""),
            authorId: self.authorId
        )
        
        // Set the mutable properties
        drawing.isFavorite = self.isFavorite
        drawing.isShared = self.isShared
        
        return drawing
    }
    
    // Update Core Data entity from UserDrawing struct
    func updateFromUserDrawing(_ drawing: UserDrawing) {
        self.id = drawing.id
        self.lessonId = drawing.lessonId
        self.title = drawing.title
        self.imageData = drawing.imageData
        self.timelapseData = drawing.timelapseData
        self.createdDate = drawing.createdDate
        self.completionTime = drawing.completionTime
        self.category = drawing.category?.rawValue
        self.authorId = drawing.authorId
        self.isFavorite = drawing.isFavorite
        self.isShared = drawing.isShared
    }
}

extension CDAchievement {
    
    // Convert Core Data entity to our Achievement class
    func toAchievement() -> Achievement? {
        guard let _ = self.id,
              let title = self.title,
              let description = self.achievementDescription,
              let iconName = self.iconName,
              let requirementData = self.requirementData else {
            return nil
        }
        
        // Decode the requirement from stored data
        guard let requirement = try? JSONDecoder().decode(AchievementRequirement.self, from: requirementData) else {
            return nil
        }
        
        let achievement = Achievement(title: title, description: description, iconName: iconName, requirement: requirement)
        achievement.isUnlocked = self.isUnlocked
        achievement.progress = self.progress
        
        return achievement
    }
    
    // Update Core Data entity from Achievement class
    func updateFromAchievement(_ achievement: Achievement) {
        self.id = achievement.id
        self.title = achievement.title
        self.achievementDescription = achievement.description
        self.iconName = achievement.iconName
        self.isUnlocked = achievement.isUnlocked
        self.progress = achievement.progress
        
        // Encode the requirement for storage
        if let encoded = try? JSONEncoder().encode(achievement.requirement) {
            self.requirementData = encoded
        }
    }
}

// MARK: - UserDrawing Extensions for Core Data Compatibility

// Note: The UserDrawing struct works well with Core Data through the conversion methods above.
// The id, createdDate, and completionTime properties are handled by the original UserDrawing init,
// while isFavorite and isShared are mutable properties that can be updated after creation.

// MARK: - AchievementRequirement Codable Conformance

extension AchievementRequirement: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type, days, count, category
    }
    
    enum RequirementType: String, Codable {
        case firstDrawing, streak, drawingsCount, categoryMastery
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RequirementType.self, forKey: .type)
        
        switch type {
        case .firstDrawing:
            self = .firstDrawing
        case .streak:
            let days = try container.decode(Int.self, forKey: .days)
            self = .streak(days: days)
        case .drawingsCount:
            let count = try container.decode(Int.self, forKey: .count)
            self = .drawingsCount(count)
        case .categoryMastery:
            let category = try container.decode(LessonCategory.self, forKey: .category)
            let count = try container.decode(Int.self, forKey: .count)
            self = .categoryMastery(category: category, count: count)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .firstDrawing:
            try container.encode(RequirementType.firstDrawing, forKey: .type)
        case .streak(let days):
            try container.encode(RequirementType.streak, forKey: .type)
            try container.encode(days, forKey: .days)
        case .drawingsCount(let count):
            try container.encode(RequirementType.drawingsCount, forKey: .type)
            try container.encode(count, forKey: .count)
        case .categoryMastery(let category, let count):
            try container.encode(RequirementType.categoryMastery, forKey: .type)
            try container.encode(category, forKey: .category)
            try container.encode(count, forKey: .count)
        }
    }
}

// MARK: - CDLessonProgress Extensions

extension CDLessonProgress {
    
    // Convert Core Data entity to our clean LessonProgress struct
    func toLessonProgress() -> LessonProgress? {
        guard let id = self.id else {
            return nil
        }
        
        return LessonProgress(
            id: id,
            lessonId: self.lessonId,
            userId: self.userId,
            isCompleted: self.isCompleted,
            isFavorite: self.isFavorite,
            completionDate: self.completionDate,
            lastAccessedDate: self.lastAccessedDate,
            timeSpent: self.timeSpent,
            accuracyScore: self.accuracyScore,
            stepProgress: Int(self.stepProgress),
            totalSteps: Int(self.totalSteps),
            createdDate: self.createdDate ?? Date()
        )
    }
    
    // Update Core Data entity from LessonProgress struct
    func updateFromLessonProgress(_ progress: LessonProgress) {
        self.id = progress.id
        self.lessonId = progress.lessonId
        self.userId = progress.userId
        self.isCompleted = progress.isCompleted
        self.isFavorite = progress.isFavorite
        self.completionDate = progress.completionDate
        self.lastAccessedDate = progress.lastAccessedDate
        self.timeSpent = progress.timeSpent
        self.accuracyScore = progress.accuracyScore
        self.stepProgress = Int32(progress.stepProgress)
        self.totalSteps = Int32(progress.totalSteps)
        self.createdDate = progress.createdDate
    }
}
