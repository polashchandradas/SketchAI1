import Foundation
import CoreData

// MARK: - Core Data Entity Classes
// These classes represent the Core Data entities and are typically auto-generated,
// but we're creating them manually for compilation compatibility

@objc(CDUserDrawing)
public class CDUserDrawing: NSManagedObject {
    
}

extension CDUserDrawing {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDUserDrawing> {
        return NSFetchRequest<CDUserDrawing>(entityName: "CDUserDrawing")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var lessonId: UUID?
    @NSManaged public var title: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var timelapseData: Data?
    @NSManaged public var createdDate: Date?
    @NSManaged public var completionTime: Double
    @NSManaged public var category: String?
    @NSManaged public var authorId: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var isShared: Bool
    
}

@objc(CDAchievement)
public class CDAchievement: NSManagedObject {
    
}

extension CDAchievement {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAchievement> {
        return NSFetchRequest<CDAchievement>(entityName: "CDAchievement")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var achievementDescription: String?
    @NSManaged public var iconName: String?
    @NSManaged public var requirementData: Data?
    @NSManaged public var isUnlocked: Bool
    @NSManaged public var progress: Double
    
}

// MARK: - Identifiable Conformance

extension CDUserDrawing: Identifiable {
    
}

extension CDAchievement: Identifiable {
    
}

@objc(CDLessonProgress)
public class CDLessonProgress: NSManagedObject {
    
}

extension CDLessonProgress {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDLessonProgress> {
        return NSFetchRequest<CDLessonProgress>(entityName: "CDLessonProgress")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var lessonId: UUID
    @NSManaged public var userId: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var isFavorite: Bool
    @NSManaged public var completionDate: Date?
    @NSManaged public var lastAccessedDate: Date?
    @NSManaged public var timeSpent: Double
    @NSManaged public var accuracyScore: Double
    @NSManaged public var stepProgress: Int32
    @NSManaged public var totalSteps: Int32
    @NSManaged public var createdDate: Date?
    
}

extension CDLessonProgress: Identifiable {
    
}