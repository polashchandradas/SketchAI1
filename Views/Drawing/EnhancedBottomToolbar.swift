import SwiftUI
import PencilKit
import UIKit

// MARK: - Enhanced Bottom Toolbar with New Features
struct EnhancedBottomToolbar: View {
    @Binding var selectedTool: DrawingTool
    @Binding var showGuides: Bool
    @Binding var guideOpacity: Double
    @Binding var showToolPicker: Bool
    @Binding var showRealTimeFeedback: Bool
    
    let canvasView: PKCanvasView
    let isAnalyzing: Bool
    
    // Video Recording Properties
    let isRecording: Bool
    let recordingProgress: Double
    let recordingDuration: TimeInterval
    
    // Actions
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onClear: () -> Void
    let onImportPhoto: () -> Void
    let onAnalyze: () -> Void
    let onToggleFeedback: () -> Void
    
    // Video Recording Actions
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onPauseRecording: () -> Void
    
    @State private var showColorPicker = false
    @State private var selectedColor: Color = .black
    @State private var strokeWidth: Double = 2.0
    
    var body: some View {
        VStack(spacing: 12) {
            // Top controls row
            HStack {
                // Guide controls
                Button {
                    showGuides.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showGuides ? "eye.fill" : "eye.slash.fill")
                        Text("Guides")
                    }
                    .font(.caption)
                    .foregroundColor(showGuides ? .blue : .secondary)
                }
                
                if showGuides {
                    Slider(value: $guideOpacity, in: 0.1...1.0)
                        .frame(width: 60)
                        .accentColor(.blue)
                }
                
                Spacer()
                
                // Real-time feedback toggle
                Button {
                    onToggleFeedback()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showRealTimeFeedback ? "waveform.path.ecg" : "waveform.path.ecg.rectangle")
                        Text("AI Feedback")
                    }
                    .font(.caption)
                    .foregroundColor(showRealTimeFeedback ? .green : .secondary)
                }
            }
            .padding(.horizontal)
            
            // Main toolbar
            HStack(spacing: 16) {
                // Drawing tools section
                HStack(spacing: 12) {
                    ForEach(DrawingTool.allCases, id: \.self) { tool in
                        EnhancedToolButton(
                            tool: tool,
                            isSelected: selectedTool == tool
                        ) {
                            selectedTool = tool
                            updateCanvasTool(tool)
                        }
                    }
                }
                
                // Color picker button
                Button {
                    showColorPicker.toggle()
                } label: {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: 1)
                        )
                }
                .sheet(isPresented: $showColorPicker) {
                    ColorPickerView(selectedColor: $selectedColor) { color in
                        updateCanvasColor(color)
                    }
                }
                
                Spacer()
                
                // Action buttons section
                HStack(spacing: 12) {
                    // Video Recording Controls
                    VideoRecordingControls(
                        isRecording: isRecording,
                        recordingProgress: recordingProgress,
                        recordingDuration: recordingDuration,
                        onStartRecording: onStartRecording,
                        onStopRecording: onStopRecording,
                        onPauseRecording: onPauseRecording
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Photo import
                    ActionButton(
                        icon: "photo.badge.plus",
                        action: onImportPhoto,
                        color: .blue,
                        tooltip: "Import Photo"
                    )
                    
                    // AI Analysis
                    ActionButton(
                        icon: isAnalyzing ? "brain" : "brain.head.profile",
                        action: onAnalyze,
                        color: isAnalyzing ? .orange : .purple,
                        tooltip: "Analyze Drawing",
                        isLoading: isAnalyzing
                    )
                    
                    // Tool picker toggle
                    ActionButton(
                        icon: "pencil.and.outline",
                        action: { showToolPicker.toggle() },
                        color: showToolPicker ? .blue : .secondary,
                        tooltip: "Toggle Tool Picker"
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    // Standard actions
                    ActionButton(
                        icon: "arrow.uturn.backward",
                        action: onUndo,
                        tooltip: "Undo"
                    )
                    
                    ActionButton(
                        icon: "arrow.uturn.forward",
                        action: onRedo,
                        tooltip: "Redo"
                    )
                    
                    ActionButton(
                        icon: "trash",
                        action: onClear,
                        color: .red,
                        tooltip: "Clear Canvas"
                    )
                }
            }
            .padding(.horizontal)
            
            // Stroke width slider (when drawing tool is selected)
            if selectedTool != .eraser {
                HStack {
                    Image(systemName: "pencil.line")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: $strokeWidth, in: 1.0...20.0, step: 1.0)
                        .frame(width: 120)
                        .accentColor(.blue)
                        .onChange(of: strokeWidth) { width in
                            updateStrokeWidth(width)
                        }
                    
                    Text("\(Int(strokeWidth))px")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
        .onAppear {
            // Initialize with current tool settings
            updateCanvasTool(selectedTool)
        }
    }
    
    // MARK: - Tool Management
    
    private func updateCanvasTool(_ tool: DrawingTool) {
        let color = UIColor(selectedColor)
        let width = CGFloat(strokeWidth)
        
        switch tool {
        case .pencil:
            canvasView.tool = PKInkingTool(.pen, color: color, width: width)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        case .brush:
            canvasView.tool = PKInkingTool(.marker, color: color, width: width * 1.5)
        }
    }
    
    private func updateCanvasColor(_ color: Color) {
        selectedColor = color
        updateCanvasTool(selectedTool)
    }
    
    private func updateStrokeWidth(_ width: Double) {
        updateCanvasTool(selectedTool)
    }
}

