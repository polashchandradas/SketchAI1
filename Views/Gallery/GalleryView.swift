import SwiftUI
import UIKit

// MARK: - Simple Image Cache for Performance Optimization
class SimpleImageCache {
    static let shared = SimpleImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func getImage(for key: String, from data: Data) -> UIImage? {
        if let cachedImage = cache.object(forKey: NSString(string: key)) {
            return cachedImage
        }
        
        guard let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: NSString(string: key))
        return image
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}

// MARK: - Optimized Image View
struct OptimizedImageView: View {
    let imageData: Data
    let contentMode: ContentMode
    let frameHeight: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let key = "\(imageData.hashValue)"
        
        if let cachedImage = SimpleImageCache.shared.getImage(for: key, from: imageData) {
            self.image = cachedImage
            self.isLoading = false
        } else {
            // Fallback to direct UIImage creation
            DispatchQueue.global(qos: .userInitiated).async {
                let uiImage = UIImage(data: imageData)
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            }
        }
    }
}

struct GalleryView: View {
    @EnvironmentObject var userProfileService: UserProfileService
    
    @State private var selectedCategory: LessonCategory?
    @State private var sortOption: SortOption = .newest
    @State private var showSortOptions = false
    @State private var selectedDrawing: UserDrawing?
    
    // OPTIMIZED: Cache filtered and sorted drawings to avoid recalculation
    @State private var cachedFilteredDrawings: [UserDrawing] = []
    @State private var lastFilterCategory: LessonCategory?
    @State private var lastSortOption: SortOption = .newest
    
    var filteredAndSortedDrawings: [UserDrawing] {
        // Only recalculate if filters or sort options changed
        if selectedCategory != lastFilterCategory || sortOption != lastSortOption {
            updateCachedDrawings()
        }
        return cachedFilteredDrawings
    }
    
    private func updateCachedDrawings() {
        var drawings = userProfileService.userDrawings
        
        // Apply category filter
        if let category = selectedCategory {
            drawings = drawings.filter { $0.category == category }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            drawings = drawings.sorted { $0.createdDate > $1.createdDate }
        case .oldest:
            drawings = drawings.sorted { $0.createdDate < $1.createdDate }
        case .category:
            drawings = drawings.sorted { 
                ($0.category?.rawValue ?? "") < ($1.category?.rawValue ?? "") 
            }
        }
        
        cachedFilteredDrawings = drawings
        lastFilterCategory = selectedCategory
        lastSortOption = sortOption
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters and sort options
                FiltersAndSortSection(
                    selectedCategory: $selectedCategory,
                    sortOption: $sortOption,
                    showSortOptions: $showSortOptions,
                    drawingsCount: filteredAndSortedDrawings.count
                )
                
                // Gallery grid with optimized image loading
                GalleryGridSection(
                    drawings: filteredAndSortedDrawings,
                    selectedDrawing: $selectedDrawing
                )
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog("Sort By", isPresented: $showSortOptions, titleVisibility: .visible) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(option.rawValue) {
                        sortOption = option
                    }
                    .accessibilityLabel("Sort by \(option.rawValue)")
                }
            }
            .sheet(item: $selectedDrawing) { drawing in
                DrawingDetailView(drawing: drawing)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Gallery with \(filteredAndSortedDrawings.count) drawings")
            .onChange(of: selectedCategory) { _ in
                updateCachedDrawings()
            }
            .onChange(of: sortOption) { _ in
                updateCachedDrawings()
            }
            .refreshable {
                // Refresh user drawings from persistence service
                userProfileService.loadUserData()
                updateCachedDrawings()
            }
        }
        .onAppear {
            // Initialize cached drawings on first appearance
            updateCachedDrawings()
        }
    }
}

struct FiltersAndSortSection: View {
    @Binding var selectedCategory: LessonCategory?
    @Binding var sortOption: SortOption
    @Binding var showSortOptions: Bool
    let drawingsCount: Int
    
    // MARK: - Adaptive Layout Properties
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Design Constants
    private let sectionSpacing: CGFloat = 16
    private let chipSpacing: CGFloat = 8
    private let horizontalPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 16
    
    private var adaptiveHorizontalPadding: CGFloat {
        return horizontalSizeClass == .regular ? 20 : horizontalPadding
    }
    
    var body: some View {
        VStack(spacing: sectionSpacing) {
            // Category filter with consistent spacing
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: chipSpacing) {
                    GalleryFilterChip(
                        title: "All",
                        isSelected: selectedCategory == nil
                    ) {
                        selectedCategory = nil
                    }
                    
                    ForEach(LessonCategory.allCases, id: \.self) { category in
                        GalleryFilterChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.horizontal, adaptiveHorizontalPadding)
            }
            
            // Sort options with consistent spacing and accessibility
            HStack {
                Button {
                    showSortOptions = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .accessibilityHidden(true) // Icon is decorative
                        Text(sortOption.rawValue)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .accessibilityLabel("Sort by \(sortOption.rawValue)")
                .accessibilityHint("Double tap to change sort order")
                .accessibilityAddTraits(.isButton)
                
                Spacer()
                
                Text("\(drawingsCount) drawings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("\(drawingsCount) drawings total")
                    .accessibilityAddTraits(.isStaticText)
            }
            .padding(.horizontal, adaptiveHorizontalPadding)
        }
        .padding(.bottom, bottomPadding)
    }
}

struct GalleryGridSection: View {
    let drawings: [UserDrawing]
    @Binding var selectedDrawing: UserDrawing?
    
