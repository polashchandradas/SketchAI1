import SwiftUI
import UIKit

// MARK: - Enhanced Button Components with Micro-interactions
// Implementing Chris's philosophy of making every interaction feel premium

// MARK: - Primary Action Button
struct EnhancedPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isLoading: Bool
    let isEnabled: Bool
    
    @State private var isPressed = false
    @State private var animationScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled && !isLoading else { return }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Success animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animationScale = 1.1
                glowOpacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animationScale = 1.0
                    glowOpacity = 0.0
                }
            }
            
            action()
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? [.blue, .blue.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(glowOpacity), radius: 20, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.96 : animationScale)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animationScale)
        .animation(.easeInOut(duration: 0.3), value: glowOpacity)
        .disabled(!isEnabled || isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Secondary Action Button
struct EnhancedSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let isEnabled: Bool
    
    @State private var isPressed = false
    @State private var borderOpacity: Double = 0.3
    
    init(
        _ title: String,
        icon: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            // Light haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Border animation
            withAnimation(.easeInOut(duration: 0.2)) {
                borderOpacity = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    borderOpacity = 0.3
                }
            }
            
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue.opacity(borderOpacity), lineWidth: 2)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: borderOpacity)
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Icon Button with Ripple Effect
struct EnhancedIconButton: View {
    let icon: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 0
    
    init(
        icon: String,
        size: CGFloat = 24,
        color: Color = .blue,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Ripple animation
            withAnimation(.easeOut(duration: 0.6)) {
                rippleScale = 2.0
                rippleOpacity = 0.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    rippleOpacity = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                rippleScale = 0
            }
            
            action()
        }) {
            ZStack {
                // Ripple effect background
                Circle()
                    .fill(color.opacity(rippleOpacity))
                    .scaleEffect(rippleScale)
                
                // Button background
                if let backgroundColor = backgroundColor {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: size + 16, height: size + 16)
                }
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: size, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Floating Action Button
struct EnhancedFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let isExpanded: Bool
    
    @State private var isPressed = false
    @State private var shadowRadius: CGFloat = 8
    @State private var shadowOpacity: Double = 0.3
    
    init(
        icon: String,
        isExpanded: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.isExpanded = isExpanded
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Strong haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            // Shadow animation
            withAnimation(.easeInOut(duration: 0.2)) {
                shadowRadius = 20
                shadowOpacity = 0.6
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    shadowRadius = 8
                    shadowOpacity = 0.3
                }
            }
            
            action()
        }) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: .blue.opacity(shadowOpacity),
                            radius: shadowRadius,
                            x: 0,
                            y: 4
                        )
                )
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Toggle Button with Morphing Animation
struct EnhancedToggleButton: View {
    @Binding var isOn: Bool
    let onIcon: String
    let offIcon: String
    let onColor: Color
    let offColor: Color
    
    @State private var morphScale: CGFloat = 1.0
    
    init(
        isOn: Binding<Bool>,
        onIcon: String = "checkmark.circle.fill",
        offIcon: String = "circle",
        onColor: Color = .green,
        offColor: Color = .gray
    ) {
        self._isOn = isOn
        self.onIcon = onIcon
        self.offIcon = offIcon
        self.onColor = onColor
        self.offColor = offColor
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Morph animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                morphScale = 1.3
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                isOn.toggle()
                morphScale = 1.0
            }
        }) {
            Image(systemName: isOn ? onIcon : offIcon)
                .font(.title2)
                .foregroundColor(isOn ? onColor : offColor)
                .scaleEffect(morphScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isOn)
        }
    }
}

// MARK: - Card Button with Depth Animation
struct EnhancedCardButton<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content
    
    @State private var isPressed = false
    @State private var shadowRadius: CGFloat = 4
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        Button(action: {
            // Light haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: shadowRadius,
                            x: 0,
                            y: yOffset + 2
                        )
                )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .offset(y: yOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                shadowRadius = pressing ? 2 : 4
                yOffset = pressing ? 1 : 0
            }
        }, perform: {})
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            Group {
                EnhancedPrimaryButton("Start Drawing", icon: "pencil") {
                    print("Primary button tapped")
                }
                
                EnhancedSecondaryButton("View Gallery", icon: "photo") {
                    print("Secondary button tapped")
                }
                
                HStack(spacing: 16) {
                    EnhancedIconButton(icon: "heart") {
                        print("Heart tapped")
                    }
                    
                    EnhancedIconButton(icon: "share", backgroundColor: .blue.opacity(0.1)) {
                        print("Share tapped")
                    }
                    
                    EnhancedIconButton(icon: "bookmark", color: .orange) {
                        print("Bookmark tapped")
                    }
                }
                
                EnhancedFloatingActionButton(icon: "plus") {
                    print("FAB tapped")
                }
            }
            
            EnhancedCardButton {
                print("Card tapped")
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "paintbrush.pointed.fill")
                            .foregroundColor(.blue)
                        Text("Drawing Lesson")
                            .font(.headline)
                        Spacer()
                        Text("Pro")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text("Learn to draw realistic portraits with AI guidance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
    }
}

