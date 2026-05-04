# Task Plan — V5 "Warm Hybrid" iOS Front-end

## Goal

Recreate the V5 design-handoff bundle natively in SwiftUI inside `ios/KidsActivity/`,
matching the warm-editorial visual language and high-fidelity specs in
`design_handoff_v5_hybrid/README.md`. Replace the system-default chrome with
hand-tuned tokens, add Saved + Calendar tabs, and ship the new co-parent /
conflict / transparency / handoff surfaces.

## Constraints / Non-goals

- **Native SwiftUI only** — no WebView, React Native, or new third-party libs.
- **Existing patterns** — keep `@Observable ActivityStore`, `Codable` models,
  `NavigationStack`, native `TabView`. Use SF Symbols where the prototype
  inlines SVG glyphs.
- **Persistence** — stay on `UserDefaults` + JSON snapshot already wired in
  `ActivityStore`/`StorePersistence` (don't introduce SwiftData unless the
  user asks).
- **Co-parent + Why-this surfaces are OPT-IN** — single-parent users must
  never see those entry points.
- **Distance, partner state, and per-kid availability mocks** are placeholders
  in the prototype; surface as `// TODO:` with realistic stub values.

## Current state of the codebase (2026-05-04)

The first wave of the redesign is already substantially landed. The remaining
work is the **second batch** of new prototypes under `design_handoff_v5_hybrid/`.

| README step | Status | iOS file(s) |
|---|---|---|
| 1. Tokens | DONE | `Views/DesignTokens.swift` (full OKLCH palette + CategoryStyle + Kid styling + WarmCard) |
| 2. TabView shell | DONE | `Views/ContentView.swift` |
| 3. Onboarding | PARTIAL — no Welcome step | `Views/Onboarding/OnboardingFlow.swift` + Kids/Location/Availability steps |
| 4. BrowseView | DONE | `Views/ActivityListView.swift` (struct `BrowseView`) |
| 5. FilterSheet | DONE | `Views/FilterSheet.swift` |
| 6. Activity Detail | DONE (no co-parent row yet) | `Views/ActivityDetailView.swift` |
| 7. Registration handoff sheet | NOT STARTED | new `Views/RegistrationHandoffSheet.swift` |
| 8. SavedView | DONE | `Views/SavedView.swift` |
| 9. CalendarView | DONE — no conflict detection or parent filter | `Views/CalendarView.swift` |
| 10. Share / link parents | NOT STARTED | new `Views/Settings/Share*.swift` + Parent / Assignment models |
| 11. Why this? transparency | NOT STARTED | new `Views/Browse/WhyThisSheet.swift` |
| 12. Export (.ics + EventKit) | DONE | `Services/CalendarExportService.swift`, `ICSExporter` in CalendarView |

## Phases (mapped to README build order)

### Phase A — token + onboarding deltas (steps 1, 3 fixups)
- [x] **A.1** Add new tokens to `DesignTokens.swift`: `amberWarn`, `amberWarnSoft`,
      `amberWarnInk`, `partnerBlue`, `partnerBlueSoft`, `partnerBlueInk`,
      `dangerRed`, `dangerRedSoft`. Both as `Color` extensions and `ShapeStyle`
      shorthands.
- [x] **A.2** Re-skin `OnboardingFlow.swift` header (back chevron + thin
      progress bar + step counter); single-CTA footer with adaptive label;
      replaced `stepHeader` helper with `stepHero(eyebrow:title:subtitle:)`.
- [x] **A.3** Step polish:
      - Kids step: eyebrow "Welcome", title "Who are we planning for?",
        added "Stays on this device" privacy info card.
      - Location step: eyebrow "Step 2", title "Where's home?", upgraded
        the "Use my current location" CTA to the prototype's bubble-icon
        card (icon + label + subtitle + chevron).
      - Availability step: replaced day grid with 1:1.1 cap-pill grid
        (letter + 3-letter day name, terracotta-on shadow), added presets
        below the grid, and a "You'll see" summary card with collapsed
        labels (Weekends / Weekdays / Any day of the week).

### Phase B — Registration handoff (step 7)
- [x] Add `Views/RegistrationHandoffSheet.swift` matching `v5-handoff.jsx`:
      hero, summary card, "you'll need" rows (with COPY chip via
      UIPasteboard), 3-step list, sticky terracotta CTA → `SafariView` +
      "Already done? I registered" secondary link.
- [x] Wire it from `ActivityDetailView`'s "Register" CTA (only when
      `status == .open`). Other statuses keep direct Safari since their
      CTAs are informational (Remind me / Join waitlist / View listing).
      Persists "I registered" via existing `ActivityStore.toggleRegistered`.

### Phase C — Co-parent foundation (step 10, prerequisites for step 9)
- [x] Models: `Parent`, `AssignmentKind`, `Assignment`, `LinkedParent` in
      `Models/Parent.swift`. Custom Codable for `AssignmentKind` (tagged
      union). `InviteCode` helper with `generate()` / `isValid(_:)`.
- [x] `ActivityStore` extension: `linkedParent`, `assignments`,
      `assignment(for:on:)`, `setAssignment / clearAssignment`,
      `linkPartner / unlinkPartner`, `loadSummaryThisWeek()`. Persisted via
      `StoreSnapshot`.
