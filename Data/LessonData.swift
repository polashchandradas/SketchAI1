import Foundation

struct LessonData {
    static let sampleLessons: [Lesson] = [
        // MARK: - Faces & Portraits
        Lesson(
            title: "Basic Face Proportions",
            description: "Learn the fundamental proportions of a human face using the classic oval and guideline method.",
            category: .faces,
            difficulty: .beginner,
            thumbnailImageName: "face_basic",
            referenceImageName: "face_basic",
            estimatedTime: 15,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw an oval for the head", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 2, instruction: "Add horizontal guideline for eyes", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 3, instruction: "Mark nose position", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 4, instruction: "Draw mouth guideline", guidancePoints: [], shapeType: .line)
            ]
        ),
        
        Lesson(
            title: "Portrait with Loomis Method",
            description: "Master the advanced Loomis method for accurate head construction and facial feature placement.",
            category: .faces,
            difficulty: .advanced,
            thumbnailImageName: "face_loomis",
            referenceImageName: "face_loomis",
            estimatedTime: 45,
            isPremium: true,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw the basic sphere", guidancePoints: [], shapeType: .circle),
                LessonStep(stepNumber: 2, instruction: "Add facial plane guidelines", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 3, instruction: "Construct the jaw and chin", guidancePoints: [], shapeType: .curve),
                LessonStep(stepNumber: 4, instruction: "Place facial features accurately", guidancePoints: [], shapeType: .oval)
            ]
        ),
        
        Lesson(
            title: "Eyes and Expression",
            description: "Focus on drawing expressive eyes with proper eyelid construction and iris placement.",
            category: .faces,
            difficulty: .intermediate,
            thumbnailImageName: "face_eyes",
            referenceImageName: "face_eyes",
            estimatedTime: 25,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw almond shapes for eye outline", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 2, instruction: "Add iris circles", guidancePoints: [], shapeType: .circle),
                LessonStep(stepNumber: 3, instruction: "Define upper and lower eyelids", guidancePoints: [], shapeType: .curve),
                LessonStep(stepNumber: 4, instruction: "Add pupils and highlights", guidancePoints: [], shapeType: .circle)
            ]
        ),
        
        // MARK: - Animals
        Lesson(
            title: "Simple Cat Face",
            description: "Learn to draw an adorable cat face using basic geometric shapes and proportions.",
            category: .animals,
            difficulty: .beginner,
            thumbnailImageName: "animal_cat",
            referenceImageName: "animal_cat",
            estimatedTime: 20,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw circle for head", guidancePoints: [], shapeType: .circle),
                LessonStep(stepNumber: 2, instruction: "Add triangular ears", guidancePoints: [], shapeType: .polygon),
                LessonStep(stepNumber: 3, instruction: "Place eyes and nose", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 4, instruction: "Draw whiskers and mouth", guidancePoints: [], shapeType: .line)
            ]
        ),
        
        Lesson(
            title: "Realistic Dog Portrait",
            description: "Create a detailed dog portrait focusing on fur texture and realistic proportions.",
            category: .animals,
            difficulty: .advanced,
            thumbnailImageName: "animal_dog",
            referenceImageName: "animal_dog",
            estimatedTime: 60,
            isPremium: true,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Establish basic head shape", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 2, instruction: "Define snout proportions", guidancePoints: [], shapeType: .rectangle),
                LessonStep(stepNumber: 3, instruction: "Add ear placement", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 4, instruction: "Detail eyes and nose", guidancePoints: [], shapeType: .circle)
            ]
        ),
        
        Lesson(
            title: "Bird in Flight",
            description: "Capture the grace of a bird in flight with proper wing anatomy and proportions.",
            category: .animals,
            difficulty: .intermediate,
            thumbnailImageName: "animal_bird",
            referenceImageName: "animal_bird",
            estimatedTime: 35,
            isPremium: true,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw body oval", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 2, instruction: "Add wing guidelines", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 3, instruction: "Define wing shapes", guidancePoints: [], shapeType: .curve),
                LessonStep(stepNumber: 4, instruction: "Add head and tail details", guidancePoints: [], shapeType: .oval)
            ]
        ),
        
        // MARK: - Objects
        Lesson(
            title: "Basic Cube and Shading",
            description: "Master 3D form drawing with a simple cube and learn fundamental shading techniques.",
            category: .objects,
            difficulty: .beginner,
            thumbnailImageName: "object_cube",
            referenceImageName: "object_cube",
            estimatedTime: 15,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw front face square", guidancePoints: [], shapeType: .rectangle),
                LessonStep(stepNumber: 2, instruction: "Add side perspective lines", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 3, instruction: "Complete the cube form", guidancePoints: [], shapeType: .rectangle),
                LessonStep(stepNumber: 4, instruction: "Add shading for depth", guidancePoints: [], shapeType: .rectangle)
            ]
        ),
        
        Lesson(
            title: "Still Life Apple",
            description: "Draw a realistic apple with proper form, highlights, and shadow to create depth.",
            category: .objects,
            difficulty: .intermediate,
            thumbnailImageName: "object_apple",
            referenceImageName: "object_apple",
            estimatedTime: 30,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw basic apple shape", guidancePoints: [], shapeType: .circle),
                LessonStep(stepNumber: 2, instruction: "Add stem indentation", guidancePoints: [], shapeType: .curve),
                LessonStep(stepNumber: 3, instruction: "Define the apple's volume", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 4, instruction: "Add highlights and shadows", guidancePoints: [], shapeType: .oval)
            ]
        ),
        
        // MARK: - Hands & Poses
        Lesson(
            title: "Basic Hand Structure",
            description: "Understand hand anatomy and proportions using simple geometric breakdown methods.",
            category: .hands,
            difficulty: .intermediate,
            thumbnailImageName: "hand_basic",
            referenceImageName: "hand_basic",
            estimatedTime: 40,
            isPremium: true,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Draw palm rectangle", guidancePoints: [], shapeType: .rectangle),
                LessonStep(stepNumber: 2, instruction: "Add finger length guides", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 3, instruction: "Define finger segments", guidancePoints: [], shapeType: .oval),
                LessonStep(stepNumber: 4, instruction: "Refine finger curves", guidancePoints: [], shapeType: .curve)
            ]
        ),
        
        // MARK: - Perspective Basics
        Lesson(
            title: "One-Point Perspective",
            description: "Learn the fundamentals of one-point perspective to create depth in your drawings.",
            category: .perspective,
            difficulty: .beginner,
            thumbnailImageName: "perspective_basic",
            referenceImageName: "perspective_basic",
            estimatedTime: 25,
            isPremium: false,
            steps: [
                LessonStep(stepNumber: 1, instruction: "Establish horizon line", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 2, instruction: "Mark vanishing point", guidancePoints: [], shapeType: .circle),
                LessonStep(stepNumber: 3, instruction: "Draw converging lines", guidancePoints: [], shapeType: .line),
                LessonStep(stepNumber: 4, instruction: "Add basic shapes in perspective", guidancePoints: [], shapeType: .rectangle)
            ]
        )
    ]
}

