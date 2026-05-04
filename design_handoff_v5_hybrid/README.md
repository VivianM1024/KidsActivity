# Handoff: KidsActivity — V5 "Warm Hybrid" Front-end

## Overview

A redesign of the KidsActivity iOS app's front-end. V5 keeps the dense
information of the existing list view but replaces the system-default
SwiftUI chrome with a warm, editorial visual language tuned for parents
quickly triaging kids' activities across multiple kids.

The redesign covers the following surfaces:

**Core screens**
1. **Browse** (`v5-hybrid.jsx`) — main feed. Search, kid picker (multi-select), category chip rail, sort control, dense list of activity rows.
2. **Filters** (`v5-filter.jsx`) — bottom sheet. Primary filters (kids, ages, distance, days) inline; advanced filters (price, registration, venue type, category) collapsed under "More filters".
3. **Saved** (`v5-saved.jsx`) — parent's shortlist, split into "Considering" vs "Registered". Each row shows which kid it's for.
4. **Calendar** (`v5-calendar.jsx`) — month strip + day-grouped agenda of registered events. Cards are color-accented by kid.
5. **Activity Detail** (`v5-detail.jsx`) — full activity view with schedule, location, pricing, registration CTA.

**First-launch + onboarding**
6. **Onboarding** (`v5-onboarding.jsx`) — three-step flow: welcome → add kids (name + age + color) → set ZIP / distance.

**Empty / loading / error states**
7. **Empty states** (`v5-empty.jsx`) — no matches, saved empty, calendar empty.
8. **Loading skeletons** (`v5-loading.jsx`) — Browse list and Calendar agenda shimmer.
9. **Cached banner** (`v5-empty.jsx::V5BrowseCached`) — inline strip on Browse when offline.

**Registration & external handoff**
10. **Registration handoff** (`v5-handoff.jsx`) — bridge sheet that warns the user before deep-linking to the venue's external registration site.

**Coordination**
11. **Conflict detection** (`v5-conflicts.jsx`) — Calendar shows overlapping events with a "Resolve" pill; the resolve sheet offers move-time, choose-one, or split-between-parents.
12. **Co-parent assignments** (`v5-coparent.jsx`) — opt-in feature for linked parents. Detail page has a collapsed "+ Add Sam to this activity" row by default; expanded picker offers Both / Just one / Split kids modes. Calendar shows parent chips only on assigned events; filter strip appears only after at least one assignment exists.
13. **Share / link parents** (`v5-share.jsx`) — generate code to invite a co-parent, enter their code, view the linked-state settings.
14. **Why this?** (`v5-transparency.jsx`) — sort transparency overlay explaining ranking signals.

## About the design files

The HTML/JSX files in `design/` are **design references**, not production
code. They are a React + inline-styles prototype rendered inside an iOS
device frame at 393×852 (iPhone 15 logical points). The task is to
**recreate these designs in the existing SwiftUI codebase** at
`ios/KidsActivity/`, using its established patterns:

- `@Observable` `ActivityStore` for state (already in place)
- `Activity` / `Venue` / `Manifest` Codable models (already in place)
- SwiftUI `NavigationStack`, sheets, `List`/`ScrollView` for layout
- SF Symbols for iconography (the prototype uses inline SVG placeholders)

Do NOT ship the HTML. Do NOT introduce React Native, web views, or a
new framework. The existing app structure (`ContentView` →
`ActivityListView` → `ActivityDetailView`, with a `FilterSheet`) is the
right scaffold; this redesign replaces those views' bodies plus adds two
new tabs (Saved, Calendar).

## Fidelity

**High-fidelity.** Colors, type scale, spacing, and component anatomy
are intended to be matched closely. The one exception: where the
prototype uses inline SVG glyphs, use the closest SF Symbol instead
(noted per-component below).

## Open the prototype

`design/KidsActivity Front-end.html` is the entry point. Open it in a
browser to see all four screens laid out side-by-side on a design
canvas, each in an iOS frame. You can drag-reorder, fullscreen any
artboard, and toggle a few tweaks (kid color accent etc.) via the
toolbar.

