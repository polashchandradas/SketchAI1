# 🤖 CodeRabbit AI Setup for SketchAI

This guide will help you set up CodeRabbit AI for automated code reviews in your SketchAI iOS project.

## 📋 Prerequisites

- GitHub repository for your SketchAI project
- Cursor IDE with CodeRabbit extension
- Admin access to your GitHub repository
- CodeRabbit.ai account

## 🚀 Quick Setup Guide

### 1. Install CodeRabbit Extension in Cursor

1. Open Cursor IDE
2. Navigate to Extensions (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for "CodeRabbit"
4. Click "Install"

### 2. Authenticate CodeRabbit

1. Click the CodeRabbit icon in Cursor's Activity Bar
2. Select "Login to CodeRabbit"
3. Choose GitHub authentication
4. If redirect fails:
   - Copy the authentication token
   - Use HTML decoder to decode the token
   - Press Ctrl+Shift+P (Cmd+Shift+P on Mac)
   - Type "open URL DEV"
   - Paste the decoded URL
   - Select Cursor as the app

### 3. GitHub Repository Setup

1. Create a GitHub repository if you haven't already:
   ```bash
   # In your SketchAI project directory
   git init
   git remote add origin https://github.com/your-username/SketchAI.git
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

### 4. Configure Repository Secrets

Add these secrets to your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Add the following secrets:

   - `CODERABBIT_TOKEN`: Your CodeRabbit API token
     - Get this from [CodeRabbit Dashboard](https://app.coderabbit.ai/settings/tokens)
     - Click "Generate New Token"
     - Copy and paste into GitHub secrets

### 5. Enable GitHub Actions

1. Go to your repository's Actions tab
2. Enable GitHub Actions if prompted
3. The CodeRabbit workflow will automatically run on:
   - Pull requests
   - Pushes to main/develop branches

## 📁 Configuration Files

The setup includes these configuration files:

### `.coderabbit.yaml`
- Main configuration for CodeRabbit AI
- iOS/Swift specific settings
- SketchAI project focus areas
- Custom review instructions

### `.github/workflows/coderabbit-review.yml`
- GitHub Actions workflow
- Automated code reviews
- Swift code quality checks
- Performance and security analysis

## 🎯 SketchAI-Specific Features

CodeRabbit is configured to focus on:

### Drawing Performance
- Real-time stroke analysis optimization
- Memory efficiency in graphics operations
- Frame-rate optimization (60fps+)
- Circular buffer implementations

### Computer Vision & ML
- Vision framework usage patterns
- Core ML integration
- Face detection and landmarks
- Error handling for ML operations

### Memory Management
- Retain cycle detection
- Drawing canvas memory optimization
- Image processing pipelines
- Video recording efficiency

### SwiftUI Architecture
- State management patterns
- ObservableObject usage
- View lifecycle optimization
- Navigation state handling

### Educational Features
- Lesson progression logic
- Achievement system validation
- Progress tracking accuracy
- Content quality checks

## 🔧 Usage Instructions

### In Cursor IDE

1. **Real-time Reviews**:
   - CodeRabbit will analyze code as you write
   - Inline suggestions appear in the editor
   - Click on suggestions to apply fixes

2. **Manual Reviews**:
   - Open CodeRabbit panel
   - Select changes to review (staged/unstaged)
   - Get AI-powered feedback

3. **Fix with AI**:
   - Right-click on issues
   - Select "Fix with AI"
   - Choose your preferred AI agent

### On GitHub

1. **Pull Request Reviews**:
   - CodeRabbit automatically reviews PRs
   - Inline comments on specific lines
   - Summary comments with overall feedback

2. **Push Reviews**:
   - Automatic analysis on main branch pushes
   - Performance and security checks
   - Code quality metrics

## 📊 Review Categories

CodeRabbit will categorize issues by severity:

### 🔴 Critical
- Memory leaks
- Retain cycles
- Main thread blocking
- Security vulnerabilities
- Privacy violations

### 🟠 High
- Performance issues
- Threading violations
- Core Data threading problems
- Force unwrapping
- Architecture violations

### 🟡 Medium
- Code style violations
- Naming conventions
- Missing documentation
- Unused variables

### 🟢 Low
- Spacing issues
- Comment style
- Import organization

## 🛠️ Customization

### Modify Review Focus
Edit `.coderabbit.yaml` to adjust:
- Focus areas
- Severity levels
- File patterns
- Custom rules

### Workflow Adjustments
Edit `.github/workflows/coderabbit-review.yml` to:
- Change trigger conditions
- Add custom analysis steps
- Modify notification settings

## 📈 Analytics & Insights

CodeRabbit provides:

### Code Quality Metrics
- Issue trends over time
- Code complexity analysis
- Performance bottlenecks
- Security vulnerability tracking

### Team Insights
- Review response times
- Common issue patterns
- Learning recommendations
- Best practice suggestions

## 🔍 Troubleshooting

### Common Issues

1. **Authentication Problems**:
   - Re-authenticate in Cursor
   - Check token expiration
   - Verify GitHub permissions

2. **Reviews Not Triggering**:
   - Check GitHub Actions status
   - Verify webhook configuration
   - Ensure proper file patterns

3. **False Positives**:
   - Adjust severity levels in config
   - Add exclusion patterns
   - Provide feedback to improve AI

### Getting Help

- [CodeRabbit Documentation](https://docs.coderabbit.ai)
- [GitHub Actions Troubleshooting](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows)
- [Cursor Extension Issues](https://forum.cursor.com)

## 🎉 Best Practices

### For SketchAI Development

1. **Commit Frequently**:
   - Small, focused commits get better reviews
   - Clear commit messages help AI understand context

2. **Use Descriptive PR Titles**:
   - Help CodeRabbit understand the purpose
   - Include performance/memory impact notes

3. **Address Critical Issues First**:
   - Focus on memory leaks and performance
   - Security issues should be immediate priority

4. **Learn from Reviews**:
   - CodeRabbit adapts to your coding style
   - Consistent patterns improve suggestions

5. **Combine with Manual Reviews**:
   - AI catches technical issues
   - Human reviews for design and UX

## 📚 Additional Resources

- [Swift Performance Best Practices](https://developer.apple.com/documentation/swift/performance)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [iOS Memory Management](https://developer.apple.com/documentation/swift/automatic_reference_counting)
- [Core Data Concurrency](https://developer.apple.com/documentation/coredata/core_data_concurrency)

---

## 🚀 Ready to Start!

Your SketchAI project is now configured with CodeRabbit AI! 

Start making changes to your code and watch as CodeRabbit provides intelligent, context-aware reviews specifically tailored for iOS development and your drawing education app.

Happy coding! 🎨📱
