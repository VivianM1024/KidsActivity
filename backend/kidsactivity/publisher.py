"""Serialize crawled data to JSON files served via GitHub Pages.

Writes three files under `<repo>/docs/data/`:
  - manifest.json    : { schema_version, last_updated, counts }
  - venues.json      : array of Venue
  - activities.json  : array of Activity

The iOS app reads these directly via HTTP. Bumping `SCHEMA_VERSION`
signals to the app that it must update its Swift Codable types.
"""

from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from kidsactivity.locator import load_all_venues
from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, Venue

log = get_logger(__name__)

SCHEMA_VERSION = 1


def publish(activities: list[Activity], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)

    venues = load_all_venues()
    venue_type_counts = Counter(v.venue_type.value for v in venues)
    activity_venue_counts = Counter(a.venue_type.value for a in activities)

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "last_updated": datetime.now(tz=timezone.utc).isoformat(),
        "venue_count": len(venues),
        "activity_count": len(activities),
        "venues_by_type": dict(venue_type_counts),
        "activities_by_type": dict(activity_venue_counts),
    }

    _dump(out_dir / "manifest.json", manifest)
    _dump(out_dir / "venues.json", [_to_jsonable(v) for v in venues])
    _dump(out_dir / "activities.json", [_to_jsonable(a) for a in activities])

    log.info(
        "Published %d activities and %d venues to %s",
        len(activities), len(venues), out_dir,
    )


def _to_jsonable(model: Venue | Activity) -> dict:
    """Pydantic mode='json' renders datetimes/dates/HttpUrl as strings."""
    return model.model_dump(mode="json", exclude_none=False)


def _dump(path: Path, payload: object) -> None:
    path.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=False) + "\n"
    )
