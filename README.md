# KidsActivity

A low-cost iPhone app that aggregates kids' activities from Chicago-area
park districts, public libraries, community centers, and museums.

**Architecture (zero server cost):**

1. `backend/` — Python scraper. Runs once a week in GitHub Actions, pulls
   activity catalogs from each venue's registration platform, and writes
   normalized JSON to `docs/data/`.
2. `docs/` — served by GitHub Pages. The JSON files are the API.
3. `ios/` — SwiftUI app. Fetches the JSON on launch, caches locally, and
   does all filtering (age, date, distance, keyword) in-memory.

The data model and three of the scrapers (ActiveNet, WebTrac, Amilia) are
lifted from the user's earlier `personalAgent/agents/park_district`
project. See `/Users/vivian/.claude/plans/apple-app-park-district-twinkly-brook.md`
for the design rationale.

## Backend

```bash
cd backend
pip install -e .
kidsactivity publish        # crawl every venue and write docs/data/*.json
kidsactivity test-scraper --venue chicagoparkdistrict
```

## iOS app

Open `ios/KidsActivity/KidsActivity.xcodeproj` in Xcode. The app fetches
JSON from `https://vivianm1024.github.io/KidsActivity/data/` by default;
override via `Settings.bundle` if you fork.

## Adding a new venue

1. Find the platform (ActiveNet / WebTrac / Amilia / BiblioCommons / ...).
2. Append an entry to `backend/kidsactivity/data/venues.yaml`.
3. If the platform is new, drop a class into
   `backend/kidsactivity/scrapers/` and register it in
   `scrapers/__init__.py::PLATFORM_SCRAPERS`. Subclass `BaseScraper`
   (see `scrapers/base.py`) and implement `search()` plus optionally
   `enrich()`.
