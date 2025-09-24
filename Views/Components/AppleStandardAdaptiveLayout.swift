import SwiftUI

// MARK: - Apple-Standard Adaptive Layout System
// Follows Apple's Human Interface Guidelines 2024 and iOS 18 best practices
// Based on official Apple documentation and WWDC 2024 sessions

// MARK: - Size Class Based Layout (Apple's Recommended Approach)
struct AdaptiveLayoutContainer<Content: View>: View {
    let content: Content
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.layoutMetrics, layoutMetrics)
    }
    
    // Apple-standard layout metrics based on size classes
    private var layoutMetrics: LayoutMetrics {
        LayoutMetrics(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }
}

// MARK: - Layout Metrics (Custom Environment Value)
struct LayoutMetrics {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
    let dynamicTypeSize: DynamicTypeSize
    
    // Apple-standard spacing values
    var contentPadding: EdgeInsets {
        switch horizontalSizeClass {
        case .compact:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .regular:
            return EdgeInsets(top: 24, leading: 32, bottom: 24, trailing: 32)
        default:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        }
    }
    
    var cardSpacing: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 12
        case .regular: return 16
        default: return 12
        }
    }
    
    var sectionSpacing: CGFloat {
        switch horizontalSizeClass {
        case .compact: return 20
        case .regular: return 32
        default: return 20
        }
    }
    
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }
    
    var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }
    
    var isCompactHeight: Bool {
        verticalSizeClass == .compact
    }
    
    var isRegularHeight: Bool {
        verticalSizeClass == .regular
    }
    
    // iPad landscape detection using size classes (Apple's way)
    var isLandscapeOrientation: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    // iPhone/iPad detection using size classes
    var isPadLikeLayout: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
}

// Environment key for layout metrics
private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(
        horizontalSizeClass: .compact,
        verticalSizeClass: .regular,
        dynamicTypeSize: .large
    )
}

extension EnvironmentValues {
    var layoutMetrics: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}

// MARK: - Apple Standard Grid System
struct AppleStandardGrid {
    static func adaptiveColumns(
        metrics: LayoutMetrics,
        minimumItemWidth: CGFloat,
        maximumItemWidth: CGFloat? = nil,
        spacing: CGFloat? = nil
    ) -> [GridItem] {
        let itemSpacing = spacing ?? metrics.cardSpacing
        
        if let maxWidth = maximumItemWidth {
            return [GridItem(.adaptive(minimum: minimumItemWidth, maximum: maxWidth), spacing: itemSpacing)]
        } else {
            return [GridItem(.adaptive(minimum: minimumItemWidth), spacing: itemSpacing)]
        }
    }
    
    // Predefined grid configurations for common layouts
    static func quickActionsGrid(metrics: LayoutMetrics) -> [GridItem] {
        let minWidth: CGFloat = metrics.isCompactWidth ? 140 : 180
        let maxWidth: CGFloat = metrics.isCompactWidth ? 200 : 250
        return adaptiveColumns(metrics: metrics, minimumItemWidth: minWidth, maximumItemWidth: maxWidth)
    }
    
    static func lessonsGrid(metrics: LayoutMetrics) -> [GridItem] {
        let minWidth: CGFloat = metrics.isCompactWidth ? 160 : 200
        return adaptiveColumns(metrics: metrics, minimumItemWidth: minWidth)
    }
    
    static func galleryGrid(metrics: LayoutMetrics) -> [GridItem] {
        let minWidth: CGFloat = metrics.isCompactWidth ? 100 : 150
        let maxWidth: CGFloat = metrics.isCompactWidth ? 150 : 200
        return adaptiveColumns(metrics: metrics, minimumItemWidth: minWidth, maximumItemWidth: maxWidth)
    }
    
    static func analyticsGrid(metrics: LayoutMetrics) -> [GridItem] {
        let minWidth: CGFloat = metrics.isCompactWidth ? 140 : 200
        return adaptiveColumns(metrics: metrics, minimumItemWidth: minWidth)
    }
}

// MARK: - Apple Standard Spacing System
struct AppleSpacing {
    static let extraSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    static let huge: CGFloat = 48
    
    static func adaptive(metrics: LayoutMetrics, compact: CGFloat, regular: CGFloat) -> CGFloat {
        metrics.isCompactWidth ? compact : regular
    }
    
    static func contentPadding(metrics: LayoutMetrics) -> EdgeInsets {
        metrics.contentPadding
    }
}

// MARK: - Apple Standard Typography
struct AdaptiveTypography {
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    // Dynamic sizing based on size class
    static func adaptiveTitle(metrics: LayoutMetrics) -> Font {
        metrics.isCompactWidth ? .title2 : .title
    }
    
    static func adaptiveHeadline(metrics: LayoutMetrics) -> Font {
        metrics.isCompactWidth ? .headline : .title3
    }
}

// MARK: - Apple Standard Corner Radius
struct AdaptiveCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 20
    
    static func adaptive(metrics: LayoutMetrics, compact: CGFloat, regular: CGFloat) -> CGFloat {
        metrics.isCompactWidth ? compact : regular
    }
    
    static func card(metrics: LayoutMetrics) -> CGFloat {
        adaptive(metrics: metrics, compact: 12, regular: 16)
    }
}

// MARK: - Responsive Container (Replaces GeometryReader patterns)
struct ResponsiveContainer<Content: View>: View {
    let maxWidth: CGFloat?
    let content: Content
    
    @Environment(\.layoutMetrics) var layoutMetrics
    
    init(maxWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: effectiveMaxWidth)
    }
    
    private var effectiveMaxWidth: CGFloat? {
        guard let maxWidth = maxWidth else { return nil }
        return layoutMetrics.isRegularWidth ? maxWidth : nil
    }
}

// MARK: - Adaptive Navigation Container (Replaces NavigationView)
struct AdaptiveNavigationContainer<Content: View>: View {
    let content: Content
    
    @Environment(\.layoutMetrics) var layoutMetrics
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        if layoutMetrics.isPadLikeLayout {
            // Use NavigationSplitView for iPad
            NavigationSplitView {
                // Sidebar would go here if needed
                Text("Sidebar")
            } detail: {
                NavigationStack {
                    content
                }
            }
        } else {
            // Use NavigationStack for iPhone
            NavigationStack {
                content
            }
        }
    }
}