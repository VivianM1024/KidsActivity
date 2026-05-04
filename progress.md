# Progress Log

> Append-only session log. One entry per working session or significant milestone.

## 2026-05-04 — Planning files initialized

- Created `task_plan.md`, `findings.md`, `progress.md` via `/planning-with-files:plan`.

## 2026-05-04 — V5 redesign scope mapped

- Read `design_handoff_v5_hybrid/README.md` end-to-end and skimmed the new
  prototypes (`v5-handoff.jsx`, `v5-conflicts.jsx`, `v5-coparent.jsx`,
  `v5-share.jsx`, `v5-transparency.jsx`, `v5-onboarding.jsx`, `v5-empty.jsx`,
  `v5-loading.jsx`).
- Surveyed `ios/KidsActivity/` — confirmed steps 1, 2, 4, 5, 6, 8, 9, 12 of
  the README's build order are landed; step 3 missing the Welcome step;
  steps 7, 10, 11 not started; co-parent / conflict / transparency surfaces
  not started.
- Wrote phased plan in `task_plan.md` (Phases A–F) and surveyed token gaps in
  `findings.md`. Identified five open questions for the user before code
  starts.

## 2026-05-04 — Phase A.1 complete (tokens)

- All five planning questions answered by the user; decisions recorded in
  `task_plan.md`. Notable: gear-icon Settings entry, MapKit ETA for travel
  time, real signals in Why-this, household-level availability for V1.
- Added amber/partner/danger tokens to `DesignTokens.swift` (both `Color` and
  `ShapeStyle` shorthands).
- Re-read `v5-onboarding.jsx`: prototype is 3 steps, same as existing — no
  extra Welcome screen. Phase A re-scoped to a visual re-skin (A.2 + A.3)
  rather than adding a screen.
- Paused for review before A.2 (onboarding header re-skin).

## 2026-05-04 — Phase A complete (onboarding re-skin)

- A.2: Replaced `OnboardingFlow.progressDots` with `topHeader` (back chevron
  in 32pt round button + 3-segment thin progress bar + `n/3` counter on the
  right). Removed the footer Back button (now in header). Footer collapsed
  to a single full-width terracotta CTA whose label adapts: "Continue with N
  kids" → "Continue" / "Skip for now" → "Find activities" with arrow icon.
  Renamed shared helper from `stepHeader(step:title:subtitle:)` to
  `stepHero(eyebrow:title:subtitle:)`; eyebrow now uses the prototype's
  oklch(0.45 0.13 22) ink, display 28pt with -0.7 kerning.
- A.3 Kids: eyebrow "Welcome", title "Who are we planning for?". Added
  privacy info card with `info.circle` glyph and gold-tinted background
  oklch(0.97 0.025 60).
- A.3 Location: eyebrow "Step 2", title "Where's home?", subtitle reworded
  to match prototype. Upgraded the "Use my current location" CTA from a
  dashed-border button to the prototype's bubble-icon row card (32pt
  terracotta-tinted circle + label + subtitle + chevron).