The Browse screen is `v5-hybrid.jsx`; Filters `v5-filter.jsx`; Saved
`v5-saved.jsx`; Calendar `v5-calendar.jsx`; Detail `v5-detail.jsx`.
Onboarding `v5-onboarding.jsx`; empty/cached states `v5-empty.jsx`;
loading shimmer `v5-loading.jsx`; registration bridge `v5-handoff.jsx`;
conflict resolution `v5-conflicts.jsx`; share/link `v5-share.jsx`;
sort transparency `v5-transparency.jsx`; co-parent assignments
`v5-coparent.jsx`. Shared mock data + label helpers are in
`activities.jsx`.

---

## Design tokens

### Colors

| Token | Hex / OKLCH | Use |
|---|---|---|
| `surface.canvas` | `#FBF7F1` | Screen background — warm off-white |
| `surface.card` | `#FFFFFF` | Row / card background |
| `surface.subtle` | `rgba(60,40,20,0.05)` | Pressed state, dividers |
| `text.primary` | `#26201A` | Headlines, primary copy |
| `text.secondary` | `#5B4F3F` | Secondary copy |
| `text.tertiary` | `#7A6D5C` | Meta / supporting copy |
| `text.muted` | `#8B7E6E` | Placeholder text |
| `text.faint` | `#A89B86` | Section labels, faint dates |
| `border.hairline` | `rgba(60,40,20,0.06)` | Card outline (0.5px) |
| `border.subtle` | `rgba(60,40,20,0.12)` | Chip / button outlines |
| `accent.terracotta` | `oklch(0.55 0.13 22)` | Primary CTAs, "Export", filter pill |
| `success.registered` | `oklch(0.55 0.15 145)` | Registered / open-registration green |
| `success.bg` | `oklch(0.94 0.07 145)` | Registered chip background |

### Category hues (per `CATEGORY_META` in `activities.jsx`)

Each category has a single OKLCH hue; the swatch and chip apply
lightness/chroma combos around it. SwiftUI implementation: define a
`CategoryStyle` with `(swatchBG, swatchFG, chipBG, chipFG)` per
category.

| Category | Hue | Short |
|---|---|---|
| Sports | 22 (terracotta) | SPO |
| Arts | 290 (lavender) | ART |
| STEM | 200 (teal) | STE |
| Storytime | 60 (gold) | STO |
| Events | 145 (sage) | EVT |
| Music | 320 (rose) | MUS |
| Outdoors | 130 (green) | OUT |

Computed shades:
- Swatch background: `oklch(0.88 0.07 H)`
- Swatch / chip foreground: `oklch(0.32 0.13 H)`
- Chip background: `oklch(0.92 0.07 H)`

### Kid colors

Each kid has an OKLCH hue used everywhere their activities appear
(saved row left border, calendar card left border, kid avatar,
match-dots on browse rows). Avatar = circle filled with
`oklch(0.6 0.14 H)`, white initial. Pill background when selected =
`oklch(0.95 0.06 H)`.

| Kid | Hue | Initial |
|---|---|---|
| Maya | 22 | M |
| Leo | 250 | L |
| Nora | 320 | N |

In production, kids come from the user's profile — provide a small
palette of 6–8 OKLCH hues and assign in profile-creation order.

### Typography

System font (`-apple-system, system-ui` on web → SF Pro on iOS).

| Style | Size / weight / tracking | Use |
|---|---|---|
| `display` | 28 / 700 / -0.6 | Screen titles ("May 2026", "Saved") |
| `eyebrow` | 11 / 600 / +0.5 / UPPERCASE | Above-title meta ("3 KIDS · 7 SAVED") |
| `headline` | 14 / 600 / -0.2 | Activity name on rows |
| `body` | 13 / 400 | Body copy in detail views |
| `meta` | 11–12 / 400 | Row meta line |
| `caption` | 10–11 / 700 / +0.3 / UPPERCASE | Badges, tab labels |
| `tabular` | numeric, `font-variant-numeric: tabular-nums` | Prices, distances, durations |

