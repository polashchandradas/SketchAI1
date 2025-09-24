import Foundation

// MARK: - Paywall Context
// Shared enum used across the app to drive context-aware paywall messaging
enum PaywallContext: Equatable {
    case general
    case lessonGate
    case exportGate
    case imageImportGate
    case profile
    case sharingMenu
    case drawingCanvas
    case exportMenu
}


