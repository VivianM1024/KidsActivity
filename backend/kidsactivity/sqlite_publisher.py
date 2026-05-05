"""Build the SQLite mirror of activities.json for the iOS app.

The iOS client switched from "decode every record into [Activity]" to
"download activities.db and query rows on demand". Schema below is
the contract: top-level columns are the fields the app filters/sorts on,
and the full record JSON lives in `payload` so the client can still
construct an Activity struct on the row side.

Adding a new filter dimension = add a column + an index here, decode
the column on the iOS side, extend the query.
"""

from __future__ import annotations

import gzip
import json
import sqlite3
from pathlib import Path

from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, Venue

log = get_logger(__name__)


# Mirrored from ios/.../Models/Kid.swift::ActivityCategory.infer.
# Order matters — earlier rules win.
_RAW_RULES: list[tuple[str, list[str]]] = [
    ("music", ["music", "band", "choir", "orchestra"]),
    ("outdoors", ["outdoor", "hike", "nature", "garden", "trail"]),
    ("sports", ["sport", "aquat", "swim", "camp"]),
    ("storytime", ["story", "read"]),
    ("stem", ["stem", "science", "tech", "robot", "engineer"]),
    ("arts", ["art", "paint", "draw", "dance", "theater", "theatre"]),
    ("events", ["event", "festival", "family"]),
]
_NAME_RULES: list[tuple[str, list[str]]] = [
    ("music", ["music", "band", "choir", "orchestra", "guitar", "piano", "drum"]),
    ("outdoors", ["outdoor", "hike", "nature", "garden", "trail", "forest"]),
    ("sports", [
        "soccer", "football", "ball", "hockey", "swim",
        "tennis", "yoga", "fitness", "karate", "gym",
    ]),
    ("stem", ["lego", "robot", "code", "stem", "rocket", "science"]),
    ("storytime", ["story", "read", "book"]),
    ("arts", ["art", "paint", "draw", "dance", "ballet", "theater", "theatre"]),
]


def _infer_category(a: Activity) -> str:
    raw = ((a.category or "") + " " + (a.raw_category or "")).lower()
    name = a.name.lower()
    for cat, needles in _RAW_RULES:
        if any(n in raw for n in needles):
            return cat
    for cat, needles in _NAME_RULES:
        if any(n in name for n in needles):
            return cat
    return "events"


def _kind(a: Activity) -> str:
    n = a.schedule.num_sessions
    return "series" if n is not None and n > 1 else "oneTime"


def _lowest_price(a: Activity) -> float | None:
    if a.price.resident_price is not None:
        return a.price.resident_price
    return a.price.non_resident_price


_SCHEMA = """
CREATE TABLE activities (
    activity_id        TEXT PRIMARY KEY,
    name               TEXT NOT NULL,
    venue_slug         TEXT NOT NULL,
    venue_type         TEXT NOT NULL,
    venue_name         TEXT NOT NULL,
    venue_lat          REAL,
    venue_lon          REAL,
    inferred_category  TEXT NOT NULL,
    start_date         TEXT,
    end_date           TEXT,
    age_min_months     INTEGER,
    age_max_months     INTEGER,
    lowest_price       REAL,
    kind               TEXT NOT NULL,
    reg_is_open        INTEGER,
    reg_opens_at       TEXT,
    num_sessions       INTEGER,
    payload            TEXT NOT NULL
);
CREATE INDEX idx_start_date ON activities(start_date);
CREATE INDEX idx_age        ON activities(age_min_months, age_max_months);
CREATE INDEX idx_category   ON activities(inferred_category);
CREATE INDEX idx_venue_type ON activities(venue_type);
CREATE INDEX idx_geo        ON activities(venue_lat, venue_lon);

CREATE TABLE activity_days (
    activity_id TEXT NOT NULL,
    day_of_week TEXT NOT NULL,
    PRIMARY KEY (activity_id, day_of_week)
);
CREATE INDEX idx_day ON activity_days(day_of_week);

CREATE VIRTUAL TABLE activities_fts USING fts5(
    activity_id UNINDEXED,
    name, venue_name, category, raw_category, description, location,
    tokenize='porter unicode61'
);
"""


def write_sqlite(
    activities: list[Activity],
    venues: list[Venue],
    out_path: Path,
) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists():
        out_path.unlink()

    venue_geo = {v.slug: (v.center_lat, v.center_lon) for v in venues}

    conn = sqlite3.connect(out_path)
    try:
        conn.executescript(_SCHEMA)

        rows: list[tuple] = []
        day_rows: list[tuple[str, str]] = []
        fts_rows: list[tuple] = []
        for a in activities:
            lat, lon = venue_geo.get(a.venue_slug, (None, None))
            payload = json.dumps(
                a.model_dump(mode="json", exclude_none=False),
                ensure_ascii=False,
                separators=(",", ":"),
            )
            rows.append((
                a.activity_id,
                a.name,
                a.venue_slug,
                a.venue_type.value,
                a.venue_name,
                lat,
                lon,
                _infer_category(a),
                a.schedule.start_date.isoformat() if a.schedule.start_date else None,
                a.schedule.end_date.isoformat() if a.schedule.end_date else None,
                a.age_range.min_months,
                a.age_range.max_months,
                _lowest_price(a),
                _kind(a),
                None if a.registration.is_open is None else int(a.registration.is_open),
                a.registration.opens_at.isoformat() if a.registration.opens_at else None,
                a.schedule.num_sessions,
                payload,
            ))
            for wt in a.schedule.weekly_times:
                day_rows.append((a.activity_id, wt.day_of_week))
            fts_rows.append((
                a.activity_id,
                a.name,
                a.venue_name,
                a.category or "",
                a.raw_category or "",
                a.description or "",
                a.location or "",
            ))

        with conn:
            conn.executemany(
                "INSERT INTO activities VALUES ("
                + ",".join(["?"] * 18) + ")",
                rows,
            )
            conn.executemany(
                "INSERT OR IGNORE INTO activity_days VALUES (?, ?)",
                day_rows,
            )
            conn.executemany(
                "INSERT INTO activities_fts "
                "(activity_id, name, venue_name, category, raw_category, description, location) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)",
                fts_rows,
            )
        # VACUUM cannot run inside a transaction.
        conn.execute("VACUUM;")
    finally:
        conn.close()

    # Gzipped twin for transport. SQLite compresses ~9x because every row
    # carries a JSON payload with repeated keys. The raw .db stays around
    # for local debugging via `sqlite3 activities.db`; only the .gz ships.
    gz_path = out_path.with_suffix(out_path.suffix + ".gz")
    with open(out_path, "rb") as src, gzip.open(gz_path, "wb", compresslevel=6) as dst:
        dst.writelines(src)

    raw_mb = out_path.stat().st_size / 1024 / 1024
    gz_mb = gz_path.stat().st_size / 1024 / 1024
    log.info(
        "Published %d activities to %s (%.1f MB, %.1f MB gzipped)",
        len(activities), out_path, raw_mb, gz_mb,
    )