struct AchievementData {
    static let defaultAchievements: [Achievement] = [
        Achievement(
            title: "First Steps",
            description: "Complete your first drawing",
            iconName: "star.fill",
            requirement: .firstDrawing
        ),
        Achievement(
            title: "Getting Started",
            description: "Complete 5 drawings",
            iconName: "star.circle.fill",
            requirement: .drawingsCount(5)
        ),
        Achievement(
            title: "Dedicated Artist",
            description: "Draw for 7 days in a row",
            iconName: "flame.fill",
            requirement: .streak(days: 7)
        ),
        Achievement(
            title: "Face Master",
            description: "Complete 10 face drawings",
            iconName: "person.crop.circle.fill",
            requirement: .categoryMastery(category: .faces, count: 10)
        ),
        Achievement(
            title: "Animal Lover",
            description: "Complete 10 animal drawings",
            iconName: "pawprint.fill",
            requirement: .categoryMastery(category: .animals, count: 10)
        ),
        Achievement(
            title: "Persistent",
            description: "Draw for 30 days in a row",
            iconName: "calendar.badge.plus",
            requirement: .streak(days: 30)
        ),
        Achievement(
            title: "Prolific Artist",
            description: "Complete 50 drawings",
            iconName: "paintbrush.pointed.fill",
            requirement: .drawingsCount(50)
        )
    ]
}

