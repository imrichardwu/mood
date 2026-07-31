# 📱 Mood Journal

> **Apple Swift Student Challenge Submission**

A privacy-first journaling app built with SwiftUI.

Track your mood. Reflect on your day. Discover patterns in your well-being using entirely on-device AI.

No accounts. No cloud. No analytics.

Your journal never leaves your device.

---

## Why?

Most journaling apps send deeply personal data to external servers so they can generate insights.

Mood Journal takes the opposite approach.

Every journal entry is analyzed locally using Apple's `NaturalLanguage` framework. Sentiment analysis, keyword extraction, and well-being scoring all happen directly on your device.

Your thoughts stay yours.

---

## Features

### 📝 Journal

* Daily mood, energy, and stress check-ins
* Rich journal entries with search and smart tags
* Fast filtering by date, notes, or category

### 🤖 On-Device AI

* Sentiment analysis with `NaturalLanguage`
* Automatic keyword extraction
* Well-being scoring
* Trend detection across journal history

### 📊 Insights

* Mood, energy, and stress trends
* Calendar heatmaps
* Progress tracking
* AI-powered insights dashboard

### 🎯 Goals

* Daily and weekly journaling goals
* Progress visualization
* Habit tracking

### 🧘 Wellness

* Guided breathing exercises
* Curated wellness resources

---

## Privacy

Privacy isn't a feature.

It's the architecture.

* No accounts
* No cloud storage
* No analytics
* No third-party APIs
* No network requests

Everything stays on your device.

---

## Tech Stack

| Layer        | Technology            |
| ------------ | --------------------- |
| Language     | Swift 6               |
| UI           | SwiftUI               |
| AI           | Apple NaturalLanguage |
| Architecture | MVVM                  |
| Storage      | UserDefaults          |
| State        | SwiftUI + Combine     |

---

## Architecture

```
Views
    ↓
View Models
    ↓
Services
    ↓
Local Storage
```

### Project Structure

```
Mood Journal.swiftpm
├── Models
├── Services
├── Views
├── Theme
└── Assets
```

The app is organized around a simple MVVM architecture.

* **Views** render the interface.
* **Services** handle NLP, scoring, and persistence.
* **Models** represent journal entries, goals, and tags.
* **Theme** provides reusable styling across the app.

Keeping responsibilities separated makes new features easy to add without touching unrelated code.

---

## Interesting Implementation Details

* Uses Apple's `NaturalLanguage` framework for fully local sentiment analysis.
* Extracts keywords from journal entries without external APIs.
* Computes a composite well-being score using mood, stress, energy, and sentiment.
* Generates calendar heatmaps and historical trends from local data.
* Supports fast search across notes, tags, and dates.
* Built entirely offline.

---

## Getting Started

### Requirements

* iOS 16+
* Xcode 15+
* Swift 6

### Run

```bash
git clone <repository-url>
cd mood
```

Open `Mood Journal.swiftpm` in Xcode or Swift Playgrounds and press **Run**.

---

## Future Work

* Apple Watch companion app
* Home Screen widgets
* PDF and JSON export
* Custom tags
* Optional end-to-end encrypted iCloud sync

---

## Disclaimer

Mood Journal is designed for personal reflection and is **not** a substitute for professional mental health care.

If you're experiencing a mental health crisis, please seek help from a qualified healthcare professional or your local emergency services.

---

## Philosophy

Powerful AI doesn't require giving up your privacy.

Mood Journal demonstrates that modern, intelligent experiences can run entirely on-device, giving users meaningful insights while keeping their personal thoughts exactly where they belong: on their own device.
