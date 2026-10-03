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

- Speech recognition must be tested on a physical iPhone. It may fail to initialize or stop immediately in the iOS Simulator because the necessary speech services or language assets are unavailable.
- All data is local to the device — nothing syncs between devices or machines.
- The "player" name/photo attached to each session is just a randomly generated placeholder from a public API, not a real identity or multiplayer feature.
- Map pins are jittered slightly from the recorded coordinate so multiple sessions played in the same spot don't render exactly on top of one another.

## Reflection 

-   Before developing this app I had little to no experience in developing apps for IOS. At the beginning it hard to even control the iMac in the Lab since I had only little experince operating a MacOS. But with consistant  visits to the macLab putting long hours to first get familiar with the MacOS Environment. Then learning SwiftUI was not hard since it is like any other programming language, therefore it was not a huge issue. Also, since our Lecturer Mr.Fuzil, broke this Course work down and gave us the work in stages it was very easy to grasp the module and the concepts of IOS. building those 3 games gave an insight on how to handle the apple SDKs and utilize the hardware for our development. Other than the SDKs I learnt to integrate external APIs and store them in our local storage. Before our IOS module i didn't really think about accecability features, but our lecturer encorage and dicussed the importance of adding those features to our apps. I was an enlighting experience beacuse there are so many different people who has diabilities and limitations and would lile or benefit from the apps we develop. Accecability features gives them a message that they are really heard and not merginalized. Therefore, in my app, I implemented voice control, and text-to-speech functionality to my app. This project also exposed me to different swift packages such as Swift Chart, Map Kit, Core Location and etc. Another challenge was managing data across different parts of the application. I used UserDefaults to persist game sessions, high scores and user preferences. This app also improved my understanding of reusable SwiftUI components. As the application became larger, separating common interface elements and game logic made the code easier to understand. 

-   Finally, developing this app gave me an experience beyond just creating some UI screens, I learnt how to integrate device capabilities, external data, persistent state and multiple application features while keeping the code organised. I can confidently say that this app really had me shapern my skills in my programming and artitecture.

    


## Credits

Built by Gimna Katugampala. Trivia content courtesy of [Open Trivia DB](https://opentdb.com); placeholder player data courtesy of [randomuser.me](https://randomuser.me).
