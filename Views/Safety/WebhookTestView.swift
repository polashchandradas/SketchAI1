import SwiftUI

/// Development view for testing UGC webhook functionality
/// Only available in DEBUG builds
struct WebhookTestView: View {
    @StateObject private var ugcSafetyManager = UGCSafetyManager()
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Configuration Info
                    configurationSection
                    
                    // MARK: - Quick Tests
                    quickTestsSection
                    
                    // MARK: - Test Results
                    if !testResults.isEmpty {
                        testResultsSection
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("UGC Webhook Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run All Tests") {
                        runAllTests()
                    }
                    .disabled(isRunningTests)
                }
            }
        }
    }
    
    // MARK: - Configuration Section
    private var configurationSection: some View {
        GroupBox("Webhook Configuration") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Environment:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(UGCWebhookConfiguration.getEnvironmentString())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Webhook URL:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(UGCWebhookConfiguration.current.webhookURL)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                HStack {
                    Text("API Key:")
                        .fontWeight(.medium)
                    Spacer()
                    Text("***\(String(UGCWebhookConfiguration.current.apiKey.suffix(4)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Valid Config:")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: UGCWebhookConfiguration.validateConfiguration() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(UGCWebhookConfiguration.validateConfiguration() ? .green : .red)
                }
            }
        }
    }
    
    // MARK: - Quick Tests Section
    private var quickTestsSection: some View {
        GroupBox("Quick Tests") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                
                TestButton(
                    title: "Health Check",
                    icon: "heart.fill",
                    color: .green
                ) {
                    testWebhookHealth()
                }
                
                TestButton(
                    title: "Test Report",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                ) {
                    testBasicReport()
                }
                
                TestButton(
                    title: "Urgent Report",
                    icon: "exclamationmark.octagon.fill",
                    color: .red
                ) {
                    testUrgentReport()
                }
                
                TestButton(
                    title: "Rate Limit",
                    icon: "speedometer",
                    color: .blue
                ) {
                    testRateLimit()
                }
            }
        }
    }
    
    // MARK: - Test Results Section
    private var testResultsSection: some View {
        GroupBox("Test Results") {
            LazyVStack(spacing: 8) {
                ForEach(testResults.reversed()) { result in
                    TestResultRow(result: result)
                }
            }
        }
    }
    
    // MARK: - Test Methods
    
    private func runAllTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            await testWebhookHealth()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            await testBasicReport()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await testUrgentReport()
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isRunningTests = false
            }
        }
    }
    
    private func testWebhookHealth() {
        addTestResult(TestResult(
            name: "Health Check",
            status: .running,
            message: "Testing webhook connectivity...",
            timestamp: Date()
        ))
        
        UGCWebhookConfiguration.testWebhookConnectivity { success, message in
            updateLastTestResult(
                status: success ? .success : .failure,
                message: message
            )
        }
    }
    
    private func testBasicReport() {
        addTestResult(TestResult(
            name: "Basic Report",
            status: .running,
            message: "Submitting test report...",
            timestamp: Date()
        ))
        
        ugcSafetyManager.reportContent(
            contentId: "test_content_\(UUID().uuidString.prefix(8))",
            contentType: .drawing,
            reason: .other,
            additionalDetails: "Test report from iOS - Basic functionality test"
        ) { result in
            switch result {
            case .success():
                updateLastTestResult(
                    status: .success,
                    message: "Report submitted successfully"
                )
            case .failure(let error):
                updateLastTestResult(
                    status: .failure,
                    message: "Failed: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func testUrgentReport() {
        addTestResult(TestResult(
            name: "Urgent Report",
            status: .running,
            message: "Submitting urgent test report...",
            timestamp: Date()
        ))
        
        ugcSafetyManager.reportContent(
            contentId: "urgent_test_\(UUID().uuidString.prefix(8))",
            contentType: .drawing,
            reason: .violence,
            additionalDetails: "Test urgent report - should trigger immediate notification"
        ) { result in
            switch result {
            case .success():
                updateLastTestResult(
                    status: .success,
                    message: "Urgent report submitted successfully"
                )
            case .failure(let error):
                updateLastTestResult(
                    status: .failure,
                    message: "Failed: \(error.localizedDescription)"
                )
            }
        }
    }
    
    private func testRateLimit() {
        addTestResult(TestResult(
            name: "Rate Limit Test",
            status: .running,
            message: "Testing rate limiting (sending multiple reports)...",
            timestamp: Date()
        ))
        
        var successCount = 0
        var rateLimitedCount = 0
        let totalTests = 5
        
        for i in 1...totalTests {
            ugcSafetyManager.reportContent(
                contentId: "rate_test_\(i)",
                contentType: .drawing,
                reason: .spam,
                additionalDetails: "Rate limit test report \(i)"
            ) { result in
                switch result {
                case .success():
                    successCount += 1
                case .failure(let error):
                    if case ReportingError.rateLimited = error {
                        rateLimitedCount += 1
                    }
                }
                
                // Update result after all tests complete
                if successCount + rateLimitedCount >= totalTests {
                    updateLastTestResult(
                        status: rateLimitedCount > 0 ? .success : .warning,
                        message: "Success: \(successCount), Rate Limited: \(rateLimitedCount)"
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func addTestResult(_ result: TestResult) {
        testResults.append(result)
    }
    
    private func updateLastTestResult(status: TestStatus, message: String) {
        if let index = testResults.indices.last {
            testResults[index].status = status
            testResults[index].message = message
        }
    }
}

// MARK: - Supporting Views

struct TestButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.status.iconName)
                .foregroundColor(result.status.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .fontWeight(.medium)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(result.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    var status: TestStatus
    var message: String
    let timestamp: Date
}

enum TestStatus {
    case running
    case success
    case warning
    case failure
    
    var iconName: String {
        switch self {
        case .running: return "clock.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failure: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .running: return .blue
        case .success: return .green
        case .warning: return .orange
        case .failure: return .red
        }
    }
}

// MARK: - Preview

#if DEBUG
struct WebhookTestView_Previews: PreviewProvider {
    static var previews: some View {
        WebhookTestView()
    }
}
#endif
