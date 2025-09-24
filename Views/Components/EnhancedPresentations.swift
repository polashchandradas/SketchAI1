import SwiftUI
import UIKit

// MARK: - Enhanced Presentation Components
// Custom sheet and modal presentations with advanced animations

// MARK: - Enhanced Sheet Modifier
struct EnhancedSheet<SheetContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let detents: [UISheetPresentationController.Detent]
    let dragIndicatorVisibility: Visibility
    @ViewBuilder let sheetContent: () -> SheetContent
    
    @State private var backgroundOpacity: Double = 0
    @State private var contentOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                EnhancedSheetContent(
                    isPresented: $isPresented,
                    detents: detents,
                    dragIndicatorVisibility: dragIndicatorVisibility,
                    sheetContent: self.sheetContent
                )
            }
    }
}

// MARK: - Enhanced Sheet Content
struct EnhancedSheetContent<SheetContent: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let detents: [UISheetPresentationController.Detent]
    let dragIndicatorVisibility: Visibility
    @ViewBuilder let sheetContent: () -> SheetContent
    
    func makeUIViewController(context: Context) -> UIViewController {
        let hostingController = UIHostingController(rootView: sheetContent())
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersGrabberVisible = dragIndicatorVisibility == .visible
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            
            // Custom corner radius
            sheet.preferredCornerRadius = 24
            
            // Smooth animations
            sheet.animateChanges {
                // Custom animation block
            }
        }
        
        return hostingController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let hostingController = uiViewController as? UIHostingController<SheetContent> {
            hostingController.rootView = sheetContent()
        }
    }
}

// MARK: - Enhanced Full Screen Cover
struct EnhancedFullScreenCover<CoverContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let transition: EnhancedTransition
    @ViewBuilder let coverContent: () -> CoverContent
    
    @State private var animationProgress: Double = 0
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ZStack {
                    // Background with custom transition
                    Color.black
                        .opacity(animationProgress * 0.3)
                        .ignoresSafeArea()
                    
                    // Content with transition animation
                    self.coverContent()
                        .modifier(TransitionAnimationModifier(
                            transition: transition,
                            progress: animationProgress
                        ))
                }
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        animationProgress = 1.0
                    }
                }
                .onDisappear {
                    animationProgress = 0
                }
            }
    }
}

// MARK: - Enhanced Modal Card
struct EnhancedModalCard<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let subtitle: String?
    let showCloseButton: Bool
    @ViewBuilder let content: Content
    
    @State private var cardOffset: CGFloat = 1000
    @State private var backgroundOpacity: Double = 0
    @State private var cardScale: CGFloat = 0.9
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal card
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        if showCloseButton {
                            HStack {
                                Spacer()
                                Button(action: dismissModal) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Content
                    content
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                }
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -5)
                )
                .padding(.horizontal, 20)
                .offset(y: cardOffset)
                .scaleEffect(cardScale)
            }
        }
        .onAppear {
            presentModal()
        }
    }
    
    private func presentModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardOffset = 0
            backgroundOpacity = 0.4
            cardScale = 1.0
        }
    }
    
    private func dismissModal() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            cardOffset = 1000
            backgroundOpacity = 0
            cardScale = 0.9
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Enhanced Popover
struct EnhancedPopover<Content: View>: View {
    @Binding var isPresented: Bool
    let sourceFrame: CGRect
    let arrowDirection: ArrowDirection
    @ViewBuilder let content: Content
    
    @State private var popoverOffset: CGPoint = .zero
    @State private var popoverOpacity: Double = 0
    @State private var popoverScale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissPopover()
                    }
                
                // Popover content
                VStack(spacing: 0) {
                    if arrowDirection == .up {
                        popoverArrow()
                    }
                    
                    content
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                    
                    if arrowDirection == .down {
                        popoverArrow()
                            .rotationEffect(.degrees(180))
                    }
                }
                .position(calculatePopoverPosition())
                .offset(x: popoverOffset.x, y: popoverOffset.y)
                .scaleEffect(popoverScale)
                .opacity(popoverOpacity)
            }
        }
        .onChange(of: isPresented) { presented in
            if presented {
                presentPopover()
            }
        }
    }
    
    private func popoverArrow() -> some View {
        Triangle()
            .fill(.ultraThinMaterial)
            .frame(width: 16, height: 8)
    }
    
    private func calculatePopoverPosition() -> CGPoint {
        // Calculate position based on source frame and arrow direction
        switch arrowDirection {
        case .up:
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.maxY + 50)
        case .down:
            return CGPoint(x: sourceFrame.midX, y: sourceFrame.minY - 50)
        }
    }
    
    private func presentPopover() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            popoverOpacity = 1.0
            popoverScale = 1.0
        }
    }
    
    private func dismissPopover() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            popoverOpacity = 0
            popoverScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Enhanced Alert
