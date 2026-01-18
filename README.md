# Mood Journal 📱

> **Apple Swift Student Challenge Submission**

A beautiful, privacy-first iOS app built with SwiftUI that helps you track your mood, journal your thoughts, and gain meaningful insights into your well-being—all while keeping your data completely private and secure on your device.

## 🌟 Overview

Mood Journal is a comprehensive mental wellness app that combines intuitive journaling with powerful on-device AI analysis. Built entirely with Swift and SwiftUI, this app demonstrates advanced iOS development techniques including natural language processing, data visualization, and thoughtful UX design.

### Why I Built This

Mental health awareness is more important than ever, but many existing apps compromise user privacy by sending sensitive data to external servers. I wanted to create a solution that provides intelligent insights while maintaining complete privacy—proving that powerful AI features can run entirely on-device using Apple's frameworks.

## ✨ Key Features

### 📝 Intelligent Journaling
- **Quick Check-ins**: Log mood, energy, and stress levels with intuitive sliders
- **Rich Text Entries**: Write freely about your day, thoughts, and experiences
- **Smart Tagging**: Categorize entries with contextual tags (Work, Family, Exercise, etc.)
- **Powerful Search**: Find entries instantly by searching notes, tags, or dates

### 🤖 On-Device AI Analysis
- **Sentiment Analysis**: Uses Apple's `NaturalLanguage` framework to analyze entry tone
- **Keyword Extraction**: Automatically identifies key themes and topics
- **Well-being Scoring**: Calculates comprehensive scores from multiple data points
- **Pattern Recognition**: Identifies trends and correlations in your journaling data

### 📊 Data Visualization
- **Trends View**: Beautiful charts showing mood, energy, and stress patterns over time
- **Calendar Heatmap**: Visual calendar showing journaling activity and streaks
- **Progress Tracking**: Visual indicators for goal completion
- **Insights Dashboard**: AI-powered insights with sentiment breakdowns

### 🎯 Goal System
- **Flexible Goals**: Track entries per day/week, journaling days, or word counts
- **Progress Visualization**: Real-time progress bars and completion indicators
- **Customizable Targets**: Set and adjust goals to match your needs
- **Achievement Tracking**: Celebrate milestones as you build healthy habits

### 🧘 Wellness Tools
- **Guided Breathing**: Relaxation exercises with visual guidance
- **Resources**: Curated mental health and wellness resources

## 🛠️ Technical Highlights

### Advanced Swift Features
- **Swift 6.0**: Leverages latest language features and concurrency
- **MVVM Architecture**: Clean separation of concerns with `@StateObject` and `@EnvironmentObject`
- **Protocol-Oriented Design**: Reusable, testable components
- **Type Safety**: Strong typing throughout with enums, structs, and generics

### SwiftUI Mastery
- **Declarative UI**: Modern SwiftUI views with composition
- **Custom Components**: Reusable card views, calendar grids, and progress indicators
- **Navigation**: `NavigationStack` with deep linking support
- **Animations**: Smooth transitions and state-based animations
- **Adaptive Design**: Works beautifully on iPhone and iPad

### On-Device Machine Learning
- **NaturalLanguage Framework**: Sentiment analysis and keyword extraction
- **Fallback Heuristics**: Graceful degradation when NLP isn't available
- **Performance Optimization**: Efficient text processing and caching
- **Privacy-Preserving**: All analysis happens locally—no data leaves the device

### Data Management
- **Persistence Layer**: Custom abstraction over UserDefaults
- **Codable Models**: Type-safe serialization
- **State Management**: Reactive updates with Combine patterns
- **Data Filtering**: Efficient search and filtering algorithms

## 📱 Screenshots
*Screenshots coming soon*

## 🏗️ Architecture