### Spacing & radii

- Screen horizontal padding: 16–20pt
- Card / row padding: 10pt
- Row gap between siblings: 6pt
- Card corner radius: 12pt (rows), 14pt (containers like month strip)
- Avatar / swatch corner radius: 9pt (square), 50% (circle)
- Bottom tab bar: 64pt tall, sits above 34pt safe-area inset

### Shadows & strokes

Cards use a "shadow + hairline stroke" combination, not just a shadow:

```
boxShadow: '0 1px 2px rgba(60,40,20,0.03), 0 0 0 0.5px rgba(60,40,20,0.05)'
```

In SwiftUI: `.shadow(color: .black.opacity(0.03), radius: 1, y: 1)` and
`.overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 0.5))`.

---

## Screens

### 1. Browse (`v5-hybrid.jsx`)

**Layout (top-down):**

1. **Status bar** (provided by `ios-frame.jsx`).
2. **Title block** — left-aligned 56pt below top inset.
   - Eyebrow: "12 ACTIVITIES IN MAY"
   - Display title: "Find something for the kids."
3. **Search + kid picker** — 12pt below title.
   - Search field: 9pt vertical / 12pt horizontal, white background,
     hairline shadow, magnifying-glass icon, placeholder
     "Soccer, art, swim…"
   - Below the field, a row of kid pills. Label `For` (uppercase
     eyebrow) + one pill per kid. Selected pill: kid-tinted
     background, kid-tinted border, 700-weight name. Unselected:
     white background, subtle border, neutral text. Tapping toggles
     inclusion.
4. **Category chip rail** — horizontally scrollable; first chip is
   "All"; rest map to `CATEGORY_META`. Selected chip: dark fill
   (`#26201A`), white text. Unselected: white background, hairline
   border.
5. **Sort + result count row** — left: count ("9 results"), right:
   sort segmented control with 3 short options (Best, Soonest, Closest).
6. **Activity list** — each row is a `V5Row`.

**`V5Row` anatomy** (40pt swatch + flex content + price):

- 40×40 swatch on the left:
  - Filled `oklch(0.88 0.07 H)` (category hue)
  - Three-letter category short, weight 700, in
    `oklch(0.32 0.13 H)`
  - Top-right corner: 14×14 black circle (`#26201A`) with a single
    white letter (P=park, L=library, M=museum, C=community center).
    Border 1.5px white to lift it off the swatch.
- Body:
  - Line 1: activity name (14/600, line-clamp 1) + price (13/700,
    tabular-num, right-aligned).
  - Line 2: meta — bold day+time, then `·` separators for age,
    venue (clamped), distance.
  - Line 3: badges + per-kid match dots.
    - Match dots: one 14pt kid-colored circle with their initial,
      per kid that the activity fits. Use ±1y age window.
    - "SERIES · N×" badge for multi-session courses (lavender);
      "ONE-TIME" for single events (teal).
    - "DROP-IN" / "OPEN" / "OPENS Mar 1" status badge.
    - Optional "QUIET HOUR" flag when applicable.

**Empty state**: when filters yield 0 results, show centered "Nothing
matches that combination." plus a "Clear filters" link.

**Tab bar** (fixed bottom): Browse / Saved / Calendar (4 icons + labels).

### 2. Filter sheet (`v5-filter.jsx`)

A bottom sheet at ~85% viewport height with rounded top corners.
Title row: "Filters" + count of active filters + "Reset" link on the
right.

Sections (top to bottom):

1. **Kids** — list of all kids. Each row shows the avatar (32pt
   circle), name + age, with a kid-color left border when selected
   and a checkbox on the right. Multi-select.
2. **Ages** — segmented toggle: "Use kids' ages" vs "Manual range".
   - In "Use kids' ages" mode, render one mini track per selected
     kid showing their `[ageYears-1, ageYears+1]` window inside a
     0–18 scale, kid-colored. Right side shows the numeric range.
   - In "Manual range" mode, show a `RangeRow` (low/high stepper).
