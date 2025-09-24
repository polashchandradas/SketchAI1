import SwiftUI

// MARK: - Report Content View
// User interface for reporting inappropriate user-generated content

struct ReportContentView: View {
    let contentId: String
    let contentType: UGCContentType
    
    @StateObject private var safetyManager = UGCSafetyManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails = ""
    @State private var isSubmitting = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                reportReasonSection
                additionalDetailsSection
                submissionSection
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                }
            }
        }
        .alert("Report Submitted", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Thank you for your report. We'll review it within 24 hours and take appropriate action.")
        }
        .alert("Submission Failed", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Report Reason Section
    private var reportReasonSection: some View {
        Section {
            ForEach(ReportReason.allCases, id: \.self) { reason in
                ReportReasonRow(
                    reason: reason,
                    isSelected: selectedReason == reason
                ) {
                    selectedReason = reason
                }
            }
        } header: {
            Text("Reason for Report")
        } footer: {
            Text("Please select the most appropriate reason for reporting this \(contentType.displayName.lowercased()).")
        }
    }
    
    // MARK: - Additional Details Section
    private var additionalDetailsSection: some View {
        Section {
            TextEditor(text: $additionalDetails)
                .frame(minHeight: 80)
                .placeholder(when: additionalDetails.isEmpty) {
                    Text("Describe what you found inappropriate...")
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
        } header: {
            Text("Additional Details (Optional)")
        } footer: {
            Text("Provide any additional context that might help us understand the issue.")
        }
    }
    
    // MARK: - Submission Section
    private var submissionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Report will be reviewed within 24 hours", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("Action will be taken if content violates policies", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("False reports may result in restrictions", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if isSubmitting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Submitting report...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
        } footer: {
            Text("By submitting this report, you confirm that you believe this content violates our community guidelines.")
        }
    }
    
    // MARK: - Actions
    private func submitReport() {
        guard let reason = selectedReason else { return }
        
        isSubmitting = true
        
        safetyManager.reportContent(
            contentId: contentId,
            contentType: contentType,
            reason: reason,
            additionalDetails: additionalDetails.isEmpty ? nil : additionalDetails
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success:
                    showingSuccessAlert = true
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Report Reason Row
struct ReportReasonRow: View {
    let reason: ReportReason
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(reason.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview
#Preview {
    ReportContentView(
        contentId: "sample-drawing-123",
        contentType: .drawing
    )
}

// MARK: - Sheet Presentation Helper
extension View {
    func reportContentSheet(
        contentId: String,
        contentType: UGCContentType,
        isPresented: Binding<Bool>
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            ReportContentView(
                contentId: contentId,
                contentType: contentType
            )
        }
    }
}