- A.3 Availability: eyebrow "Step 3", subtitle is kid-aware (uses store.kids
  names if there's exactly one). Day grid is now a 7-col cap-pill layout
  (1:1.1 aspect, letter eyebrow + 3-letter day name, terracotta filled +
  shadowed when on, hairline-bordered when off). Presets row moved below
  the grid; added "You'll see" summary card that collapses Set comparisons
  to friendly labels (Weekends / Weekdays / Any day).
- SourceKit reported a wave of cross-module "cannot find" complaints after
  each edit; verified by re-reading edited files that all referenced
  symbols (ActivityStore, Kid, ActivityFilters, LocationService, color
  tokens) exist in the same module — same as before edits. Treating as
  index lag; will confirm with a real build.

## 2026-05-04 — Build green

- Confirmed: every SourceKit "Cannot find" diagnostic during the Phase A–F
  push was index lag. Real compiler is happy.
- Real cause of the first build break: 13 new Swift files weren't in
  `project.pbxproj`. Patched by hand — added `PBXBuildFile`,
  `PBXFileReference`, group-children, and `Sources` build-phase entries,
  plus four new groups (`Browse`, `Calendar`, `Detail`, `Settings`).
  ID scheme follows the existing `F0001000A1B2C3D4E5F6XXXX` pattern.
- `xcodebuild -scheme KidsActivity -sdk iphonesimulator -destination
  'platform=iOS Simulator,name=iPhone 16' build` → **BUILD SUCCEEDED**,
  no errors or warnings (unrelated AppIntents metadata noise aside).
- The wordField-chain "type-check timeout" warning never showed up at
  build time — must have been a SourceKit artifact too.

## 2026-05-04 — Phases C/D/E/F shipped in one push

User asked to skip pause-points and run Phases C through F to completion.

**Phase C — co-parent foundation.**
- `Models/Parent.swift` — `Parent`, `AssignmentKind` (tagged-union Codable),
  `Assignment`, `LinkedParent`, `InviteCode.generate()/.isValid(_:)`.
- `ActivityStore` extension: `linkedParent`, `assignments`,
  `assignment(for:on:)`, `setAssignment / clearAssignment`,
  `linkPartner / unlinkPartner`, `loadSummaryThisWeek()`. Persisted via
  `StoreSnapshot`.
- `Views/Components/ParentChip.swift` — shared mini-avatar (both / solo /
  split / unassigned).
- Settings cluster: `SettingsView` (hub), `ShareCodeView` (code + share +
  what-you-share rows + privacy note), `EnterCodeView` (3 inputs, paste,
  link preview, partner-blue focus ring), `LinkedSettingsView` (partner
  hero, real `loadSummaryThisWeek`, log, unlink alert), `LinkedLoadView`
  (parity artboard, currently a stub).
- Browse gear-icon toolbar entry → SettingsView sheet.

**Phase D — Detail/Calendar co-parent surfaces.**
- `Views/Detail/WhosGoingSection.swift` — collapsed ghost row by default;
  expanded picker (Both / Solo / Split) writes `Assignment` to the store.
  Only renders when `linkedParent != nil`.
- `CalendarView` parent filter strip (All / Mine / partner's / Both) with
  counts. Renders only when at least one assignment exists.
- `DayEventCard` shows a `ParentChip` on the right when an assignment is
  set; resolves Solo/Both/Split variants correctly.

**Phase E — Conflict detection + ResolveConflictSheet.**
- `ActivityStore.Conflict` + `conflicts(on:)` + `conflictDayKeys`. Sorted-
  pair overlap sweep, O(n²) per day but n is tiny.
- `Services/TravelTimeService.swift` — `MKDirections` async ETA with a
  session cache keyed on rounded lat/lon.
- Month-cell yellow ring + amber dot for conflict days; day-block pill
  replaces event count with "N conflict" when applicable.
- `Views/Calendar/ResolveConflictSheet.swift` — stacked timeline (kid-color
  bars, overlap stripe), real travel-time row, three options (skip,
  split-with-partner when linked, cancel). Sheet routes from the day-block
  pill via `resolveConflict: ActivityStore.Conflict?` state.

**Phase F — Why-this + skeletons + cached banner.**
- `Views/Browse/WhyThisSheet.swift` — six rules driven by real
  `ActivityFilters` state + the top-ranked activity. Met rules sage,
  non-applicable rules struck through with a `·0` chip. Ring sums met
  weights.
- "Why these?" info-button wired next to the result count in BrowseView.
- `Views/Components/SkeletonViews.swift` — `Bone` (TimelineView pulse),
  `BrowseSkeletonView`, `CalendarSkeletonView`, `CachedBanner`.
- ContentView's loading state now renders `BrowseSkeletonView` instead of
  a spinner so the layout doesn't pop in.

**Deferred (non-blocking).**
- `CachedBanner` view exists but isn't auto-wired to network state — would
  need a "served from cache" signal on `DataLoader`.
- Saved + Calendar empty states retain their existing minimal copy.
  `EmptyIllSearch` / `EmptyIllBookmark` / `EmptyIllCalendar` SVGs from
  `v5-empty.jsx` aren't ported as SF Symbols won't match them — would need
  custom Path drawing to be faithful, low ROI for V1.

**SourceKit noise throughout.** Every edit triggered cross-module "Cannot
find type" complaints (ActivityStore, Kid, Activity, Parent, color tokens,
Formatters, etc.). All those symbols exist in the same Swift module and
were already referenced elsewhere; treating as index lag. There was one
legitimate warning on `EnterCodeView.swift` line 101 (wordField type-check
timeout); leaving for now since it's a complex SwiftUI modifier chain that
the compiler may handle once cross-file symbols resolve. If a real build
flags it, the fix is splitting the chain into a helper view.

## 2026-05-04 — Phase B complete (registration handoff)

- Created `Views/RegistrationHandoffSheet.swift` matching `v5-handoff.jsx`:
  hero with "HEADS UP" eyebrow + 24pt display title; activity summary card
  (40pt category swatch + name + day-time/price); "You'll need" card with
  rows for the primary kid (with COPY chip backed by UIPasteboard), payment,
  and host account (each with a 28pt colored icon bubble); "What happens"
  3-step list with terracotta active circle + warm-card outlined inactive
  circles + 1.5px vertical connecting line; sticky footer with terracotta
  "Open {host}" → SafariView and a secondary "Already done? I registered"
  link that calls `store.toggleRegistered` then dismisses.
- Wired into `ActivityDetailView`: added `showHandoff` state and a sheet
  modifier; the primary CTA routes through the handoff only when status is
  `.open`. Drop-in / opens-soon / full / closed states keep going straight
  to Safari since their CTA labels (Remind me / Join waitlist / View
  listing) aren't a registration moment.
- Initially imported UIKit explicitly for `UIPasteboard`; SourceKit flagged
  "No such module 'UIKit'". Removed the explicit import — convention in this
  codebase is `import SwiftUI` only (SwiftUI re-exports UIKit symbols on
  iOS, as in `SavedView.swift` which uses `UIBezierPath` the same way).