struct EnhancedAlert: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let primaryButton: AlertButton?
    let secondaryButton: AlertButton?
    
    @State private var alertScale: CGFloat = 0.8
    @State private var alertOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            // Alert content
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Buttons
                VStack(spacing: 12) {
                    if let primaryButton = primaryButton {
                        EnhancedPrimaryButton(primaryButton.title) {
                            primaryButton.action()
                            dismissAlert()
                        }
                    }
                    
                    if let secondaryButton = secondaryButton {
                        EnhancedSecondaryButton(secondaryButton.title) {
                            secondaryButton.action()
                            dismissAlert()
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 40)
            .scaleEffect(alertScale)
            .opacity(alertOpacity)
        }
        .onAppear {
            presentAlert()
        }
    }
    
    private func presentAlert() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            alertScale = 1.0
            alertOpacity = 1.0
            backgroundOpacity = 0.4
        }
    }
    
    private func dismissAlert() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            alertScale = 0.8
            alertOpacity = 0
            backgroundOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Supporting Types and Enums
enum EnhancedTransition {
    case slide
    case fade
    case scale
    case flip
    case push
}

enum ArrowDirection {
    case up
    case down
}

struct AlertButton {
    let title: String
    let action: () -> Void
}

// MARK: - Transition Animation Modifier
struct TransitionAnimationModifier: ViewModifier {
    let transition: EnhancedTransition
    let progress: Double
    
    func body(content: Content) -> some View {
        switch transition {
        case .slide:
            content
                .offset(y: (1 - progress) * 1000)
        case .fade:
            content
                .opacity(progress)
        case .scale:
            content
                .scaleEffect(0.8 + (progress * 0.2))
                .opacity(progress)
        case .flip:
            content
                .rotation3DEffect(
                    .degrees((1 - progress) * 90),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.5
                )
        case .push:
            content
                .offset(x: (1 - progress) * 1000)
        }
    }
}

// MARK: - Triangle Shape for Popover Arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Extensions
extension View {
    func enhancedSheet<Content: View>(
        isPresented: Binding<Bool>,
        detents: [UISheetPresentationController.Detent] = [.medium(), .large()],
        dragIndicatorVisibility: Visibility = .automatic,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(EnhancedSheet(
            isPresented: isPresented,
            detents: detents,
            dragIndicatorVisibility: dragIndicatorVisibility,
            sheetContent: content
        ))
    }
    
    func enhancedFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        transition: EnhancedTransition = .slide,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(EnhancedFullScreenCover(
            isPresented: isPresented,
            transition: transition,
            coverContent: content
        ))
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var showSheet = false
        @State private var showModal = false
        @State private var showAlert = false
        @State private var showPopover = false
        
        var body: some View {
            VStack(spacing: 20) {
                EnhancedPrimaryButton("Show Enhanced Sheet") {
                    showSheet = true
                }
                
                EnhancedSecondaryButton("Show Modal Card") {
                    showModal = true
                }
                
                EnhancedSecondaryButton("Show Alert") {
                    showAlert = true
                }
                
                EnhancedSecondaryButton("Show Popover") {
                    showPopover = true
                }
            }
            .padding()
            .enhancedSheet(isPresented: $showSheet) {
                VStack(spacing: 20) {
                    Text("Enhanced Sheet")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("This sheet has custom detents and smooth animations")
                        .multilineTextAlignment(.center)
                    
                    EnhancedPrimaryButton("Close") {
                        showSheet = false
                    }
                }
                .padding()
            }
            .overlay {
                if showModal {
                    EnhancedModalCard(
                        isPresented: $showModal,
                        title: "Enhanced Modal",
                        subtitle: "Custom animations and interactions",
                        showCloseButton: true
                    ) {
                        VStack(spacing: 16) {
                            Text("This modal has custom spring animations")
                            
                            EnhancedPrimaryButton("Got it!") {
                                showModal = false
                            }
                        }
                    }
                }
                
                if showAlert {
                    EnhancedAlert(
                        isPresented: $showAlert,
                        title: "Enhanced Alert",
                        message: "This alert has custom animations and styling",
                        primaryButton: AlertButton(title: "Confirm") {
                            print("Confirmed")
                        },
                        secondaryButton: AlertButton(title: "Cancel") {
                            print("Cancelled")
                        }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
