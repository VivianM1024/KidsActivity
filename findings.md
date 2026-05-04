# Findings — V5 redesign survey

## Codebase state vs. README

The first batch of V5 surfaces is already implemented. Cite-paths below.

### Tokens — fully in place
- OKLCH conversion + warm palette: `ios/KidsActivity/KidsActivity/Views/DesignTokens.swift:6`
- `CategoryStyle` lookup (swatchBG/FG, chipBG/FG, dot, border): `DesignTokens.swift:122`
- `Kid` style extensions (avatarColor, pillBG, deepText): `DesignTokens.swift:138`
- Typography scale (`v5Display` … `v5Tabular`): `DesignTokens.swift:186`
- Card surface modifier (`.warmCard`): `DesignTokens.swift:163`

**Missing tokens** (needed for new prototypes):
- Amber / warning — `v5-conflicts.jsx::CFLT.warn` `oklch(0.62 0.14 70)`,
  `warnSoft` `oklch(0.96 0.05 70)`, `warnInk` `oklch(0.42 0.14 70)`. Also
  consumed by `v5-transparency.jsx`.
- Partner blue — `v5-share.jsx::SHARE_PALETTE.partner` `oklch(0.55 0.14 250)`,
  `partnerSoft` `oklch(0.94 0.05 250)`. Consumed by `v5-coparent.jsx`.
- Danger red — `v5-share.jsx` line 609 `oklch(0.5 0.18 25)`,
  `oklch(0.95 0.05 25)`. Consumed by the "Disconnect" / "Cancel one"
  destructive options.

### Already-done surfaces (so don't rebuild)
- TabView shell: `Views/ContentView.swift:42` (`V5TabView`).
- Browse: `Views/ActivityListView.swift:6` (`struct BrowseView`). Includes
  search debounce, kid pills, venue type segmented bar, category chips,
  kind+sort row, empty state, `ActivityRow` row anatomy.
- Filter sheet: `Views/FilterSheet.swift` — full active-summary, kids, ages
  (kid windows + manual), distance slider, days, price, registration, venue
  type, categories. Sticky "Show N results" CTA.
- Saved: `Views/SavedView.swift` — Considering / Registered split, summary
  pills, `SavedRow` with kid-colored left bar.
- Calendar: `Views/CalendarView.swift` — month strip, day groups,
  `DayBlock`/`DayEventCard`, export menu (.ics + EventKit + Google Safari),
  toast + Undo.
- Detail: `Views/ActivityDetailView.swift` — hero band, key facts grid,
  status banner, schedule preview, location placeholder, host card, source
  card, terracotta CTA.
- Onboarding: `Views/Onboarding/OnboardingFlow.swift` (3 steps:
  Kids → Location → Availability) — **no Welcome step yet** (prototype
  starts with one).

### State already in `ActivityStore`
- `kids`, `selectedKidIds`, `savedActivityIds`, `registeredActivityIds`,
  `calendarEvents`, `savedKidByActivity`: `ViewModels/ActivityStore.swift:28`.
- `homeCoordinate`, `homeZIP`, `weeklyAvailability` + onboarding gate:
  `ActivityStore.swift:39`.
- Persistence snapshot: `ActivityStore.swift:331` (`StoreSnapshot` /
  `StorePersistence`) — UserDefaults + JSON.
- `matchKids(for:)` already implements the ±1y window: `ActivityStore.swift:100`.
- Calendar event expansion (8-week cap): `ActivityStore.swift:253`.

### What's not yet wired up
- No `Parent`, `Assignment`, `LinkedParent` models anywhere.
- No `linkedParent` or `assignments` on `ActivityStore`.
- No Welcome step in `OnboardingFlow.swift` — prototype's `v5-onboarding.jsx`
  has 4 steps (welcome, kids, ZIP, days), existing has 3.
- Detail CTA opens `SafariView` directly (`ActivityDetailView.swift:62`); no
  bridge sheet.
- Calendar has no conflict detection, no parent filter bar, no parent chips.
- No `WhyThisSheet`, no cached banner, no skeleton shimmer.

## Naming + layout conventions to match
- One-struct-per-file is the norm; row/card sub-views share the file
  with their list (e.g. `SavedRow` lives in `SavedView.swift`).
- Helper formatters live in `Services/Formatters.swift`.
- `@Bindable var store = store` shadow inside `body` is the established
  pattern for binding into the `@Observable` store.
- Prefer `Color.warmCard`, `.terracotta`, etc. via `ShapeStyle` extensions
  rather than calling `oklch(...)` inline — `DesignTokens.swift:51` adds
  these conveniences.
- Inline `oklch(L,C,H)` is reserved for one-off tints (e.g. eyebrow text in
  `BrowseView.titleBlock`). Don't introduce new color literals; route them
  through the token file.

## Prototype-specific details to remember
- `v5-handoff.jsx` "Things you'll need" section uses **COPY** chips next to
  the kid's name field — implement with `UIPasteboard.general.string = …`.
- `v5-conflicts.jsx::ConflictGroup` stitches two events into one rounded
  rectangle with a yellow rail; resolve sheet uses a timeline rendered with
  GeometryReader (1.5px per minute → easy in SwiftUI with `.frame(width:)`).
- `v5-coparent.jsx` has three assignment modes: **Both / Solo / Split**.
  `Split` lets the user assign each kid independently; the picker collapses
  back to summary form when not editing.
- `v5-share.jsx` invite codes follow `<word>-<word>-<digits>` pattern.
  Generation can be local-only for V1 (no backend); store as a string.