3. **Distance** — single slider, 1–25 mi.
4. **Registration** — segmented control: Open · Opens soon · Any.
5. **Price** — segmented: Free · ≤ $25 · ≤ $100 · Any.
6. **Days** — Mon–Sun pill row. Toggleable.
7. **Venue type** — three checkboxes with venue letters.
8. **Categories** — multi-select chips identical to Browse.

**Footer** (sticky): "Show 9 results" CTA in `accent.terracotta`,
full-width.

**Active-filter summary** at top of sheet (read-only): "Maya + Leo ·
within 5 mi · weekends · registration open" — built from selected kids
and current settings.

### 3. Saved (`v5-saved.jsx`)

- Title block: eyebrow "3 KIDS · 7 SAVED", display "Saved", subtitle
  "Confirm the ones you actually registered for — they'll show up on
  your Calendar."
- **Summary strip**: two `SummaryPill`s side-by-side — "Considering
  N · still deciding" (white) and "Registered N · on calendar"
  (sage-tinted).
- **Section: Considering** — rows of saved-but-not-confirmed
  activities. Each row has a "I REGISTERED" pill button on the right.
- **Section: Registered** — confirmed rows with a green check pill.

`SavedRow` matches `V5Row` but adds a 3px **kid-colored left border**
and a 16pt kid avatar before the activity name.

### 4. Calendar (`v5-calendar.jsx`)

- Title: eyebrow "N UPCOMING", display "May 2026", with an "Export"
  button on the right (opens an inline menu with Apple Calendar /
  Google Calendar / .ics download options).
- **Month strip** — 7-col grid, S–S header, then days. Today's cell
  is filled with terracotta. Days with events get a 4pt sage dot
  beneath the number.
- **Day groups** — each day section has:
  - Big tabular day number + weekday name + date below it
  - Hairline divider with event count on the right
  - One `V5DayEvent` per event, rendered as:
    - Left gutter: time (13/700, tabular-num) + duration (10pt)
    - Card with **kid-colored 3px left border**:
      - Row 1: 18pt kid avatar (initial) + uppercase category chip
        (in category hue) + activity name (truncated)
      - Row 2: location pin icon + venue name (caption color)
      - Row 3 (optional): note (e.g. "Session 3 of 8").

### 5. Activity Detail (`v5-detail.jsx`)

(See file for full layout — hero with category-tinted band, schedule
table, location with map placeholder, price/registration CTA, "Save"
toggle, deep-link to source URL. Lower priority for V1 of the redesign.)

---

## Interactions

- **Search field** is debounced (300ms) before filtering.
- **Kid picker** above the list and **Kids section** in filter sheet
  share the same selection state — selecting Maya in the picker
  pre-selects her in the sheet and vice versa.
- **Sort** has three modes; default is "Best" (relevance to selected
  kids). "Soonest" sorts by `schedule.startDate`. "Closest" sorts by
  user→venue distance (placeholder; the existing app does not yet
  compute distance — leave as a TODO).
- **Confirm registration** in Saved is a local-only flag for now; the
  app does not actually register the user. Persist to `UserDefaults`
  or SwiftData. Once confirmed, the activity's first N sessions
  expand into `CalendarEvent`s and appear on the Calendar tab.
- **Export** menu options:
  - "Add to Apple Calendar" — generate `.ics` and present the
    iOS `EKEventEditViewController` for each event, OR write the
    events directly via `EKEventStore` with user permission.
  - "Add to Google Calendar" — open Google's web template URL
    (`https://www.google.com/calendar/render?action=TEMPLATE&...`)
    in `SFSafariViewController`.
  - "Download .ics" — write a multi-event `.ics` file and
    present a share sheet.

## State management

The existing `ActivityStore` already owns `activities`, `manifest`,
`filters`, and a derived `filteredActivities`. Extend it with:

```swift
@Observable
final class ActivityStore {
    // existing
    var activities: [Activity] = []
    var manifest: Manifest?
    var filters: ActivityFilters = .default
    var state: LoadState = .idle

    // NEW
    var kids: [Kid] = []                       // user's kids
    var selectedKidIds: Set<Kid.ID> = []       // multi-select for filtering
    var savedActivityIds: Set<Activity.ID> = []
    var registeredActivityIds: Set<Activity.ID> = []
    var calendarEvents: [CalendarEvent] = []   // generated from registered activities
    var sortMode: SortMode = .best             // best | soonest | closest

    func toggleSaved(_ a: Activity) { ... }
    func toggleRegistered(_ a: Activity) { ... }
    func matchKids(for a: Activity) -> [Kid] { ... }   // ±1y age window
}
```

```swift
struct Kid: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var ageYears: Int
    var hue: Double          // 0–360, OKLCH H component
    var initial: String { String(name.prefix(1)) }
}

struct CalendarEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let activityId: Activity.ID
    let kidId: Kid.ID
    let date: Date
    let durationMinutes: Int
    var note: String?
}
```

Persistence: use SwiftData (preferred for iOS 17+) or
`UserDefaults` + JSON for kids, saved set, registered set,
generated events.

### New models for additional surfaces

```swift
// Co-parent assignment (v5-coparent.jsx)
struct Parent: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var initial: String
    var hue: Double           // 0\u2013360 OKLCH H
    var role: Role            // .you | .partner
}

enum AssignmentKind: Codable {
    case both                                    // both parents going
    case solo(parentId: Parent.ID)               // one parent takes both kids
    case split(byKid: [Kid.ID: Parent.ID])       // different parents per kid
}

// Persisted per (activity, session) or per activity if "apply to all sessions"
struct Assignment: Codable, Hashable {
    var activityId: Activity.ID
    var sessionDate: Date?      // nil \u2192 default for all sessions
    var kind: AssignmentKind
}

// Linked-parent state (v5-share.jsx)
struct LinkedParent: Codable {
    var partner: Parent
    var inviteCode: String      // e.g. "maple-otter-39"
    var linkedAt: Date
}
```

The Calendar parent-filter bar and the Settings load summary are
**both opt-in surfaces**: only render the filter bar when at least
one event has an `Assignment`; only show the load summary inside
the linked-state Settings screen (never push notifications about it).

## Suggested implementation order

1. **Tokens** \u2014 add a `DesignTokens.swift` with `Color` extensions
   (warmCanvas, warmText, terracotta, sageRegistered) and a
   `CategoryStyle` lookup. Add `Kid` model + sample data.
2. **TabView shell** \u2014 three tabs, placeholder views.
3. **Onboarding flow** (`v5-onboarding.jsx`) \u2014 welcome \u2192 add kids \u2192
   set ZIP. Drives initial `kids` array and home location.
4. **BrowseView** \u2014 port `v5-hybrid.jsx` row by row. Start with
   static mock data, then wire to `store.filteredActivities`.
   Add empty + skeleton + cached-banner states from `v5-empty.jsx`
   and `v5-loading.jsx`.
5. **FilterSheet** rewrite \u2014 keep the existing `@Bindable store`
   pattern, change layout. Primary filters inline, advanced filters
   collapsed under "More filters".
6. **Activity detail** \u2014 redesign + add the collapsed "+ Add Sam"
   row from `v5-coparent.jsx::V5DetailWhosGoing` (only renders when
   user has a linked partner).
7. **Registration handoff sheet** (`v5-handoff.jsx`) \u2014 confirm-then-
   open-Safari pattern. Persist "I registered" flag locally.
8. **SavedView** \u2014 straightforward; depends on `store.savedActivityIds`
   and a `kidId` per saved item.
9. **CalendarView** \u2014 month strip + day groups. Then add conflict
   detection (`v5-conflicts.jsx`) + parent-filter bar
   (`v5-coparent.jsx::V5CalendarByParent`).
10. **Share / link parents** (`v5-share.jsx`) \u2014 generate / enter code
    flow, linked settings with load summary
    (`v5-coparent.jsx::V5LinkedLoad`).