```
Mood Journal.swiftpm/
├── Models/              # Core data models
│   ├── MoodEntry.swift      # Journal entry with derived NLP data
│   ├── Goal.swift            # Goal tracking with progress calculation
│   └── Tag.swift             # Categorization system
├── Services/            # Business logic and data management
│   ├── EntryStore.swift      # Entry CRUD operations
│   ├── GoalStore.swift       # Goal management
│   ├── NlpAnalyzer.swift     # On-device NLP processing
│   └── WellBeingScorer.swift # Composite scoring algorithm
├── Views/               # SwiftUI views
│   ├── TabShell.swift        # Main navigation
│   ├── CheckInView.swift     # Journal with calendar
│   ├── TrendsView.swift      # Data visualization
│   ├── InsightsView.swift    # AI insights display
│   └── [Other views...]
└── Theme/               # Design system
    └── AppTheme.swift        # Consistent theming
```

## 🎓 What I Learned

Building Mood Journal was an incredible learning experience that pushed me to explore many advanced iOS development concepts:

### Technical Skills
- **Advanced SwiftUI**: Complex view composition, custom modifiers, and state management
- **Natural Language Processing**: Implementing sentiment analysis and keyword extraction
- **Data Visualization**: Creating custom charts and calendar views
- **Architecture Patterns**: MVVM with proper separation of concerns
- **Performance**: Optimizing NLP processing and data filtering

### Design & UX
- **User-Centered Design**: Creating intuitive interfaces for sensitive mental health data
- **Accessibility**: Ensuring the app is usable for everyone
- **Visual Design**: Building a cohesive design system with custom theming
- **Information Architecture**: Organizing complex features into a clear navigation structure

### Problem Solving
- **Privacy Engineering**: Implementing on-device processing to protect user data
- **Algorithm Design**: Creating well-being scoring algorithms from multiple data points
- **Data Modeling**: Designing flexible, extensible data structures
- **Error Handling**: Graceful fallbacks when NLP features aren't available

## 🚀 Getting Started

### Requirements
- iOS 16.0+
- Xcode 15.0+ or Swift Playgrounds 4.0+
- Swift 6.0

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mood
   ```

2. **Open in Xcode**
   - Open `Mood Journal.swiftpm` in Xcode
   - Select your target device or simulator
   - Build and run (⌘R)

3. **Or use Swift Playgrounds**
   - Open `Mood Journal.swiftpm` in Swift Playgrounds
   - Run directly on iPad or Mac

## 🔒 Privacy & Security

Privacy is at the core of Mood Journal's design:

- ✅ **100% On-Device Storage**: All data stored locally using UserDefaults
- ✅ **No Network Access**: The app never connects to the internet
- ✅ **On-Device AI**: All NLP processing happens locally using Apple's frameworks
- ✅ **No Third-Party Services**: Zero external dependencies or APIs
- ✅ **No Analytics**: No tracking, no data collection, no telemetry
- ✅ **No Cloud Sync**: Your journal entries never leave your device

Your thoughts are yours alone.

## 🎯 Future Enhancements

Ideas for future development:
- Export functionality (PDF, JSON)
- Custom tag creation
- Advanced filtering and sorting
- Widget support for quick check-ins
- Apple Watch companion app
- iCloud sync (opt-in, end-to-end encrypted)

## 📚 Technologies Used

- **Swift 6.0** - Modern Swift with latest features
- **SwiftUI** - Declarative UI framework
- **NaturalLanguage** - On-device NLP processing
- **Foundation** - Core data structures and date handling
- **Combine** - Reactive programming patterns (implicitly via SwiftUI)

## 🙏 Acknowledgments

- Apple's NaturalLanguage framework for enabling on-device AI
- The Swift and SwiftUI communities for excellent documentation
- Mental health advocates who inspire privacy-first wellness tools

## ⚠️ Important Note

This app is designed for personal use and is **not a substitute for professional mental health care**. If you're experiencing a mental health crisis, please contact a healthcare provider or emergency services.

---

**Built with ❤️ for the Apple Swift Student Challenge**

*Demonstrating that powerful, intelligent apps can be built while respecting user privacy.*