    // MARK: - Adaptive Layout Properties
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var adaptiveColumns: [GridItem] {
        let isIPad = horizontalSizeClass == .regular
        let columnCount = isIPad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount)
    }
    
    private var adaptiveSpacing: CGFloat {
        return horizontalSizeClass == .regular ? 16 : 12
    }
    
    private var adaptivePadding: CGFloat {
        return horizontalSizeClass == .regular ? 20 : 16
    }
    
    var body: some View {
        if drawings.isEmpty {
            EmptyGalleryView(selectedCategory: nil)
        } else {
            ScrollView {
                LazyVGrid(
                    columns: adaptiveColumns,
                    spacing: adaptiveSpacing
                ) {
                    ForEach(drawings) { drawing in
                        DrawingThumbnailView(drawing: drawing) {
                            selectedDrawing = drawing
                        }
                    }
                }
                .padding(adaptivePadding)
                .padding(.bottom, 120) // Space for tab bar
            }
        }
    }
}

struct DrawingThumbnailView: View {
    let drawing: UserDrawing
    let onTap: () -> Void
    
    // MARK: - Adaptive Layout Properties
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // MARK: - Design Constants
    private let cornerRadius: CGFloat = 12
    private let imageCornerRadius: CGFloat = 8
    private let contentSpacing: CGFloat = 8
    private let infoSpacing: CGFloat = 4
    private let horizontalPadding: CGFloat = 8
    private let bottomPadding: CGFloat = 8
    
    private var adaptiveImageHeight: CGFloat {
        return horizontalSizeClass == .regular ? 140 : 120
    }
    
    private var thumbnailSize: CGSize {
        return CGSize(width: adaptiveImageHeight * 2, height: adaptiveImageHeight)
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        let category = drawing.category?.rawValue ?? "Unknown category"
        let date = drawing.createdDate.formatted(date: .abbreviated, time: .omitted)
        return "\(drawing.title), \(category) drawing, created \(date)"
    }
    
    private var accessibilityHint: String {
        return "Double tap to view drawing details"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: contentSpacing) {
                // OPTIMIZED: Use cached image loading instead of creating UIImage every time
                OptimizedImageView(
                    imageData: drawing.imageData,
                    contentMode: .fill,
                    frameHeight: adaptiveImageHeight
                )
                .frame(height: adaptiveImageHeight)
                .cornerRadius(imageCornerRadius)
                .clipped()
                .accessibilityHidden(true) // Hide from VoiceOver since we have the button label
                
                // Drawing info with consistent spacing
                VStack(alignment: .leading, spacing: infoSpacing) {
                    Text(drawing.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isStaticText)
                    
                    HStack {
                        // Category with consistent styling
                        HStack(spacing: 4) {
                            Circle()
                                .fill(drawing.category?.color ?? .gray)
                                .frame(width: 6, height: 6)
                                .accessibilityHidden(true)
                            
                            Text(drawing.category?.rawValue ?? "Unknown")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .accessibilityAddTraits(.isStaticText)
                        }
                        
                        Spacer()
                        
                        // Date with consistent styling
                        Text(drawing.createdDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, bottomPadding)
            }
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
}

struct EmptyGalleryView: View {
    let selectedCategory: LessonCategory?
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if let category = selectedCategory {
            return "No drawings found in \(category.rawValue) category. Start drawing to create your first artwork."
        } else {
            return "No drawings yet. Start drawing to see your creations here."
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true) // Decorative image
            
            VStack(spacing: 8) {
                Text("No drawings yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                if let category = selectedCategory {
                    Text("No drawings found in \(category.rawValue) category")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isStaticText)
                } else {
                    Text("Start drawing to see your creations here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isStaticText)
                }
            }
            
            NavigationLink(destination: LessonsView()) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .accessibilityHidden(true) // Icon is decorative
                    Text("Start Drawing")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Start Drawing")
            .accessibilityHint("Navigate to lessons to begin creating your first drawing")
            .accessibilityAddTraits(.isButton)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct DrawingDetailView: View {
    let drawing: UserDrawing
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Accessibility Properties
    private var imageAccessibilityLabel: String {
        let category = drawing.category?.rawValue ?? "Unknown category"
        return "\(drawing.title) drawing, \(category) category"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // OPTIMIZED: Drawing image with caching and accessibility
                    OptimizedImageView(
                        imageData: drawing.imageData,
                        contentMode: .fit,
                        frameHeight: 400
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .accessibilityLabel(imageAccessibilityLabel)
                    .accessibilityAddTraits(.isImage)
                    
                    // Drawing info with proper accessibility structure
                    VStack(alignment: .leading, spacing: 16) {
                        Text(drawing.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        
                        HStack {
                            Label(drawing.category?.rawValue ?? "Unknown", systemImage: "tag")
                                .accessibilityLabel("Category: \(drawing.category?.rawValue ?? "Unknown")")
                            Spacer()
                            Label(drawing.createdDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                                .accessibilityLabel("Created: \(drawing.createdDate.formatted(date: .abbreviated, time: .shortened))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        if let authorId = drawing.authorId {
                            Label("Created by: \(authorId)", systemImage: "person")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Created by: \(authorId)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
            .navigationTitle("Drawing Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close drawing details")
                }
            }
        }
    }
}

enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case category = "Category"
}


struct GalleryFilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        return isSelected ? "\(title) filter selected" : "\(title) filter"
    }
    
    private var accessibilityHint: String {
        return isSelected ? "Double tap to deselect filter" : "Double tap to select filter"
    }
    
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
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    NavigationView {
        GalleryView()
            .environmentObject(UserProfileService(persistenceService: PersistenceService()))
    }
}