11. **Why this?** sort transparency (`v5-transparency.jsx`) \u2014 small
    sheet, low priority but high trust impact.
12. **Export** \u2014 `.ics` generation utility + Apple Calendar
    integration via `EventKit`.

## File map (where each design lives)

| Design file | Implements | Maps to in iOS |
|---|---|---|
| `v5-hybrid.jsx` | Browse screen | `Views/BrowseView.swift` (replaces `ActivityListView`) + `Views/Components/ActivityRow.swift` (replaces `ActivityRowView`) |
| `v5-filter.jsx` | Filter sheet | `Views/FilterSheet.swift` (replace contents) |
| `v5-saved.jsx` | Saved tab | `Views/SavedView.swift` (new) + `Views/Components/SavedRow.swift` (new) |
| `v5-calendar.jsx` | Calendar tab | `Views/CalendarView.swift` (new) + `Views/Components/DayBlock.swift`, `DayEvent.swift` |
| `v5-detail.jsx` | Activity detail | `Views/ActivityDetailView.swift` (replace contents) |
| `v5-onboarding.jsx` | First-launch flow | `Views/Onboarding/WelcomeView.swift`, `AddKidsView.swift`, `LocationView.swift` (new) |
| `v5-handoff.jsx` | Registration bridge sheet | `Views/RegistrationHandoffSheet.swift` (new) — opens `SFSafariViewController` after confirmation |
| `v5-empty.jsx` | Empty / cached states | Inline empty views inside Browse / Saved / Calendar; `V5BrowseCached` → cached banner above list |
| `v5-loading.jsx` | Skeleton shimmer | Redacted-style placeholder views for Browse / Calendar; show during `store.state == .loading` |
| `v5-share.jsx` | Co-parent invite + linked settings | `Views/Settings/ShareCodeView.swift`, `EnterCodeView.swift`, `LinkedSettingsView.swift` (new) |
| `v5-conflicts.jsx` | Calendar conflict detection + resolve sheet | Conflict computation in `ActivityStore`; `Views/Calendar/ConflictBadge.swift` and `ResolveConflictSheet.swift` (new) |
| `v5-transparency.jsx` | Sort transparency overlay | `Views/Browse/WhyThisSheet.swift` (new) — bottom sheet shown from a "Why these?" link near the sort control |
| `v5-coparent.jsx` | Per-activity parent assignment + filtered Calendar + load summary | `Views/Detail/WhosGoingSection.swift`, `Views/Calendar/ParentFilterBar.swift`, `Views/Settings/LinkedLoadView.swift` (new) |
| `activities.jsx` | Mock data + helpers | Data already in `Activity.swift`. Helpers (`priceLabel`, `daysLabel`, `ageRangeLabel`) port to a `Formatters` extension. New: `PARENTS`/`Assignment` model. |

## Top-level navigation

Replace the current single-stack `NavigationStack` with a `TabView`:

```swift
TabView {
    BrowseView()
        .tabItem { Label("Browse", systemImage: "magnifyingglass") }
    SavedView()
        .tabItem { Label("Saved", systemImage: "bookmark") }
    CalendarView()
        .tabItem { Label("Calendar", systemImage: "calendar") }
}
```

Each tab embeds its own `NavigationStack` so deep-linking into
`ActivityDetailView` works from any tab.

## Suggested implementation order

## Notes

- The prototype has no real distance data; the row shows `1.2 mi`
  etc. as placeholders. The iOS app should compute distance from
  `CLLocationManager` + venue coordinates (which would need to be
  added to the `Venue` model and backend scrape).
- The prototype shows three hardcoded kids (Maya/Leo/Nora). In
  production, kids come from a user-managed profile section
  (out of scope for this redesign — assume a settings screen
  exists or build a minimal "Add a kid" flow).
- "OPENS Mar 1" / drop-in / open status is derived from
  `activity.registration` plus `today`. Logic is already in
  `activities.jsx::statusLabel`; port to Swift.
- The bottom tab bar in the prototype is custom; in SwiftUI use
  the native `TabView` instead — do not recreate the custom bar.
