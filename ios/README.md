# KidsActivity iOS App

SwiftUI app that fetches the JSON published by the Python backend and lets
you browse / filter kids activities. Pure read-only client; no auth.

## Prerequisites

- macOS with Xcode 15+ installed (the App Store version, not just the
  Command Line Tools).
- Open Xcode once and accept the license.

## Generate the Xcode project

```bash
brew install xcodegen        # one-time
cd ios
xcodegen generate            # produces KidsActivity.xcodeproj
open KidsActivity.xcodeproj
```

`KidsActivity.xcodeproj` is a generated artifact — don't commit it.
Re-run `xcodegen generate` whenever you add/remove a Swift file.

If you'd rather skip XcodeGen, in Xcode pick **File → New → Project →
iOS App** (SwiftUI, Swift), then drag `KidsActivity/KidsActivity/`
(everything under it) into the project navigator, ticking
"Copy if needed".

## Run

1. Pick an iPhone simulator from the toolbar.
2. Hit ⌘R.

On first launch the app fetches data from
`https://vivianm1024.github.io/KidsActivity/data/{manifest,venues,activities}.json`.
If your GitHub Pages URL differs (e.g. you forked under another username),
edit `DataLoader.baseURL` in `Services/DataLoader.swift`.

## Sideload to your phone

- Plug your iPhone in and pick it as the run destination.
- Add a free Apple ID under **Signing & Capabilities** (Personal Team).
  This signs the build for 7 days.
- For longer-lived installs, enroll in the Apple Developer Program ($99/yr)
  and use TestFlight.

## File map

| File | Role |
| --- | --- |
| `KidsActivityApp.swift` | `@main` entry, owns `ActivityStore`. |
| `Models/Activity.swift` | `Activity`, `Schedule`, `Price`, `AgeRange`, `Registration`. Mirrors backend pydantic. |
| `Models/Venue.swift` | `Venue` shape. |
| `Models/Manifest.swift` | Schema-version manifest read on load. |
| `Services/DataLoader.swift` | Fetches JSON, caches to disk, fallback when offline. |
| `Services/FilterEngine.swift` | Pure function: applies filters in-memory. |
| `Services/Formatters.swift` | Display helpers. |
| `ViewModels/ActivityStore.swift` | `@Observable` source of truth. |
| `Views/ContentView.swift` | NavigationStack + toolbar. |
| `Views/ActivityListView.swift` | Filtered list with status header. |
| `Views/ActivityRowView.swift` | One row in the list. |
| `Views/ActivityDetailView.swift` | Detail screen with `SFSafariViewController` registration link. |
| `Views/FilterSheet.swift` | Filter form (venue type / age / dates / keyword / registration-open). |
