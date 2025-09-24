import Foundation

/// Configuration for UGC Safety Webhook
/// Manages webhook URLs and API keys for different environments
struct UGCWebhookConfiguration {
    
    // MARK: - Environment Detection
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
    }
    
    // MARK: - Configuration Properties
    struct WebhookConfig {
        let webhookURL: String
        let apiKey: String
        let timeout: TimeInterval
        let maxRetries: Int
    }
    
    // MARK: - Environment Configurations
    static var current: WebhookConfig {
        switch Environment.current {
        case .development:
            return WebhookConfig(
                webhookURL: "http://localhost:3000/api/reports",
                apiKey: "sketchai_dev_key_2024",
                timeout: 30.0,
                maxRetries: 3
            )
            
        case .staging:
            return WebhookConfig(
                webhookURL: "https://sketchai-ugc-staging.herokuapp.com/api/reports",
                apiKey: "sketchai_staging_key_2024",
                timeout: 30.0,
                maxRetries: 3
            )
            
        case .production:
            return WebhookConfig(
                webhookURL: "https://sketchai-ugc-webhook.herokuapp.com/api/reports",
                apiKey: "sketchai_webhook_key_2024_production",
                timeout: 30.0,
                maxRetries: 3
            )
        }
    }
    
    // MARK: - Fallback Configuration
    static let fallbackEmail = "support@sketchai.app"
    static let moderationEmail = "moderation@sketchai.app"
    
    // MARK: - Validation
    static func validateConfiguration() -> Bool {
        let config = current
        
        // Validate URL format
        guard let url = URL(string: config.webhookURL) else {
            print("⚠️ Invalid webhook URL: \(config.webhookURL)")
            return false
        }
        
        // Ensure HTTPS in production
        if Environment.current == .production && url.scheme != "https" {
            print("⚠️ Production webhook must use HTTPS")
            return false
        }
        
        // Validate API key length
        if config.apiKey.count < 16 {
            print("⚠️ API key too short (minimum 16 characters)")
            return false
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    static func getEnvironmentString() -> String {
        switch Environment.current {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
    
    static func printConfiguration() {
        let config = current
        print("""
        🔧 UGC Webhook Configuration
        ============================
        Environment: \(getEnvironmentString())
        Webhook URL: \(config.webhookURL)
        API Key: \(String(repeating: "*", count: config.apiKey.count - 4))\(String(config.apiKey.suffix(4)))
        Timeout: \(config.timeout)s
        Max Retries: \(config.maxRetries)
        Valid: \(validateConfiguration() ? "✅" : "❌")
        """)
    }
}

/// Extension to support custom webhook URLs (for testing)
extension UGCWebhookConfiguration {
    
    /// Create custom configuration for testing
    static func custom(webhookURL: String, apiKey: String) -> WebhookConfig {
        return WebhookConfig(
            webhookURL: webhookURL,
            apiKey: apiKey,
            timeout: 30.0,
            maxRetries: 3
        )
    }
    
    /// Test webhook connectivity
    static func testWebhookConnectivity(completion: @escaping (Bool, String) -> Void) {
        let config = current
        
        guard let url = URL(string: config.webhookURL.replacingOccurrences(of: "/api/reports", with: "/api/health")) else {
            completion(false, "Invalid webhook URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Connection failed: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(false, "Invalid response format")
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    completion(true, "Webhook is healthy")
                } else {
                    completion(false, "Webhook returned status code: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}
