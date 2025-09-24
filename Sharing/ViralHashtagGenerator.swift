import Foundation
import SwiftUI

// MARK: - Viral Hashtag Generator
// Generates relevant hashtags for viral content based on lesson category, difficulty, and trends

@MainActor
class ViralHashtagGenerator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generatedHashtags: [String] = []
    @Published var trendingHashtags: [String] = []
    
    // MARK: - Configuration
    private struct Config {
        static let maxHashtags = 30
        static let maxRecommended = 10
        static let baseAppHashtags = ["SketchAI", "LearnToDraw", "DigitalArt", "DrawingTutorial", "ArtTutorial", "DrawingApp"]
    }
    
    // MARK: - Hashtag Categories
    private enum HashtagCategory {
        case base
        case category
        case difficulty  
        case trending
        case viral
        case platform
        case community
    }
    
    // MARK: - Main Generation Methods
    
    /// Generate hashtags for a specific lesson and drawing
    func generateHashtags(
        for lesson: Lesson?,
        drawing: UserDrawing,
        includeAppPromo: Bool = true,
        targetPlatform: SocialPlatform = .general
    ) -> [String] {
        
        var hashtags: [String] = []
        
        // Base app hashtags
        if includeAppPromo {
            hashtags.append(contentsOf: Config.baseAppHashtags)
        }
        
        // Category-specific hashtags
        if let lesson = lesson {
            hashtags.append(contentsOf: getCategoryHashtags(for: lesson.category))
            hashtags.append(contentsOf: getDifficultyHashtags(for: lesson.difficulty))
        }
        
        // Drawing-specific hashtags
        hashtags.append(contentsOf: getDrawingHashtags(for: drawing))
        
        // Platform-specific hashtags
        hashtags.append(contentsOf: getPlatformHashtags(for: targetPlatform))
        
        // Viral trend hashtags
        hashtags.append(contentsOf: getViralTrendHashtags())
        
        // Community hashtags
        hashtags.append(contentsOf: getCommunityHashtags())
        
        // Remove duplicates and limit
        let uniqueHashtags = Array(Set(hashtags))
        return Array(uniqueHashtags.prefix(Config.maxHashtags))
    }
    
    /// Generate hashtags specifically for viral templates
    func generateViralTemplateHashtags(
        template: ViralTemplate,
        lesson: Lesson?,
        includeAppPromo: Bool = true
    ) -> [String] {
        
        var hashtags: [String] = []
        
        // Base hashtags
        if includeAppPromo {
            hashtags.append(contentsOf: Config.baseAppHashtags)
        }
        
        // Template-specific hashtags
        hashtags.append(contentsOf: getTemplateHashtags(for: template))
        
        // Category hashtags if available
        if let lesson = lesson {
            hashtags.append(contentsOf: getCategoryHashtags(for: lesson.category))
        }
        
        // Viral trend hashtags
        hashtags.append(contentsOf: getViralTrendHashtags())
        
        // Platform optimization hashtags
        hashtags.append(contentsOf: ["fyp", "viral", "trending", "foryou", "explore"])
        
        return Array(Set(hashtags))
    }
    
    /// Generate hashtags for specific art challenges (e.g., #Inktober, #Mermay)
    func generateChallengeHashtags(
        challengeName: String,
        dayNumber: Int? = nil,
        customPrompt: String? = nil
    ) -> [String] {
        
        var hashtags: [String] = []
        
        // Challenge-specific hashtags
        hashtags.append(challengeName.lowercased())
        
        if let day = dayNumber {
            hashtags.append("\(challengeName.lowercased())day\(day)")
            hashtags.append("day\(day)")
        }
        
        if let prompt = customPrompt {
            hashtags.append(prompt.lowercased().replacingOccurrences(of: " ", with: ""))
        }
        
        // General challenge hashtags
        hashtags.append(contentsOf: [
            "artchallenge",
            "dailyart",
            "artprompt",
            "drawingchallenge",
            "artistsoninstagram",
            "artistsontiktok"
        ])
        
        return hashtags
    }
    
    // MARK: - Category-Specific Hashtags
    
    private func getCategoryHashtags(for category: LessonCategory) -> [String] {
        switch category {
        case .faces:
            return [
                "portraitdrawing", "facedrawing", "portraitart", "faceartist",
                "portraitsketch", "humanface", "portraiture", "faceart",
                "realisticportrait", "portraitpractice", "faceproportions"
            ]
            
        case .animals:
            return [
                "animalart", "animalDrawing", "wildlifeart", "petportrait",
                "animalsketch", "natureart", "wildlifeDrawing", "animalartist",
                "cuteanimals", "animalsketching", "wildlifeillustration"
            ]
            
        case .objects:
            return [
                "stilllife", "objectdrawing", "observationaldrawing", "stilllifeart",
                "objectstudy", "drawingfromlife", "realisticdrawing", "studyart",
                "objectrendering", "stilllifesketch", "artfundamentals"
            ]
            
        case .hands:
            return [
                "handdrawing", "handart", "anatomydrawing", "handstudy",
                "anatomyart", "handsketch", "anatomypractice", "handpose",
                "anatomystudy", "handreference", "figureart"
            ]
            
        case .perspective:
            return [
                "perspective", "perspectiveart", "architecture", "perspectiveDrawing",
                "architecturalart", "buildingdrawing", "urbansketch", "perspectivesketch",
                "architecturesketch", "technicalDrawing", "spatialart"
            ]
            
        case .nature:
            return [
                "natureart", "landscapeart", "botanicalart", "naturesketch",
                "outdoorart", "pleinair", "natureDrawing", "botanicalDrawing",
                "landscapeDrawing", "naturestudies", "environmentalart"
            ]
        }
    }
    
    private func getDifficultyHashtags(for difficulty: DifficultyLevel) -> [String] {
        switch difficulty {
        case .beginner:
            return [
                "beginnerart", "learningtodraw", "artbeginner", "newartist",
                "basicdrawing", "startingout", "artjourney", "firstdrawing",
                "beginnerartist", "learningart", "artbasics"
            ]
            
        case .intermediate:
            return [
                "improvingskills", "artprogress", "levelingup", "skillbuilding",
                "artimprovement", "practicemaking perfect", "artgrowth",
                "intermediateartist", "buildingskills", "artdevelopment"
            ]
            
        case .advanced:
            return [
                "advancedart", "masterpiece", "skilleddrawing", "expertart",
                "professionaldrawing", "mastery", "advancedtechnique",
                "artisticexcellence", "highskill", "artmastery"
            ]
        }
    }
    
    private func getDrawingHashtags(for drawing: UserDrawing) -> [String] {
        var hashtags: [String] = []
        
        // Time-based hashtags
        let creationDate = drawing.createdDate
        let calendar = Calendar.current
        
        if calendar.isDateInToday(creationDate) {
            hashtags.append("todaysdrawing")
        }
        
        if calendar.isDateInYesterday(creationDate) {
            hashtags.append("yesterdaysdrawing")
        }
        
        // Week-based hashtags
        let weekday = calendar.component(.weekday, from: creationDate)
        let weekdayNames = ["", "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        if weekday < weekdayNames.count {
            hashtags.append("\(weekdayNames[weekday])art")
        }
        
        // Title-based hashtags (if applicable)
        let titleWords = drawing.title.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        for word in titleWords.prefix(3) {
            hashtags.append(word.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression))
        }
        
        return hashtags
    }
    
    private func getTemplateHashtags(for template: ViralTemplate) -> [String] {
        switch template {
        case .classicReveal:
            return [
                "beforeandafter", "transformation", "artreveal", "processvideo",
                "drawingrevealed", "artmagic", "stepbystep", "howitsmade",
                "artprocess", "revealed", "arttransformation"
            ]
            
        case .progressGlowUp:
            return [
                "glowup", "artglowup", "progress", "improvement", "beforeafter",
                "talentispursuedinterest", "bobross", "skillbuilding", "artjourney",
                "practicing", "getbetter", "nevergiveup", "keepgoing"
            ]
            
        case .memeFormat:
            return [
                "artmeme", "relatable", "artstruggle", "artistproblems",
                "meme", "funny", "humor", "arthumor", "drawingjokes",
                "artistlife", "artstudentlife", "mood"
            ]
        }
    }
    
    private func getPlatformHashtags(for platform: SocialPlatform) -> [String] {
        switch platform {
        case .tikTok:
            return [
                "tiktokart", "arttok", "drawingtok", "artistsontiktok",
                "fyp", "foryou", "viral", "trending", "arttiktok"
            ]
            
        case .instagram:
            return [
                "instagramart", "artistsoninstagram", "instaart", "artofinstagram",
                "igartist", "explore", "artcommunity", "instadraw"
            ]
            
        case .general:
            return [
                "art", "drawing", "sketch", "artist", "artwork",
                "creative", "illustration", "design"
            ]
            
        default:
            return []
        }
    }
    
    private func getViralTrendHashtags() -> [String] {
        // These would ideally be updated based on current trends
        // For now, we'll use commonly viral art-related hashtags
        return [
            "satisfying", "oddlysatisfying", "mesmerizing", "mindblowing",
            "incredible", "amazing", "wow", "unbelievable", "talent",
            "skills", "gifted", "artistic", "creative", "inspiring"
        ]
    }
    
    private func getCommunityHashtags() -> [String] {
        return [
            "artcommunity", "supportartists", "artistsupport", "artshare",
            "drawingcommunity", "artfamily", "creatives", "artistsonline",
            "artlovers", "artappreciation", "emergingartist", "undiscoveredartist"
        ]
    }
    
    // MARK: - Trending Hashtag Analysis
    
    /// Simulate trending hashtag analysis (in production, this would connect to APIs)
    func fetchTrendingHashtags(for category: LessonCategory? = nil) async -> [String] {
        isGenerating = true
        
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        var trending: [String] = []
        
        // Simulate trending hashtags based on current "trends"
        let baseTrending = [
            "artchallenge2024", "digitalartist", "procreate", "ipadart",
            "drawdaily", "artoftheday", "sketchbook", "artistlife",
            "workinprogress", "arttherapy", "mindfulart", "relaxingart"
        ]
        
        trending.append(contentsOf: baseTrending)
        
        // Add category-specific trending if provided
        if let category = category {
            let categoryTrending = getCategoryTrendingHashtags(for: category)
            trending.append(contentsOf: categoryTrending)
        }
        
        await MainActor.run { [trending] in
            self.trendingHashtags = trending
            self.isGenerating = false
        }
        
        return trending
    }
    
    private func getCategoryTrendingHashtags(for category: LessonCategory) -> [String] {
        switch category {
        case .faces:
            return ["portraitchallenge", "selfportrait", "characterdesign"]
        case .animals:
            return ["petportrait", "wildlifewednesday", "animalcrossing"]
        case .objects:
            return ["everydayobjects", "minimalism", "stilllifechallenge"]
        case .hands:
            return ["anatomychallenge", "handposes", "gesturedrawing"]
        case .perspective:
            return ["architecturalart", "urbansketch", "onepoint"]
        case .nature:
            return ["botanicalart", "naturejournaling", "pleinairpainting"]
        }
    }
    
    // MARK: - Hashtag Optimization
    
    /// Optimize hashtags for maximum reach based on platform and content
    func optimizeHashtags(
        _ hashtags: [String],
        for platform: SocialPlatform,
        maxCount: Int = 30
    ) -> [String] {
        
        var optimized = hashtags
        
        // Platform-specific optimization
        switch platform {
        case .tikTok:
            // TikTok prefers shorter, trendier hashtags
            optimized = optimized.filter { $0.count <= 20 }
            
        case .instagram:
            // Instagram allows more hashtags, mix popular and niche
            optimized = balancePopularAndNiche(hashtags)
            
        default:
            break
        }
        
        // Remove duplicates and limit count
        let uniqueHashtags = Array(Set(optimized))
        return Array(uniqueHashtags.prefix(maxCount))
    }
    
    private func balancePopularAndNiche(_ hashtags: [String]) -> [String] {
        // In a real implementation, this would analyze hashtag popularity
        // For now, we'll just shuffle and return
        return hashtags.shuffled()
    }
    
    // MARK: - Hashtag Suggestions
    
    /// Get suggested hashtags based on user's previous successful posts
    func getSuggestedHashtags(basedOnHistory userHistory: [UserDrawing]) -> [String] {
        // Analyze user's previous drawings for patterns
        var suggestions: [String] = []
        
        // Find most common categories
        let categories = userHistory.compactMap { $0.category }
        let categoryCounts = Dictionary(grouping: categories, by: { $0 }).mapValues { $0.count }
        let topCategories = categoryCounts.sorted { $0.value > $1.value }.prefix(3)
        
        for (category, _) in topCategories {
            suggestions.append(contentsOf: getCategoryHashtags(for: category).prefix(3))
        }
        
        // Add personalized suggestions
        suggestions.append(contentsOf: [
            "myartstyle", "personalproject", "artisticjourney",
            "myartwork", "originalart", "handdrawn"
        ])
        
        return Array(Set(suggestions))
    }
    
    // MARK: - Hashtag Validation
    
    /// Validate hashtags for platform compliance
    func validateHashtags(_ hashtags: [String], for platform: SocialPlatform) -> [String] {
        return hashtags.compactMap { hashtag in
            let cleaned = cleanHashtag(hashtag)
            return isValidHashtag(cleaned, for: platform) ? cleaned : nil
        }
    }
    
    private func cleanHashtag(_ hashtag: String) -> String {
        // Remove special characters, spaces, and ensure proper format
        let cleaned = hashtag
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        
        return cleaned
    }
    
    private func isValidHashtag(_ hashtag: String, for platform: SocialPlatform) -> Bool {
        // Basic validation rules
        guard hashtag.count >= 2 && hashtag.count <= 30 else { return false }
        guard !hashtag.isEmpty else { return false }
        guard hashtag.first?.isLetter == true else { return false }
        
        // Platform-specific rules
        switch platform {
        case .tikTok:
            return hashtag.count <= 20 // TikTok prefers shorter hashtags
        case .instagram:
            return hashtag.count <= 30 // Instagram allows longer hashtags
        default:
            return true
        }
    }
}