// MARK: - Enhanced Tool Button
struct EnhancedToolButton: View {
    let tool: DrawingTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.iconName)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(tool.name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 50, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Action Button
struct ActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .primary
    var tooltip: String = ""
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: color))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                }
            }
            .foregroundColor(color)
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
            )
        }
        .disabled(isLoading)
        .help(tooltip)
    }
}

// MARK: - Color Picker View
struct ColorPickerView: View {
    @Binding var selectedColor: Color
    let onColorSelected: (Color) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let predefinedColors: [Color] = [
        .black, .white, .gray, .red, .orange, .yellow,
        .green, .blue, .purple, .pink, .brown, .cyan
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // System color picker
                ColorPicker("Custom Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.5)
                    .padding()
                
                Divider()
                
                // Predefined colors
                Text("Quick Colors")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(predefinedColors, id: \.self) { color in
                        Button {
                            selectedColor = color
                            onColorSelected(color)
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.blue : Color(.systemGray4), lineWidth: selectedColor == color ? 3 : 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onColorSelected(selectedColor)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

//MARK: - Video Recording Controls Component
struct VideoRecordingControls: View {
    let isRecording: Bool
    let recordingProgress: Double
    let recordingDuration: TimeInterval
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onPauseRecording: () -> Void
    
    @State private var isPaused = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Main recording button
            Button(action: {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 36, height: 36)
                    
                    // Recording indicator or play icon
                    if isRecording {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "record.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    // Progress ring
                    if isRecording {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                        
                        Circle()
                            .trim(from: 0, to: recordingProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: recordingProgress)
                    }
                }
            }
            .disabled(false)
            
            // Recording duration display
            if isRecording {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                            .opacity(isRecording ? 1 : 0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isRecording)
                        
                        Text("REC")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    Text(formatDuration(recordingDuration))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    EnhancedBottomToolbar(
        selectedTool: .constant(.pencil),
        showGuides: .constant(true),
        guideOpacity: .constant(0.7),
        showToolPicker: .constant(true),
        showRealTimeFeedback: .constant(true),
        canvasView: PKCanvasView(),
        isAnalyzing: false,
        isRecording: false,
        recordingProgress: 0.0,
        recordingDuration: 0.0,
        onUndo: {},
        onRedo: {},
        onClear: {},
        onImportPhoto: {},
        onAnalyze: {},
        onToggleFeedback: {},
        onStartRecording: {},
        onStopRecording: {},
        onPauseRecording: {}
    )
    .padding()
}
