import SwiftUI
import Charts

// MARK: - Performance Analytics Dashboard
struct PerformanceAnalyticsDashboard: View {
    @StateObject private var analyticsManager = AnalyticsManager()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: AnalyticsMetric = .accuracy
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with time range selector
                    headerSection
                    
                    // Key Performance Indicators
                    kpiSection
                    
                    // Performance Charts
                    chartSection
                    
                    // DTW Performance Metrics
                    dtwMetricsSection
                    
                    // Category Performance Breakdown
                    categoryBreakdownSection
                    
                    // User Progress Insights
                    progressInsightsSection
                }
                .padding()
            }
            .navigationTitle("Performance Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                analyticsManager.loadAnalytics()
            }
            .refreshable {
                await analyticsManager.refreshAnalytics()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(range.displayName) {
                            selectedTimeRange = range
                            analyticsManager.updateTimeRange(range)
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimeRange.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            Text("Track your drawing progress and AI analysis performance")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - KPI Section
    private var kpiSection: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            KPICard(
                title: "Average Accuracy",
                value: String(format: "%.1f%%", analyticsManager.averageAccuracy * 100),
                change: analyticsManager.accuracyChange,
                icon: "target",
                color: .blue
            )
            
            KPICard(
                title: "Lessons Completed",
                value: "\(analyticsManager.completedLessons)",
                change: analyticsManager.completionChange,
                icon: "checkmark.circle",
                color: .green
            )
            
            KPICard(
                title: "DTW Success Rate",
                value: String(format: "%.1f%%", analyticsManager.dtwSuccessRate * 100),
                change: analyticsManager.dtwChange,
                icon: "brain.head.profile",
                color: .purple
            )
            
            KPICard(
                title: "Avg. Analysis Time",
                value: String(format: "%.0fms", analyticsManager.avgAnalysisTime * 1000),
                change: analyticsManager.performanceChange,
                icon: "clock",
                color: .orange
            )
        }
        }
    }
    
    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
                .frame(minWidth: 200)
            }
            
            // Performance Chart
            PerformanceChart(
                data: analyticsManager.getChartData(for: selectedMetric),
                metric: selectedMetric
            )
            .frame(minHeight: 180)
            .frame(maxHeight: 250)
            .aspectRatio(1.6, contentMode: .fit)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - DTW Metrics Section (Enhanced User-Facing)
    private var dtwMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("🎯 AI Drawing Tutor")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Real-time status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(analyticsManager.dtwMetrics.enhancedSuccessRate > 0.8 ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("See how our AI analyzes your drawing technique in real-time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            VStack(spacing: 12) {
                // Enhanced DTW metrics with user-friendly language
                DTWMetricRowEnhanced(
                    title: "AI Analysis Success",
                    value: String(format: "%.1f%%", analyticsManager.dtwMetrics.enhancedSuccessRate * 100),
                    subtitle: "How often our AI can analyze your strokes",
                    icon: "checkmark.seal.fill",
                    color: .purple,
                    showTrend: true,
                    trend: analyticsManager.dtwChange
                )
                
                DTWMetricRowEnhanced(
                    title: "Path Following Accuracy", 
                    value: String(format: "%.0f%%", analyticsManager.dtwMetrics.averageDTWScore * 100),
                    subtitle: "How closely you follow the guide path",
                    icon: "location.fill",
                    color: .blue,
                    showTrend: true,
                    trend: 5.2
                )
                
                DTWMetricRowEnhanced(
                    title: "Drawing Speed Control",
                    value: String(format: "%.1f%%", analyticsManager.dtwMetrics.averageTemporalAccuracy * 100),
                    subtitle: "Consistency of your drawing rhythm",
                    icon: "speedometer",
                    color: .green,
                    showTrend: true,
                    trend: 2.1
                )
                
                DTWMetricRowEnhanced(
                    title: "Hand Steadiness",
                    value: String(format: "%.1f%%", analyticsManager.dtwMetrics.averageVelocityConsistency * 100),
                    subtitle: "Smoothness and control of your strokes", 
                    icon: "hand.draw.fill",
                    color: .orange,
                    showTrend: true,
                    trend: -1.3
                )
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6), Color(.systemGray6).opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Category Breakdown Section
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(analyticsManager.categoryPerformance, id: \.category) { performance in
                    CategoryPerformanceRow(performance: performance)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Progress Insights Section
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(analyticsManager.insights, id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct KPICard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.1f%%", abs(change)))
                        .font(.caption2)
                }
                .foregroundColor(change >= 0 ? .green : .red)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct PerformanceChart: View {
    let data: [ChartDataPoint]
    let metric: AnalyticsMetric
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value(metric.displayName, point.value)
            )
            .foregroundStyle(metric.color)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value(metric.displayName, point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [metric.color.opacity(0.3), metric.color.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}

struct DTWMetricRow: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Enhanced DTW Metric Row with Trends and Icons
struct DTWMetricRowEnhanced: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let showTrend: Bool
    let trend: Double
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Trend indicator
                    if showTrend {
                        HStack(spacing: 2) {
                            Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.caption2)
                                .foregroundColor(trend >= 0 ? .green : .red)
                            
                            Text(String(format: "%.1f%%", abs(trend)))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(trend >= 0 ? .green : .red)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill((trend >= 0 ? Color.green : Color.red).opacity(0.1))
                        )
                    }
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Value with enhanced styling
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text("Real-time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct CategoryPerformanceRow: View {
    let performance: CategoryPerformanceData
    
    var body: some View {
        HStack {
            // Category icon and name
            HStack(spacing: 8) {
                Image(systemName: performance.category.iconName)
                    .foregroundColor(performance.category.color)
                    .frame(width: 20)
                
                Text(performance.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // Progress bar
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(performance.completed)/\(performance.total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: performance.completionRate)
                    .progressViewStyle(LinearProgressViewStyle(tint: performance.category.color))
                    .frame(width: 80)
            }
        }
    }
}

struct InsightCard: View {
    let insight: PerformanceInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: insight.icon)
                .foregroundColor(insight.type.color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(insight.type.backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(insight.type.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Supporting Types

enum TimeRange: CaseIterable {
    case day, week, month, year
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
}

enum AnalyticsMetric: CaseIterable {
    case accuracy, completionTime, dtwScore, analysisTime
    
    var displayName: String {
        switch self {
        case .accuracy: return "Accuracy"
        case .completionTime: return "Completion Time"
        case .dtwScore: return "DTW Score"
        case .analysisTime: return "Analysis Time"
        }
    }
    
    var color: Color {
        switch self {
        case .accuracy: return .blue
        case .completionTime: return .green
        case .dtwScore: return .purple
        case .analysisTime: return .orange
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct CategoryPerformanceData {
    let category: LessonCategory
    let completed: Int
    let total: Int
    
    var completionRate: Double {
        total > 0 ? Double(completed) / Double(total) : 0.0
    }
}

struct PerformanceInsight {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let type: InsightType
}

enum InsightType {
    case success, improvement, warning
    
    var color: Color {
        switch self {
        case .success: return .green
        case .improvement: return .blue
        case .warning: return .orange
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return .green.opacity(0.1)
        case .improvement: return .blue.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .success: return .green.opacity(0.3)
        case .improvement: return .blue.opacity(0.3)
        case .warning: return .orange.opacity(0.3)
        }
    }
}

// MARK: - Analytics Manager
class AnalyticsManager: ObservableObject {
    @Published var averageAccuracy: Double = 0.0
    @Published var completedLessons: Int = 0
    @Published var dtwSuccessRate: Double = 0.0
    @Published var avgAnalysisTime: Double = 0.0
    
    @Published var accuracyChange: Double = 0.0
    @Published var completionChange: Double = 0.0
    @Published var dtwChange: Double = 0.0
    @Published var performanceChange: Double = 0.0
    
    @Published var dtwMetrics = DTWMetrics()
    @Published var categoryPerformance: [CategoryPerformanceData] = []
    @Published var insights: [PerformanceInsight] = []
    
    private var currentTimeRange: TimeRange = .week
    
    func loadAnalytics() {
        // Load Core ML system performance metrics (placeholder)
        let performanceReport = "Core ML System Performance Report"
        let performanceMetrics = ["accuracy": 0.85, "latency": 0.1, "throughput": 100.0]
        
        averageAccuracy = performanceMetrics["accuracy"] ?? 0.0
        dtwSuccessRate = performanceMetrics["accuracy"] ?? 0.0
        avgAnalysisTime = performanceMetrics["latency"] ?? 0.0
        
        // Load Core ML-specific metrics (placeholder values)
        dtwMetrics = DTWMetrics(
            enhancedSuccessRate: performanceMetrics["accuracy"] ?? 0.0,
            averageDTWScore: performanceMetrics["accuracy"] ?? 0.0,
            averageTemporalAccuracy: performanceMetrics["accuracy"] ?? 0.0,
            averageVelocityConsistency: performanceMetrics["accuracy"] ?? 0.0
        )
        
        generateInsights()
        loadCategoryPerformance()
    }
    
    @MainActor
    func refreshAnalytics() async {
        // Simulate async refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadAnalytics()
    }
    
    func updateTimeRange(_ range: TimeRange) {
        currentTimeRange = range
        loadAnalytics()
    }
    
    func getChartData(for metric: AnalyticsMetric) -> [ChartDataPoint] {
        // Generate sample chart data based on metric
        let calendar = Calendar.current
        let now = Date()
        var data: [ChartDataPoint] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let value: Double
            
            switch metric {
            case .accuracy:
                value = 0.7 + Double.random(in: 0...0.3)
            case .completionTime:
                value = 120 + Double.random(in: -30...60)
            case .dtwScore:
                value = 0.8 + Double.random(in: -0.2...0.2)
            case .analysisTime:
                value = 0.03 + Double.random(in: -0.01...0.02)
            }
            
            data.append(ChartDataPoint(date: date, value: value))
        }
        
        return data.reversed()
    }
    
    private func generateInsights() {
        insights = []
        
        if dtwSuccessRate > 0.9 {
            insights.append(PerformanceInsight(
                title: "Excellent AI Performance",
                description: "Your DTW analysis is performing exceptionally well with \(String(format: "%.1f%%", dtwSuccessRate * 100)) success rate.",
                icon: "star.fill",
                type: .success
            ))
        }
        
        if averageAccuracy < 0.6 {
            insights.append(PerformanceInsight(
                title: "Practice More Basic Shapes",
                description: "Your accuracy could improve with more practice on fundamental shapes and proportions.",
                icon: "lightbulb.fill",
                type: .improvement
            ))
        }
        
        if avgAnalysisTime > 0.1 {
            insights.append(PerformanceInsight(
                title: "Performance Optimization",
                description: "Analysis times are higher than optimal. Consider closing other apps for better performance.",
                icon: "exclamationmark.triangle.fill",
                type: .warning
            ))
        }
    }
    
    private func loadCategoryPerformance() {
        categoryPerformance = LessonCategory.allCases.map { category in
            CategoryPerformanceData(
                category: category,
                completed: Int.random(in: 0...10),
                total: Int.random(in: 5...15)
            )
        }
    }
}

struct DTWMetrics {
    let enhancedSuccessRate: Double
    let averageDTWScore: Double
    let averageTemporalAccuracy: Double
    let averageVelocityConsistency: Double
    
    init() {
        self.enhancedSuccessRate = 0.0
        self.averageDTWScore = 0.0
        self.averageTemporalAccuracy = 0.0
        self.averageVelocityConsistency = 0.0
    }
    
    init(enhancedSuccessRate: Double, averageDTWScore: Double, averageTemporalAccuracy: Double, averageVelocityConsistency: Double) {
        self.enhancedSuccessRate = enhancedSuccessRate
        self.averageDTWScore = averageDTWScore
        self.averageTemporalAccuracy = averageTemporalAccuracy
        self.averageVelocityConsistency = averageVelocityConsistency
    }
}

#Preview {
    PerformanceAnalyticsDashboard()
}
