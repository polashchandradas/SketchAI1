import Foundation
import SwiftUI

/// Manages user consent for data collection and processing
class ConsentManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var consentStatus: ConsentStatus = .notRequested
    @Published var dataSharingEnabled: Bool = false
    @Published var analyticsEnabled: Bool = false
    
    // MARK: - Private Properties
    private let persistenceService: PersistenceService
    private let privacyPolicyURL = "https://yourapp.com/privacy"
    private let termsOfServiceURL = "https://yourapp.com/terms"
    
    init(persistenceService: PersistenceService) {
        self.persistenceService = persistenceService
        loadConsentStatus()
    }
    
    // MARK: - Consent Request
    
    /// Request comprehensive consent for data collection
    func requestConsent(
        purpose: String,
        dataTypes: [String],
        retentionPeriod: TimeInterval,
        anonymization: Bool
    ) async throws -> ConsentRecord {
        
        let consentRequest = ConsentRequest(
            purpose: purpose,
            dataTypes: dataTypes,
            retentionPeriod: retentionPeriod,
            anonymization: anonymization,
            timestamp: Date()
        )
        
        // Show consent UI and wait for user response
        let userResponse = await showConsentUI(consentRequest)
        
        let consentRecord = ConsentRecord(
            id: UUID(),
            granted: userResponse.granted,
            dataSharingEnabled: userResponse.dataSharingEnabled,
            analyticsEnabled: userResponse.analyticsEnabled,
            purpose: purpose,
            dataTypes: dataTypes,
            retentionPeriod: retentionPeriod,
            anonymization: anonymization,
            timestamp: Date(),
            version: "1.0"
        )
        
        // Save consent record
        try await persistenceService.saveConsentRecord(consentRecord)
        
        // Update local state
        await MainActor.run {
            self.consentStatus = userResponse.granted ? .granted : .denied
            self.dataSharingEnabled = userResponse.dataSharingEnabled
            self.analyticsEnabled = userResponse.analyticsEnabled
        }
        
        return consentRecord
    }
    
    /// Update consent status
    func updateConsentStatus(granted: Bool) async throws {
        let updatedRecord = ConsentRecord(
            id: UUID(),
            granted: granted,
            dataSharingEnabled: granted ? dataSharingEnabled : false,
            analyticsEnabled: granted ? analyticsEnabled : false,
            purpose: "AI Model Training",
            dataTypes: ["stroke patterns", "drawing techniques"],
            retentionPeriod: 365 * 24 * 60 * 60,
            anonymization: true,
            timestamp: Date(),
            version: "1.0"
        )
        
        try await persistenceService.saveConsentRecord(updatedRecord)
        
        await MainActor.run {
            self.consentStatus = granted ? .granted : .denied
        }
    }
    
    // MARK: - Consent UI
    
    private func showConsentUI(_ request: ConsentRequest) async -> ConsentResponse {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let consentView = ConsentView(
                    request: request,
                    onResponse: { response in
                        continuation.resume(returning: response)
                    }
                )
                
                // Present consent view
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let hostingController = UIHostingController(rootView: consentView)
                    hostingController.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(hostingController, animated: true)
                }
            }
        }
    }
    
    // MARK: - Consent Status Management
    
    private func loadConsentStatus() {
        // Load from UserDefaults
        let granted = UserDefaults.standard.bool(forKey: "consent_granted")
        let dataSharing = UserDefaults.standard.bool(forKey: "data_sharing_enabled")
        let analytics = UserDefaults.standard.bool(forKey: "analytics_enabled")
        
        consentStatus = granted ? .granted : .denied
        dataSharingEnabled = dataSharing
        analyticsEnabled = analytics
    }
    
    /// Check if consent is valid and not expired
    func isConsentValid() -> Bool {
        guard consentStatus == .granted else { return false }
        
        // Check if consent is not expired (e.g., 1 year validity)
        if let lastConsentDate = UserDefaults.standard.object(forKey: "last_consent_date") as? Date {
            let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 60 * 60)
            return lastConsentDate > oneYearAgo
        }
        
        return false
    }
    
    /// Get consent summary for display
    func getConsentSummary() -> ConsentSummary {
        return ConsentSummary(
            status: consentStatus,
            dataSharingEnabled: dataSharingEnabled,
            analyticsEnabled: analyticsEnabled,
            lastUpdated: UserDefaults.standard.object(forKey: "last_consent_date") as? Date ?? Date()
        )
    }
}

// MARK: - Consent UI Components

struct ConsentView: View {
    let request: ConsentRequest
    let onResponse: (ConsentResponse) -> Void
    
    @State private var dataSharingEnabled = false
    @State private var analyticsEnabled = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Help Improve SketchAI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your anonymous drawing data helps us create better AI guidance for everyone")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Purpose
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What we collect:")
                            .font(.headline)
                        
                        ForEach(request.dataTypes, id: \.self) { dataType in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(dataType)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Privacy Protection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your privacy is protected:")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.blue)
                                Text("All data is anonymized")
                            }
                            
                            HStack {
                                Image(systemName: "eye.slash.fill")
                                    .foregroundColor(.blue)
                                Text("No personal information collected")
                            }
                            
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.blue)
                                Text("Data deleted after \(Int(request.retentionPeriod / (24 * 60 * 60))) days")
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .cornerRadius(12)
                    
                    // Consent Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose what to share:")
                            .font(.headline)
                        
                        Toggle("Help improve AI models", isOn: $dataSharingEnabled)
                            .toggleStyle(SwitchToggleStyle())
                        
                        Toggle("Share anonymous usage analytics", isOn: $analyticsEnabled)
                            .toggleStyle(SwitchToggleStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Legal Links
                    HStack {
                        Button("Privacy Policy") {
                            showingPrivacyPolicy = true
                        }
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button("Terms of Service") {
                            showingTermsOfService = true
                        }
                        .foregroundColor(.blue)
                    }
                    .font(.caption)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Data Collection Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Decline") {
                        onResponse(ConsentResponse(
                            granted: false,
                            dataSharingEnabled: false,
                            analyticsEnabled: false
                        ))
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Accept") {
                        onResponse(ConsentResponse(
                            granted: true,
                            dataSharingEnabled: dataSharingEnabled,
                            analyticsEnabled: analyticsEnabled
                        ))
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            WebView(url: URL(string: "https://yourapp.com/privacy")!)
        }
        .sheet(isPresented: $showingTermsOfService) {
            WebView(url: URL(string: "https://yourapp.com/terms")!)
        }
    }
}

// MARK: - Supporting Types

enum ConsentStatus {
    case notRequested
    case granted
    case denied
    case expired
}

struct ConsentRequest {
    let purpose: String
    let dataTypes: [String]
    let retentionPeriod: TimeInterval
    let anonymization: Bool
    let timestamp: Date
}

struct ConsentResponse {
    let granted: Bool
    let dataSharingEnabled: Bool
    let analyticsEnabled: Bool
}

struct ConsentRecord: Codable {
    let id: UUID
    let granted: Bool
    let dataSharingEnabled: Bool
    let analyticsEnabled: Bool
    let purpose: String
    let dataTypes: [String]
    let retentionPeriod: TimeInterval
    let anonymization: Bool
    let timestamp: Date
    let version: String
}

struct ConsentSummary {
    let status: ConsentStatus
    let dataSharingEnabled: Bool
    let analyticsEnabled: Bool
    let lastUpdated: Date
}

// MARK: - WebView for Privacy Policy

struct WebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIViewController {
        let webView = WKWebView()
        let viewController = UIViewController()
        viewController.view = webView
        webView.load(URLRequest(url: url))
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
