# Arcade — iOS Mini-Game Collection

A SwiftUI iOS app featuring three arcade-style mini-games with score tracking, statistics, and location tagging.

---

## Project Structure

```
sample1/
├── sample1App.swift              # App entry point, environment injection
│
├── Views/
│   ├── MainTabView.swift         # Root tab bar (Home, Stats, Map, Settings)
│   ├── MapTabView.swift          # Map view showing game session locations
│   ├── StatsView.swift           # Score history chart and per-mode summaries
│   └── SettingsView.swift        # Appearance and notification preferences
│
├── HomeView.swift                # Game-mode picker / lobby
├── ContentView.swift             # Tap Frenzy game (combo system, moving target)
├── LightItUpView.swift           # Light It Up game (whack-a-mole, 4-level grid)
├── QuizRushView.swift            # Quiz Rush game (trivia, streak multiplier)
├── QuizRushViewModel.swift       # Observable VM for Quiz Rush state
│
├── Models/
│   ├── GameMode.swift            # Enum of game modes with icons and accent colours
│   └── GameSession.swift        # Codable session model (mode, score, timestamp, location)
│
├── Services/
│   ├── SessionStore.swift        # Observable in-memory + UserDefaults session store
│   ├── LocationService.swift     # CLLocationManager wrapper (@Observable)
│   └── NotificationService.swift # UNUserNotificationCenter daily challenge scheduler
│
├── QuizService.swift             # Async fetch from Open Trivia DB API
├── QuizQuestion.swift            # Codable models for trivia API response
├── Persistence.swift             # Core Data stack (HighScore entity for Tap Frenzy)
│
└── Assets.xcassets/             # App icon, accent colour
```

---

## Game Modes

| Mode | Description | Scoring |
|---|---|---|
| **Tap Frenzy** | Tap a moving button as fast as possible in 30 s | +combo multiplier per tap within 0.5 s window |
| **Light It Up** | Tap the lit card before it fades; grid grows over 60 s | +1 correct tap, −1 miss or timeout |
| **Quiz Rush** | Answer 10 trivia questions from the Open Trivia DB | +1 per correct answer, streak tracking |

---

## Technologies Used

| Technology | Purpose |
|---|---|
| **SwiftUI** | All UI, navigation, animations |
| **Swift Observation (`@Observable`)** | Reactive state for `SessionStore` and `LocationService` |
| **Core Data** | Persistent high-score storage for Tap Frenzy |
| **UserDefaults** | Lightweight persistence for Light It Up / Quiz Rush best scores and app settings |
| **Swift Charts** | Score history bar chart in the Stats tab |
| **CoreLocation** | Geotag each game session with the player's location |
| **UserNotifications** | Daily challenge local push notification scheduler |
| **async/await (Swift Concurrency)** | Non-blocking trivia API fetch in `QuizService` |
| **Open Trivia DB API** | Free REST API providing randomised multiple-choice questions |
| **ShareLink** | Native iOS share sheet for posting scores |

---

## Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+

---

## Getting Started

1. Clone the repository and open `sample1.xcodeproj` in Xcode.
2. Select a simulator or device running iOS 17+.
3. Build and run (`Cmd + R`).
4. Grant location permission when prompted (optional — sessions are still recorded without it).
