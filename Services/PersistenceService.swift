import Foundation
import SwiftUI
import Combine
import CoreData

// MARK: - Persistence Service
class PersistenceService: ObservableObject {
    
    // MARK: - Core Data Stack
    lazy var container: NSPersistentContainer = {
        // Create CoreData model programmatically to avoid momc compilation issues
        let model = NSManagedObjectModel()
        
        // Create CDUserDrawing entity
        let userDrawingEntity = NSEntityDescription()
        userDrawingEntity.name = "CDUserDrawing"
        userDrawingEntity.managedObjectClassName = "CDUserDrawing"
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = true
        
        let lessonIdAttribute = NSAttributeDescription()
        lessonIdAttribute.name = "lessonId"
        lessonIdAttribute.attributeType = .UUIDAttributeType
        lessonIdAttribute.isOptional = true
        
        let titleAttribute = NSAttributeDescription()
        titleAttribute.name = "title"
        titleAttribute.attributeType = .stringAttributeType
        titleAttribute.isOptional = true
        
        let imageDataAttribute = NSAttributeDescription()
        imageDataAttribute.name = "imageData"
        imageDataAttribute.attributeType = .binaryDataAttributeType
        imageDataAttribute.isOptional = true
        
        let timelapseDataAttribute = NSAttributeDescription()
        timelapseDataAttribute.name = "timelapseData"
        timelapseDataAttribute.attributeType = .binaryDataAttributeType
        timelapseDataAttribute.isOptional = true
        
        let createdDateAttribute = NSAttributeDescription()
        createdDateAttribute.name = "createdDate"
        createdDateAttribute.attributeType = .dateAttributeType
        createdDateAttribute.isOptional = true
        
        let completionTimeAttribute = NSAttributeDescription()
        completionTimeAttribute.name = "completionTime"
        completionTimeAttribute.attributeType = .doubleAttributeType
        completionTimeAttribute.isOptional = true
        completionTimeAttribute.defaultValue = 0.0
        
        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = true
        
        let authorIdAttribute = NSAttributeDescription()
        authorIdAttribute.name = "authorId"
        authorIdAttribute.attributeType = .stringAttributeType
        authorIdAttribute.isOptional = true
        
        let isFavoriteAttribute = NSAttributeDescription()
        isFavoriteAttribute.name = "isFavorite"
        isFavoriteAttribute.attributeType = .booleanAttributeType
        isFavoriteAttribute.isOptional = true
        
        let isSharedAttribute = NSAttributeDescription()
        isSharedAttribute.name = "isShared"
        isSharedAttribute.attributeType = .booleanAttributeType
        isSharedAttribute.isOptional = true
        
        userDrawingEntity.properties = [
            idAttribute, lessonIdAttribute, titleAttribute, imageDataAttribute,
            timelapseDataAttribute, createdDateAttribute, completionTimeAttribute,
            categoryAttribute, authorIdAttribute, isFavoriteAttribute, isSharedAttribute
        ]
        
        // Create CDAchievement entity
        let achievementEntity = NSEntityDescription()
        achievementEntity.name = "CDAchievement"
        achievementEntity.managedObjectClassName = "CDAchievement"
        
        let achievementIdAttribute = NSAttributeDescription()
        achievementIdAttribute.name = "id"
        achievementIdAttribute.attributeType = .UUIDAttributeType
        achievementIdAttribute.isOptional = true
        
        let achievementTitleAttribute = NSAttributeDescription()
        achievementTitleAttribute.name = "title"
        achievementTitleAttribute.attributeType = .stringAttributeType
        achievementTitleAttribute.isOptional = true
        
        let achievementDescriptionAttribute = NSAttributeDescription()
        achievementDescriptionAttribute.name = "achievementDescription"
        achievementDescriptionAttribute.attributeType = .stringAttributeType
        achievementDescriptionAttribute.isOptional = true
        
        let iconNameAttribute = NSAttributeDescription()
        iconNameAttribute.name = "iconName"
        iconNameAttribute.attributeType = .stringAttributeType
        iconNameAttribute.isOptional = true
        
        let requirementDataAttribute = NSAttributeDescription()
        requirementDataAttribute.name = "requirementData"
        requirementDataAttribute.attributeType = .binaryDataAttributeType
        requirementDataAttribute.isOptional = true
        
        let isUnlockedAttribute = NSAttributeDescription()
        isUnlockedAttribute.name = "isUnlocked"
        isUnlockedAttribute.attributeType = .booleanAttributeType
        isUnlockedAttribute.isOptional = true
        
        let progressAttribute = NSAttributeDescription()
        progressAttribute.name = "progress"
        progressAttribute.attributeType = .doubleAttributeType
        progressAttribute.isOptional = true
        progressAttribute.defaultValue = 0.0
        
        achievementEntity.properties = [
            achievementIdAttribute, achievementTitleAttribute, achievementDescriptionAttribute,
            iconNameAttribute, requirementDataAttribute, isUnlockedAttribute, progressAttribute
        ]
        
        // Create CDLessonProgress entity
        let lessonProgressEntity = NSEntityDescription()
        lessonProgressEntity.name = "CDLessonProgress"
        lessonProgressEntity.managedObjectClassName = "CDLessonProgress"
        
        let lessonProgressIdAttribute = NSAttributeDescription()
        lessonProgressIdAttribute.name = "id"
        lessonProgressIdAttribute.attributeType = .UUIDAttributeType
        lessonProgressIdAttribute.isOptional = true
        
        let lessonProgressLessonIdAttribute = NSAttributeDescription()
        lessonProgressLessonIdAttribute.name = "lessonId"
        lessonProgressLessonIdAttribute.attributeType = .UUIDAttributeType
        lessonProgressLessonIdAttribute.isOptional = false
        
        let userIdAttribute = NSAttributeDescription()
        userIdAttribute.name = "userId"
        userIdAttribute.attributeType = .stringAttributeType
        userIdAttribute.isOptional = true
        
        let isCompletedAttribute = NSAttributeDescription()
        isCompletedAttribute.name = "isCompleted"
        isCompletedAttribute.attributeType = .booleanAttributeType
        isCompletedAttribute.isOptional = false
        isCompletedAttribute.defaultValue = false
        
        let isFavoriteLessonAttribute = NSAttributeDescription()
        isFavoriteLessonAttribute.name = "isFavorite"
        isFavoriteLessonAttribute.attributeType = .booleanAttributeType
        isFavoriteLessonAttribute.isOptional = false
        isFavoriteLessonAttribute.defaultValue = false
        
        let completionDateAttribute = NSAttributeDescription()
        completionDateAttribute.name = "completionDate"
        completionDateAttribute.attributeType = .dateAttributeType
        completionDateAttribute.isOptional = true
        
        let lastAccessedDateAttribute = NSAttributeDescription()
        lastAccessedDateAttribute.name = "lastAccessedDate"
        lastAccessedDateAttribute.attributeType = .dateAttributeType
        lastAccessedDateAttribute.isOptional = true
        
        let timeSpentAttribute = NSAttributeDescription()
        timeSpentAttribute.name = "timeSpent"
        timeSpentAttribute.attributeType = .doubleAttributeType
        timeSpentAttribute.isOptional = false
        timeSpentAttribute.defaultValue = 0.0
        
        let accuracyScoreAttribute = NSAttributeDescription()
        accuracyScoreAttribute.name = "accuracyScore"
        accuracyScoreAttribute.attributeType = .doubleAttributeType
        accuracyScoreAttribute.isOptional = false
        accuracyScoreAttribute.defaultValue = 0.0
        
        let stepProgressAttribute = NSAttributeDescription()
        stepProgressAttribute.name = "stepProgress"
        stepProgressAttribute.attributeType = .integer32AttributeType
        stepProgressAttribute.isOptional = true
        stepProgressAttribute.defaultValue = 0
        
        let totalStepsAttribute = NSAttributeDescription()
        totalStepsAttribute.name = "totalSteps"
        totalStepsAttribute.attributeType = .integer32AttributeType
        totalStepsAttribute.isOptional = true
        totalStepsAttribute.defaultValue = 0
        
        let lessonCreatedDateAttribute = NSAttributeDescription()
        lessonCreatedDateAttribute.name = "createdDate"
        lessonCreatedDateAttribute.attributeType = .dateAttributeType
        lessonCreatedDateAttribute.isOptional = true
        
        lessonProgressEntity.properties = [
            lessonProgressIdAttribute, lessonProgressLessonIdAttribute, userIdAttribute,
            isCompletedAttribute, isFavoriteLessonAttribute, completionDateAttribute,
            lastAccessedDateAttribute, timeSpentAttribute, accuracyScoreAttribute,
            stepProgressAttribute, totalStepsAttribute, lessonCreatedDateAttribute
        ]
        
        // Add entities to model
        model.entities = [userDrawingEntity, achievementEntity, lessonProgressEntity]
        
        // Create container with programmatic model
        let container = NSPersistentContainer(name: "SketchAI", managedObjectModel: model)
        
        // Configure store description for better error handling and migration
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.shouldInferMappingModelAutomatically = true
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Log the error but don't crash the app
                print("❌ [PERSISTENCE] CoreData error: \(error), \(error.userInfo)")
                
                // Try to delete and recreate the store if it's corrupted
                if let url = storeDescription.url {
                    do {
                        try FileManager.default.removeItem(at: url)
                        print("🔄 [PERSISTENCE] Deleted corrupted store, will recreate on next launch")
                    } catch {
                        print("❌ [PERSISTENCE] Failed to delete corrupted store: \(error)")
                    }
                }
            } else {
                print("✅ [PERSISTENCE] CoreData store loaded successfully")
            }
        }
        
        // Configure context for better performance
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil // PERFORMANCE OPTIMIZATION: Disable undo manager to save memory
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let streakCount = "streakCount"
        static let lastDrawingDate = "lastDrawingDate"
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let isProUser = "isProUser"
        static let currentSubscription = "currentSubscription"
        static let lessonTokens = "lessonTokens"
        static let subscriptionStatus = "subscriptionStatus"
        static let userID = "userID"
        static let subscriptionData = "subscriptionData"
    }
    
    // MARK: - Initialization
    init() {
        setupCoreData()
    }
    
    private func setupCoreData() {
        // CoreData setup is now handled in the container lazy initialization
        // This method is kept for potential future setup needs
        print("🚀 [PERSISTENCE] CoreData setup completed")
    }
    
    // MARK: - User Drawing Persistence
    func saveUserDrawing(_ drawing: UserDrawing) {
        
        // Check if drawing already exists
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawing.id as CVarArg)
        
        do {
            let existingDrawings = try context.fetch(fetchRequest)
            
            if let existingDrawing = existingDrawings.first {
                // Update existing drawing
                existingDrawing.updateFromUserDrawing(drawing)
            } else {
                // Create new drawing
                let cdDrawing = CDUserDrawing(context: context)
                cdDrawing.updateFromUserDrawing(drawing)
            }
            
            saveContext()
        } catch {
            print("Failed to save user drawing: \(error)")
        }
    }
    
    func loadUserDrawings() -> [UserDrawing] {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        
        // PERFORMANCE OPTIMIZATION: Configure fetch request for better performance
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUserDrawing.createdDate, ascending: false)]
        fetchRequest.fetchLimit = 100 // Limit to prevent excessive memory usage
        fetchRequest.returnsObjectsAsFaults = true // Use faulting to reduce memory usage
        
        do {
            let cdDrawings = try context.fetch(fetchRequest)
            return cdDrawings.compactMap { $0.toUserDrawing() }
        } catch {
            print("Failed to load user drawings: \(error)")
            return []
        }
    }
    
    func deleteUserDrawing(_ drawing: UserDrawing) {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", drawing.id as CVarArg)
        
        do {
            let existingDrawings = try context.fetch(fetchRequest)
            
            for cdDrawing in existingDrawings {
                context.delete(cdDrawing)
            }
            
            saveContext()
        } catch {
            print("Failed to delete user drawing: \(error)")
        }
    }
    
    // MARK: - Achievement Persistence
    func saveAchievements(_ achievements: [Achievement]) {
        Task {
            do {
                try await performBackgroundSave { backgroundContext in
                    // PERFORMANCE OPTIMIZATION: Use batch delete for clearing existing achievements
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CDAchievement.fetchRequest()
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    deleteRequest.resultType = .resultTypeObjectIDs
                    
                    do {
                        let result = try backgroundContext.execute(deleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                        }
                    } catch {
                        print("Failed to batch delete existing achievements: \(error)")
            }
            
            // Save new achievements
            for achievement in achievements {
                        let cdAchievement = CDAchievement(context: backgroundContext)
                cdAchievement.updateFromAchievement(achievement)
            }
            
                    print("✅ [PERSISTENCE] Achievements saved using background context")
                }
        } catch {
                print("❌ [PERSISTENCE] Failed to save achievements: \(error)")
            }
        }
    }
    
    func loadAchievements() -> [Achievement] {
        
        let fetchRequest: NSFetchRequest<CDAchievement> = CDAchievement.fetchRequest()
        
        // Sort by title for consistent ordering
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDAchievement.title, ascending: true)]
        
        do {
            let cdAchievements = try context.fetch(fetchRequest)
            return cdAchievements.compactMap { $0.toAchievement() }
        } catch {
            print("Failed to load achievements: \(error)")
            return []
        }
    }
    
    // MARK: - User Preferences
    func saveStreakCount(_ count: Int) {
        UserDefaults.standard.set(count, forKey: Keys.streakCount)
    }
    
    func loadStreakCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.streakCount)
    }
    
    func saveLastDrawingDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: Keys.lastDrawingDate)
    }
    
    func loadLastDrawingDate() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.lastDrawingDate) as? Date
    }
    
    func saveOnboardingComplete(_ completed: Bool) {
        UserDefaults.standard.set(completed, forKey: Keys.hasLaunchedBefore)
    }
    
    func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore)
    }
    
    // MARK: - Subscription State Persistence
    func saveSubscriptionState(isProUser: Bool, tier: String, tokens: Int, status: String) {
        UserDefaults.standard.set(isProUser, forKey: Keys.isProUser)
        UserDefaults.standard.set(tier, forKey: Keys.currentSubscription)
        UserDefaults.standard.set(tokens, forKey: Keys.lessonTokens)
        UserDefaults.standard.set(status, forKey: Keys.subscriptionStatus)
    }
    
    func loadSubscriptionState() -> (isProUser: Bool, tier: String?, tokens: Int, status: String?) {
        return (
            isProUser: UserDefaults.standard.bool(forKey: Keys.isProUser),
            tier: UserDefaults.standard.object(forKey: Keys.currentSubscription) as? String,
            tokens: UserDefaults.standard.integer(forKey: Keys.lessonTokens),
            status: UserDefaults.standard.object(forKey: Keys.subscriptionStatus) as? String
        )
    }
    
    // MARK: - Additional Query Methods
    func getUserDrawingsByCategory(_ category: LessonCategory) -> [UserDrawing] {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUserDrawing.createdDate, ascending: false)]
        
        do {
            let cdDrawings = try context.fetch(fetchRequest)
            return cdDrawings.compactMap { $0.toUserDrawing() }
        } catch {
            print("Failed to load drawings by category: \(error)")
            return []
        }
    }
    
    func getFavoriteDrawings() -> [UserDrawing] {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFavorite == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUserDrawing.createdDate, ascending: false)]
        
        do {
            let cdDrawings = try context.fetch(fetchRequest)
            return cdDrawings.compactMap { $0.toUserDrawing() }
        } catch {
            print("Failed to load favorite drawings: \(error)")
            return []
        }
    }
    
    func getRecentDrawings(limit: Int = 10) -> [UserDrawing] {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDUserDrawing.createdDate, ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            let cdDrawings = try context.fetch(fetchRequest)
            return cdDrawings.compactMap { $0.toUserDrawing() }
        } catch {
            print("Failed to load recent drawings: \(error)")
            return []
        }
    }
    
    func getUserDrawingCount() -> Int {
        
        let fetchRequest: NSFetchRequest<CDUserDrawing> = CDUserDrawing.fetchRequest()
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Failed to count user drawings: \(error)")
            return 0
        }
    }
    
    // MARK: - Core Data Helpers
    func saveContext() {
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
            // In production, you might want to implement more sophisticated error handling
            // such as presenting an alert to the user or attempting recovery
        }
    }
    
    // MARK: - Background Context Operations
    
    /// Perform a background task with optimized context configuration
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { backgroundContext in
                // PERFORMANCE OPTIMIZATION: Configure background context for better performance
                backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                backgroundContext.undoManager = nil // Disable undo manager to save memory
                
                // Use autorelease pool for memory management
                autoreleasepool {
                let result = block(backgroundContext)
                continuation.resume(returning: result)
                }
            }
        }
    }
    
    /// Perform a background save operation with proper error handling
    func performBackgroundSave<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { backgroundContext in
                // PERFORMANCE OPTIMIZATION: Configure background context
                backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                backgroundContext.undoManager = nil
                
                do {
                    let result = try block(backgroundContext)
                    
                    // Save the background context
                    if backgroundContext.hasChanges {
                        try backgroundContext.save()
                    }
                    
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Data Cleanup
    func clearAllData() {
        Task {
            do {
                try await performBackgroundSave { backgroundContext in
                    // PERFORMANCE OPTIMIZATION: Use batch delete operations for better performance
                    
                    // Clear all user drawings using batch delete
                    let drawingFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDUserDrawing.fetchRequest()
                    let drawingDeleteRequest = NSBatchDeleteRequest(fetchRequest: drawingFetchRequest)
                    drawingDeleteRequest.resultType = .resultTypeObjectIDs
                    
                    do {
                        let result = try backgroundContext.execute(drawingDeleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                        }
                    } catch {
                        print("Failed to batch delete drawings: \(error)")
                    }
                    
                    // Clear all achievements using batch delete
                    let achievementFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDAchievement.fetchRequest()
                    let achievementDeleteRequest = NSBatchDeleteRequest(fetchRequest: achievementFetchRequest)
                    achievementDeleteRequest.resultType = .resultTypeObjectIDs
                    
                    do {
                        let result = try backgroundContext.execute(achievementDeleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
            }
        } catch {
                        print("Failed to batch delete achievements: \(error)")
                    }
                    
                    // Clear all lesson progress using batch delete
                    let progressFetchRequest: NSFetchRequest<NSFetchRequestResult> = CDLessonProgress.fetchRequest()
                    let progressDeleteRequest = NSBatchDeleteRequest(fetchRequest: progressFetchRequest)
                    progressDeleteRequest.resultType = .resultTypeObjectIDs
                    
                    do {
                        let result = try backgroundContext.execute(progressDeleteRequest) as? NSBatchDeleteResult
                        if let objectIDs = result?.result as? [NSManagedObjectID] {
                            let changes = [NSDeletedObjectsKey: objectIDs]
                            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                        }
                    } catch {
                        print("Failed to batch delete lesson progress: \(error)")
                    }
                    
                    print("✅ [PERSISTENCE] All data cleared using batch operations")
                }
            } catch {
                print("❌ [PERSISTENCE] Failed to clear all data: \(error)")
            }
        }
    }
    
    // MARK: - User ID Management
    func loadUserID() -> String? {
        return UserDefaults.standard.string(forKey: Keys.userID)
    }
    
    func saveUserID(_ userID: String) {
        UserDefaults.standard.set(userID, forKey: Keys.userID)
    }
    
    // MARK: - Subscription Data Management
    func saveSubscriptionData(_ subscriptionData: SubscriptionData) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(subscriptionData)
            UserDefaults.standard.set(data, forKey: Keys.subscriptionData)
        } catch {
            print("Failed to save subscription data: \(error)")
        }
    }
    
    func loadSubscriptionData() -> SubscriptionData? {
        guard let data = UserDefaults.standard.data(forKey: Keys.subscriptionData) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(SubscriptionData.self, from: data)
        } catch {
            print("Failed to load subscription data: \(error)")
            return nil
        }
    }
    
    // MARK: - Lesson Progress Persistence
    
    /// Save or update lesson progress
    func saveLessonProgress(_ progress: LessonProgress) {
        
        // Check if progress already exists for this lesson and user
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           progress.lessonId as CVarArg, 
                                           progress.userId ?? "" as CVarArg)
        
        do {
            let existingProgress = try context.fetch(fetchRequest)
            
            if let existingProgress = existingProgress.first {
                // Update existing progress
                existingProgress.updateFromLessonProgress(progress)
            } else {
                // Create new progress record
                let cdProgress = CDLessonProgress(context: context)
                cdProgress.updateFromLessonProgress(progress)
            }
            
            saveContext()
        } catch {
            print("Failed to save lesson progress: \(error)")
        }
    }
    
    /// Load lesson progress for a specific lesson and user
    func loadLessonProgress(lessonId: UUID, userId: String?) -> LessonProgress? {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           lessonId as CVarArg, 
                                           userId ?? "" as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let cdProgress = try context.fetch(fetchRequest)
            return cdProgress.first?.toLessonProgress()
        } catch {
            print("Failed to load lesson progress: \(error)")
            return nil
        }
    }
    
    /// Load all lesson progress for a specific user
    func loadAllLessonProgress(userId: String?) -> [LessonProgress] {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId ?? "" as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CDLessonProgress.lastAccessedDate, ascending: false)]
        
        do {
            let cdProgressList = try context.fetch(fetchRequest)
            return cdProgressList.compactMap { $0.toLessonProgress() }
        } catch {
            print("Failed to load all lesson progress: \(error)")
            return []
        }
    }
    
    /// Load favorite lessons for a user
    func loadFavoriteLessons(userId: String?) -> [UUID] {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND isFavorite == YES", userId ?? "" as CVarArg)
        
        do {
            let cdProgressList = try context.fetch(fetchRequest)
            return cdProgressList.map { $0.lessonId }
        } catch {
            print("Failed to load favorite lessons: \(error)")
            return []
        }
    }
    
    /// Load completed lessons for a user
    func loadCompletedLessons(userId: String?) -> [UUID] {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@ AND isCompleted == YES", userId ?? "" as CVarArg)
        
        do {
            let cdProgressList = try context.fetch(fetchRequest)
            return cdProgressList.map { $0.lessonId }
        } catch {
            print("Failed to load completed lessons: \(error)")
            return []
        }
    }
    
    /// Toggle favorite status for a lesson
    func toggleLessonFavorite(lessonId: UUID, userId: String?) {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           lessonId as CVarArg, 
                                           userId ?? "" as CVarArg)
        
        do {
            let existingProgress = try context.fetch(fetchRequest)
            
            if let progress = existingProgress.first {
                // Update existing progress
                progress.isFavorite.toggle()
                progress.lastAccessedDate = Date()
            } else {
                // Create new progress with favorite status
                let newProgress = LessonProgress(lessonId: lessonId, userId: userId)
                var mutableProgress = newProgress
                mutableProgress.toggleFavorite()
                
                let cdProgress = CDLessonProgress(context: context)
                cdProgress.updateFromLessonProgress(mutableProgress)
            }
            
            saveContext()
        } catch {
            print("Failed to toggle lesson favorite: \(error)")
        }
    }
    
    /// Mark lesson as completed
    func markLessonCompleted(lessonId: UUID, userId: String?, accuracyScore: Double = 0.0, timeSpent: Double = 0.0) {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           lessonId as CVarArg, 
                                           userId ?? "" as CVarArg)
        
        do {
            let existingProgress = try context.fetch(fetchRequest)
            
            if let progress = existingProgress.first {
                // Update existing progress
                progress.isCompleted = true
                progress.completionDate = Date()
                progress.accuracyScore = accuracyScore
                progress.timeSpent += timeSpent
                progress.lastAccessedDate = Date()
            } else {
                // Create new progress with completion status
                let newProgress = LessonProgress(lessonId: lessonId, userId: userId)
                var mutableProgress = newProgress
                mutableProgress.markCompleted(accuracyScore: accuracyScore)
                mutableProgress.timeSpent = timeSpent
                
                let cdProgress = CDLessonProgress(context: context)
                cdProgress.updateFromLessonProgress(mutableProgress)
            }
            
            saveContext()
        } catch {
            print("Failed to mark lesson completed: \(error)")
        }
    }
    
    /// Update lesson step progress
    func updateLessonProgress(lessonId: UUID, userId: String?, currentStep: Int, totalSteps: Int, timeSpent: Double = 0.0) {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           lessonId as CVarArg, 
                                           userId ?? "" as CVarArg)
        
        do {
            let existingProgress = try context.fetch(fetchRequest)
            
            if let progress = existingProgress.first {
                // Update existing progress
                progress.stepProgress = Int32(currentStep)
                progress.totalSteps = Int32(totalSteps)
                progress.timeSpent += timeSpent
                progress.lastAccessedDate = Date()
            } else {
                // Create new progress
                let newProgress = LessonProgress(lessonId: lessonId, userId: userId)
                var mutableProgress = newProgress
                mutableProgress.updateProgress(currentStep: currentStep, totalSteps: totalSteps, timeSpent: timeSpent)
                
                let cdProgress = CDLessonProgress(context: context)
                cdProgress.updateFromLessonProgress(mutableProgress)
            }
            
            saveContext()
        } catch {
            print("Failed to update lesson progress: \(error)")
        }
    }
    
    /// Get lesson statistics for a user
    func getLessonStatistics(userId: String?) -> (completed: Int, favorites: Int, totalTimeSpent: Double) {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userId == %@", userId ?? "" as CVarArg)
        
        do {
            let progressList = try context.fetch(fetchRequest)
            let completed = progressList.filter { $0.isCompleted }.count
            let favorites = progressList.filter { $0.isFavorite }.count
            let totalTimeSpent = progressList.reduce(0.0) { $0 + $1.timeSpent }
            
            return (completed: completed, favorites: favorites, totalTimeSpent: totalTimeSpent)
        } catch {
            print("Failed to get lesson statistics: \(error)")
            return (completed: 0, favorites: 0, totalTimeSpent: 0.0)
        }
    }
    
    /// Delete lesson progress for a specific lesson
    func deleteLessonProgress(lessonId: UUID, userId: String?) {
        
        let fetchRequest: NSFetchRequest<CDLessonProgress> = CDLessonProgress.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "lessonId == %@ AND userId == %@", 
                                           lessonId as CVarArg, 
                                           userId ?? "" as CVarArg)
        
        do {
            let progressList = try context.fetch(fetchRequest)
            for progress in progressList {
                context.delete(progress)
            }
            saveContext()
        } catch {
            print("Failed to delete lesson progress: \(error)")
        }
    }
}
