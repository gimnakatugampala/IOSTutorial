# 🎮 Game Center

A SwiftUI iOS app bundling three quick-play mini-games — **Tap Frenzy**, **Light It Up**, and **Quiz Rush** — with shared stats tracking, a session map, and a settings hub, all wrapped in a native four-tab experience.

## Games

| Game | What you do |
|---|---|
| **Tap Frenzy** | Chase a shrinking, moving target before the 10-second clock runs out. Three difficulties change how fast it jumps and whether misses cost points. |
| **Light It Up** | Tap glowing cards before they go dark. Ramps through 5 escalating levels (culminating in "Overdrive"), with combo streaks, bonus "golden" cards, and a lives system. |
| **Quiz Rush** | Live trivia pulled from [Open Trivia DB](https://opentdb.com), across 13 selectable genres, with streak bonuses and a 10-question run per round. |

## Features

- **Home** — arcade-ticket-styled hub linking to all three games, with at-a-glance games played / streak / top mode.
- **Stats** — overview cards, a mode/date-range/metric-filterable bar chart (Swift Charts), and a full session history.
- **Map** — every completed session is dropped as a pin at the player's location (via Core Location), filterable by mode and date range, with a tap-to-expand detail sheet.
- **Settings** — accent color picker (used app-wide), per-round-length Light It Up high scores, a daily play-reminder notification, and destructive actions to reset high scores or clear session history independently.

## Tech Stack

- **SwiftUI** + **Combine** for UI and game-loop timers
- **Swift Charts** for the Stats bar chart
- **MapKit** + **Core Location** for the Map tab and per-session location tagging
- **UserNotifications** for the daily reminder
- **UserDefaults** for all persistence (no backend/server component)
- Swift 5, targeting **iOS 26.2+**, built with **Xcode 26.2+**

## Project Structure

```
IOSApp/
├── App/                    # App entry point (IOSAppApp.swift)
├── Models/                 # GameMode, GameDifficulty, GameSession, Card, QuizQuestion/Category
├── ViewModels/              # Game logic: TapFrenzyVM, LightItUpVM, QuizRushVM, StatsVM
├── Views/
│   ├── Tabs/                # HomeTab, StatsTab, MapTab, SettingsTab, MainTabView
│   ├── Games/               # TapFrenzyView, LightItUpView, QuizRushView
│   ├── Shared/               # ScoreBadge, GameMenuButton, ShareScoreButton, SegmentedFilterBar
│   └── SplashView.swift
├── Services/                # LocationService, NotificationService, GameCenterService, RandomUserService
├── Helpers/
│   ├── Theme/                # AppTheme (single source of truth for color/spacing), ThemeManager
│   └── String+Base64.swift  # Decodes OpenTDB's base64-encoded trivia text
└── Assets.xcassets/
```

## Getting Started

1. Clone the repo and open `IOSApp.xcodeproj` in Xcode 26.2 or later.
2. Select the `IOSApp` scheme and a simulator or device running iOS 26.2+.
3. Build and run (**⌘R**).
4. On first launch you'll be asked for location permission — this is used to tag each game session with where it was played, for the Map tab.

### Networking notes

- Quiz Rush requires network access to `opentdb.com` at runtime; if the request fails or a genre is out of questions, the game shows a retry/switch-genre screen instead of crashing.
- Each saved session makes a best-effort call to `randomuser.me` for a placeholder player name/photo used on Map pins. If that call fails (e.g. offline), the session still saves — it just has no name/photo attached.
- No API keys are required for either service.

### Simulator location

Since the iOS Simulator has no real GPS, it reports a simulated location that's configured per-machine rather than part of the project. If Map pins show up in the wrong place after a fresh clone:

- **Quick fix:** with the Simulator running, go to **Features → Location → Custom Location…** in the Simulator app's menu bar and enter your desired coordinates.
- **Persistent fix:** in Xcode, **Product → Scheme → Edit Scheme → Run → Options → Core Location**, enable "Allow Location Simulation," and set a Custom Location there so it's used on every run.

## Data & Persistence

Everything is stored locally via `UserDefaults` — there's no server or account system:

- `PlayHub_SavedSessions` — the full session history (JSON-encoded `[GameSession]`)
- `tapFrenzyHighScore(_easy/_medium/_hard)`, `lightItUpHighScore(_30/_60/_90)`, `quizRushHighScore` — per-mode best scores
- `selectedAccentColor`, `lightItUpRoundLength`, `notificationsEnabled`, `reminderHour`/`reminderMinute` — user preferences

Settings' "Clear All Game Data" removes session history and map pins only; "Reset All High Scores" resets best scores only. The two are intentionally independent.

## Known Limitations

- All data is local to the device — nothing syncs between devices or machines.
- The "player" name/photo attached to each session is just a randomly generated placeholder from a public API, not a real identity or multiplayer feature.
- Map pins are jittered slightly from the recorded coordinate so multiple sessions played in the same spot don't render exactly on top of one another.

## Credits

Built by Gimna Katugampala. Trivia content courtesy of [Open Trivia DB](https://opentdb.com); placeholder player data courtesy of [randomuser.me](https://randomuser.me).