// MARK: - Supporting Types

// SocialPlatform enum defined in EnhancedSocialSharingManager.swift

// MARK: - Hashtag Analytics (Future Enhancement)

struct HashtagAnalytics {
    let hashtag: String
    let estimatedReach: Int
    let competitionLevel: CompetitionLevel
    let trendStatus: TrendStatus
    
    enum CompetitionLevel {
        case low, medium, high
    }
    
    enum TrendStatus {
        case trending, stable, declining
    }
}

// MARK: - Extensions

extension ViralHashtagGenerator {
    
    /// Generate hashtags with analytics (premium feature)
    func generateHashtagsWithAnalytics(
        for lesson: Lesson?,
        drawing: UserDrawing,
        targetPlatform: SocialPlatform = .general
    ) -> [(String, HashtagAnalytics)] {
        
        let hashtags = generateHashtags(for: lesson, drawing: drawing, targetPlatform: targetPlatform)
        
        return hashtags.map { hashtag in
            let analytics = HashtagAnalytics(
                hashtag: hashtag,
                estimatedReach: Int.random(in: 1000...100000),
                competitionLevel: HashtagAnalytics.CompetitionLevel.allCases.randomElement() ?? .medium,
                trendStatus: HashtagAnalytics.TrendStatus.allCases.randomElement() ?? .stable
            )
            return (hashtag, analytics)
        }
    }
}

extension HashtagAnalytics.CompetitionLevel: CaseIterable {}
extension HashtagAnalytics.TrendStatus: CaseIterable {}





