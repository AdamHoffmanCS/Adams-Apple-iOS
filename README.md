# Adams Apple — iOS (Native SwiftUI)

A native SwiftUI rewrite of the Adams Apple workout web app. It mirrors the web
version feature-for-feature:

- **Dashboard** — stats (workouts logged, exercises done, day streak) + Quick Start
- **Programs** — Strength / Cardio / Flexibility / HIIT / Hyrox categories, plus a
  custom **My Workouts** builder. Every exercise has a **+ Log** button.
- **Workouts** — searchable exercise database (104 built-in exercises bundled, plus
  an optional 800+ from the free-exercise-db when online). Add/remove your own
  custom exercises with sets/reps, YouTube link, and key-point instructions.
- **Fasting** — customizable fasting window, live countdown, and a ring that shifts
  from **red → yellow → green** as your eating window approaches.
- **Log** — full workout log with per-exercise progress charts.
- **Timer** — floating stopwatch + countdown with round tracking (tap the green
  circle button).

All data persists locally via `UserDefaults` (the same data the web app kept in
`localStorage`).

> This is a **separate project and repository** from the web app. The web version
> (`index.html`, `app.js`, `style.css`) is untouched and still lives in the parent
> folder.

## Requirements

- macOS with **Xcode 15+**
- **iOS 16+** deployment target
- Your Apple Developer account (for running on a device / App Store)

## Open it in Xcode

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) so the repo stays clean (no giant
`.pbxproj` to merge).

```bash
# 1. Install XcodeGen (one time)
brew install xcodegen

# 2. From this folder, generate the Xcode project
cd AdamsAppleiOS
xcodegen generate

# 3. Open it
open AdamsApple.xcodeproj
```

Then in Xcode:

1. Select the **AdamsApple** target → **Signing & Capabilities**.
2. Choose your **Team** (your Apple Developer account). You can also set
   `DEVELOPMENT_TEAM` in `project.yml` and re-run `xcodegen generate`.
3. Pick a simulator or your iPhone and press **▶ Run**.

### Prefer not to use XcodeGen?

Create a new **iOS App** in Xcode (SwiftUI interface, name it `AdamsApple`), delete
the auto-generated `ContentView.swift` / `App.swift`, then drag everything in
`Sources/` (including `Sources/Resources/*.json` and `Sources/Assets.xcassets`) into
the project — making sure **"Copy items if needed"** and the app target are checked.

## Push to a new GitHub repository

The commits are already made locally. Create an **empty** repo on GitHub (no README),
then from this folder:

```bash
cd AdamsAppleiOS
git remote add origin https://github.com/AdamHoffmanCS/Adams-Apple-iOS.git
git branch -M main
git push -u origin main
```

(Replace the URL with whatever you name the new repo.)

## Project layout

```
AdamsAppleiOS/
├── project.yml                # XcodeGen project definition
├── Sources/
│   ├── AdamsAppleApp.swift     # @main entry
│   ├── RootView.swift          # TabView + floating timer
│   ├── Theme.swift             # colors ported from the web CSS
│   ├── Models.swift            # Codable models
│   ├── Store.swift             # ObservableObject persistence
│   ├── AppData.swift           # loads the bundled JSON
│   ├── *View.swift             # one file per screen
│   └── Resources/*.json        # exercise data extracted from the web app
└── Sources/Assets.xcassets     # accent color + app icon slot
```