- [x] Settings views:
      - `Settings/SettingsView.swift` — hub. Branches on `linkedParent`:
        unlinked → CTA cards for ShareCode / EnterCode; linked → row to
        `LinkedSettingsView`. About section shows kids/saved/registered/zip
        counts.
      - `Settings/ShareCodeView.swift` — generated code, copy + share-sheet
        actions, "What you'll share" rows, privacy footer.
      - `Settings/EnterCodeView.swift` — three word inputs (auto-advancing,
        partner-blue focus ring), paste-full-code shortcut, link preview when
        all three filled. Confirm creates `LinkedParent`.
      - `Settings/LinkedSettingsView.swift` — partner hero, real load summary
        (driven by `loadSummaryThisWeek`), recent activity log, manage rows,
        unlink with destructive alert.
      - `Settings/LinkedLoadView.swift` — standalone load surface (parity
        artboard).
- [x] `Views/Components/ParentChip.swift` — shared mini-avatar with `.both` /
      `.solo` / `.split` / `.unassigned` kinds.
- [x] Browse gear-icon toolbar entry → `SettingsView` sheet.

### Phase D — Detail co-parent + Calendar co-parent (steps 6 follow-up, 9)
- [x] `Views/Detail/WhosGoingSection.swift` — collapsed "+ Add {partner}"
      ghost row by default; expanded segmented control (Both / Solo / Split)
      with per-mode bodies. Only renders when `linkedParent != nil`. Saving
      writes `Assignment` for the activity.
- [x] Calendar parent filter bar — pill row All / Mine / {partner}'s / Both
      with counts, only when `linkedParent != nil` AND at least one
      assignment exists.
- [x] Parent chips on day-event cards — `assignmentChipKind` resolves the
      right chip per event (solo for the kid's assignee in split mode).

### Phase E — Conflict detection (step 9 follow-up)
- [x] `ActivityStore.Conflict` struct + `conflicts(on:)` + `conflictDayKeys`
      overlap computation (sorted-pair sweep).
- [x] `Services/TravelTimeService.swift` — async MapKit `MKDirections` ETA
      with session-level cache; returns `nil` on failure.
- [x] Calendar month-cell yellow ring + amberWarn dot when a day has
      conflicts (replaces the green dot for that day).
- [x] Day-block "N conflict" pill replaces the event count when conflicts
      exist; tap routes to `ResolveConflictSheet`.
- [x] `Views/Calendar/ResolveConflictSheet.swift` — eyebrow with day name,
      24pt display title, stacked timeline (kid-colored bars, overlap
      stripe, MapKit-driven travel-time row), three options (skip secondary,
      split-with-partner if linked, cancel one). Each option calls into the
      store directly.

### Phase F — Why-this transparency + empty/loading states (steps 11, fixups)
- [x] `Views/Browse/WhyThisSheet.swift` — sheet wired from a "Why these?"
      info-button next to the result count. Reads real signals from
      `store.filters` (distance cap, days, age window, registration filter,
      price cap, saved-similarity heuristic) and scores the top
      `filteredActivities` against each. Met rules colored sage; non-applicable
      rules struck through.
- [x] `Views/Components/SkeletonViews.swift` — `Bone` (TimelineView pulse),
      `BrowseSkeletonView`, `CalendarSkeletonView`, `CachedBanner`. ContentView
      now shows `BrowseSkeletonView` instead of a spinner during load — UI
      shape sticks.
- [ ] **Deferred**: `CachedBanner` is built but not auto-wired to network state.
      DataLoader would need a "from cache" signal so Browse can show the banner
      after a stale load. Slot is ready; trigger isn't.
- [ ] **Deferred**: Saved + Calendar empty states match `v5-empty.jsx` only at
      the structural level. Polishing the soft illustrations is a
      visual-polish pass — not blocking.

## Decisions

- 2026-05-04 — **Persistence: keep UserDefaults+JSON snapshot.** Existing
  `StorePersistence` is good; switching to SwiftData mid-redesign would force a
  migration without earning anything visible.
- 2026-05-04 — **Single source of truth for parents:** `linkedParent` lives on
  `ActivityStore`. `Assignment` keys by `activityId` + optional `sessionDate`
  so a per-session override can supersede the activity-level default.
- 2026-05-04 — **Settings entry point: gear icon on Browse toolbar** (next to
  the existing Filter button). Routes to a `SettingsView` that hosts Share
  Code / Enter Code / Linked Settings / Why-this preview.
- 2026-05-04 — **Onboarding has 3 steps, not 4.** Re-read `v5-onboarding.jsx`:
  the "Welcome" label is just the eyebrow text on step 1 (kids), not a
  separate screen. Keep the existing 3-step structure; re-skin the visuals
  to match the prototype (header style, info cards, day grid).
- 2026-05-04 — **Travel-time uses real MapKit ETA.** Conflict sheet calls
  `MKDirections` async with driving transport type; falls back to "—" if
  the request fails or routing is unavailable. Cache results keyed by
  (origin, destination) for the session so the same pair isn't refetched.
- 2026-05-04 — **Per-kid availability: out of scope for V1.**
  `weeklyAvailability` stays household-level. New prototypes that hint at
  per-kid windows degrade to applying the household value to every kid.
- 2026-05-04 — **Why-this reflects real signals.** `WhyThisSheet` reads from
  `FilterEngine.sort`'s actual ranking inputs (kid match, distance, status,
  recency) for the currently-displayed result list. No copy-only stub.

## Open questions

_(none — all five resolved 2026-05-04)_
