import SwiftUI

// MARK: - Enhanced Tab View with Custom Sliding Animations
// Inspired by Chris's Luna app - slides between tabs instead of instant transitions

struct EnhancedTabView: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @Namespace private var tabAnimation
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content Container with Sliding Animation
                ZStack {
                    ForEach(tabs.indices, id: \.self) { index in
                        tabs[index].content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(x: calculateOffset(for: index, screenWidth: geometry.size.width))
                            .opacity(calculateOpacity(for: index))
                            .scaleEffect(calculateScale(for: index))
                    }
                }
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            isDragging = false
                            handleDragEnd(value, screenWidth: geometry.size.width)
                        }
                )
                
                // Custom Tab Bar at Bottom
                EnhancedTabBar(
                    selectedTab: $selectedTab,
                    tabs: tabs,
                    namespace: tabAnimation,
                    onTabTap: { index in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Animation Calculations
    private func calculateOffset(for index: Int, screenWidth: CGFloat) -> CGFloat {
        let baseOffset = CGFloat(index - selectedTab) * screenWidth
        return isDragging ? baseOffset + dragOffset : baseOffset
    }
    
    private func calculateOpacity(for index: Int) -> Double {
        let distance = abs(index - selectedTab)
        if isDragging {
            let dragProgress = abs(dragOffset) / 400 // Fixed width for consistent behavior
            return distance == 0 ? 1.0 - (dragProgress * 0.3) : 
                   distance == 1 ? dragProgress * 0.7 : 0.0
        }
        return distance == 0 ? 1.0 : 0.0
    }
    
    private func calculateScale(for index: Int) -> CGFloat {
        let distance = abs(index - selectedTab)
        if isDragging {
            let dragProgress = abs(dragOffset) / 400 // Fixed width for consistent behavior
            return distance == 0 ? 1.0 - (dragProgress * 0.05) : 
                   distance == 1 ? 0.95 + (dragProgress * 0.05) : 0.95
        }
        return distance == 0 ? 1.0 : 0.95
    }
    
    // MARK: - Drag Handling
    private func handleDragEnd(_ value: DragGesture.Value, screenWidth: CGFloat) {
        let threshold: CGFloat = screenWidth * 0.25
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        var newIndex = selectedTab
        
        if value.translation.width > threshold || velocity > 500 {
            // Swipe right (go to previous tab)
            newIndex = max(0, selectedTab - 1)
        } else if value.translation.width < -threshold || velocity < -500 {
            // Swipe left (go to next tab)
            newIndex = min(tabs.count - 1, selectedTab + 1)
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.3)) {
            selectedTab = newIndex
            dragOffset = 0
        }
    }
}

// MARK: - Enhanced Tab Bar
struct EnhancedTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    let namespace: Namespace.ID
    let onTabTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button(action: {
                    // Haptic feedback for tab selection
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    onTabTap(index)
                }) {
                    VStack(spacing: 4) {
                        // Tab Icon with Animation
                        Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                            .font(.title2)
                            .foregroundColor(selectedTab == index ? .blue : .gray)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                        
                        // Tab Title
                        Text(tabs[index].title)
                            .font(.caption)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundColor(selectedTab == index ? .blue : .gray)
                            .scaleEffect(selectedTab == index ? 1.05 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                        
                        // Active Indicator with Matched Geometry Effect
                        if selectedTab == index {
                            Capsule()
                                .fill(.blue)
                                .frame(width: 30, height: 3)
                                .matchedGeometryEffect(id: "activeTab", in: namespace)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: 30, height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(TabButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background(.ultraThinMaterial)
        .safeAreaInset(edge: .bottom) {
            // Dynamic safe area handling for all devices
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - Tab Button Style with Micro-interactions
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Tab Item Data Structure
struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
    let content: AnyView
    
    init<Content: View>(title: String, icon: String, selectedIcon: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon + ".fill"
        self.content = AnyView(content())
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTab = 0
        
        var body: some View {
            EnhancedTabView(
                selectedTab: $selectedTab,
                tabs: [
                    TabItem(title: "Home", icon: "house", selectedIcon: "house.fill") {
                        Color.blue.opacity(0.3)
                            .overlay(Text("Home Tab").font(.largeTitle))
                    },
                    TabItem(title: "Lessons", icon: "book", selectedIcon: "book.fill") {
                        Color.green.opacity(0.3)
                            .overlay(Text("Lessons Tab").font(.largeTitle))
                    },
                    TabItem(title: "Gallery", icon: "photo", selectedIcon: "photo.fill") {
                        Color.orange.opacity(0.3)
                            .overlay(Text("Gallery Tab").font(.largeTitle))
                    },
                    TabItem(title: "Profile", icon: "person", selectedIcon: "person.fill") {
                        Color.purple.opacity(0.3)
                            .overlay(Text("Profile Tab").font(.largeTitle))
                    }
                ]
            )
        }
    }
    
    return PreviewWrapper()
}
