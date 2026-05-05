"""Shared audience/date/title parsing for library + museum scrapers.

Lifted from `biblio_commons.py` so `custom_html.py` (and any future
library-style scraper) can reuse the same audience-label → age-range table
and date/time regexes without copy-pasting. `biblio_commons.py` keeps its
private copies for now — touching it is out of scope for this round.

If you add a new audience label here, add it to the right scraper's parser
flow too. Audience matching is case-insensitive and substring-based, so
long phrases ("babies, toddlers, and preschoolers") must be listed BEFORE
their substrings ("babies", "toddlers") in iteration order — Python dicts
preserve insertion order in 3.7+, which we rely on.
"""

from __future__ import annotations

import re
from datetime import date, datetime, time, timedelta, timezone

# Audience label → (min_months, max_months). `None` on either side means
# "no lower/upper bound." Keys are matched case-insensitively as substrings.
# Order matters: longer phrases appear first so substring matches don't
# steal a more specific label.
AUDIENCE_AGE_MAP: dict[str, tuple[int | None, int | None]] = {
    # Compound phrases first.
    "babies, toddlers, and preschoolers": (0, 60),
    "babies and toddlers": (0, 36),
    "babies & toddlers": (0, 36),
    "teens & tweens": (96, 216),
    "tweens & teens": (96, 216),
    "school age": (60, 132),
    "school-age": (60, 132),
    "all ages": (None, None),
    # BiblioCommons-style coarse buckets.
    "birth to 5": (0, 72),
    "age 0-5": (0, 72),
    "age 0–5": (0, 72),
    "babies": (0, 18),
    "toddlers": (12, 36),
    "preschoolers": (36, 60),
    "preschool": (36, 60),
    "kids": (60, 156),
    "children": (24, 144),
    "tweens": (96, 156),
    "teens": (156, 216),
    "family": (None, None),  # treat as all-ages
    "families": (None, None),
    # Grade-band labels.
    "grade k-2": (60, 96),
    "grade k–2": (60, 96),
    "grade 3-5": (96, 132),
    "grade 3–5": (96, 132),
    "grade 6-8": (132, 168),
    "grade 6–8": (132, 168),
    "grades k-8": (60, 168),
    "grades k–8": (60, 168),
    "grade 9-12": (168, 216),
    "grade 9–12": (168, 216),
    "grades 9-12": (168, 216),
    "grades 9–12": (168, 216),
}

DATE_LINE_RE = re.compile(
    r"(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,\s*"
    r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+"
    r"(\d{1,2})(?:,\s*(\d{4}))?",
    re.IGNORECASE,
)

# "January 24 - May 10" or "Jan 24 – May 10, 2026" (no leading day-of-week).
DATE_RANGE_RE = re.compile(
    r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2})"
    r"\s*[–\-—to]+\s*"
    r"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2})"
    r"(?:,\s*(\d{4}))?",
    re.IGNORECASE,
)

TIME_RANGE_RE = re.compile(
    r"(\d{1,2}(?::\d{2})?\s*[AaPp][Mm])\s*[–\-—to]+\s*"
    r"(\d{1,2}(?::\d{2})?\s*[AaPp][Mm])"
)

DAY_FULL_TO_SHORT = {
    "monday": "Mon", "tuesday": "Tue", "wednesday": "Wed", "thursday": "Thu",
    "friday": "Fri", "saturday": "Sat", "sunday": "Sun",
    "mon": "Mon", "tue": "Tue", "wed": "Wed", "thu": "Thu",
    "fri": "Fri", "sat": "Sat", "sun": "Sun",
}

MONTH_TO_NUM = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    "january": 1, "february": 2, "march": 3, "april": 4, "june": 6,
    "july": 7, "august": 8, "september": 9, "october": 10,
    "november": 11, "december": 12,
}

# Title-trailing status badges that scrapers should strip ("Storytime
# In Progress" → "Storytime").
_TITLE_STATUS_SUFFIX_RE = re.compile(
    r"\s+(In Progress|Cancelled|Canceled|Postponed|Online|In Person|Hybrid|"
    r"Registration Required|Drop[- ]?in|Full|Waitlist|Sold Out)\s*$",
    re.IGNORECASE,
)


def parse_date_line(text: str) -> tuple[date | None, str | None]:
    """Match the `(Wed,) Jan 8(, 2026)` pattern. Returns (date, day-of-week)."""
    m = DATE_LINE_RE.search(text)
    if not m:
        return None, None
    day_token, month_token, day_num, year_token = m.groups()
    month_num = MONTH_TO_NUM.get(month_token.lower())
    if month_num is None:
        return None, DAY_FULL_TO_SHORT.get(day_token.lower())
    year = int(year_token) if year_token else _infer_year(month_num, int(day_num))
    try:
        d = date(year, month_num, int(day_num))
    except ValueError:
        return None, DAY_FULL_TO_SHORT.get(day_token.lower())
    return d, DAY_FULL_TO_SHORT.get(day_token.lower())


def parse_date_range(text: str, *, default_year: int | None = None) -> tuple[date | None, date | None]:
    """Match `January 24 - May 10` (no day-of-week prefix).

    Year inference handles three cases:
    - Year given in text → use it.
    - End date (with current year) lands in the future or recent past → the
      range is *currently active*, so anchor both start and end to the
      current year. Catches museum exhibits like "Jan 24 – May 10" that
      began before today but haven't ended yet.
    - Otherwise → infer year per `_infer_year` of the start date, and bump
      the end year by one if the range wraps Dec→Jan.

    Used by Kohl's "Special Exhibits" copy.
    """
    m = DATE_RANGE_RE.search(text)
    if not m:
        return None, None
    m1, d1, m2, d2, year_token = m.groups()
    mn1 = MONTH_TO_NUM.get(m1.lower())
    mn2 = MONTH_TO_NUM.get(m2.lower())
    if mn1 is None or mn2 is None:
        return None, None
    if year_token:
        y1 = int(year_token)
        y2 = y1 + 1 if mn2 < mn1 else y1
    else:
        y1 = _resolve_range_year(mn1, int(d1), mn2, int(d2), default_year)
        y2 = y1 + 1 if mn2 < mn1 else y1
    try:
        return date(y1, mn1, int(d1)), date(y2, mn2, int(d2))
    except ValueError:
        return None, None


def _resolve_range_year(
    start_m: int, start_d: int, end_m: int, end_d: int, default_year: int | None
) -> int:
    if default_year is not None:
        return default_year
    today = datetime.now(timezone.utc).date()
    # Active-range case: anchor end to current year and check whether
    # today falls within (start, end). If yes, use current year for both.
    try:
        # Handle wraparound: if end_m < start_m, end is in next calendar year.
        end_year = today.year + 1 if end_m < start_m else today.year
        end_with_current = date(end_year, end_m, end_d)
    except ValueError:
        end_with_current = None
    if end_with_current is not None:
        # Range is "active" if it ends in the future or ended within the
        # last 30 days. Either way, the start date sits in the current
        # calendar year (or this year for wraparound start).
        if end_with_current >= today - timedelta(days=30):
            return today.year
    return _infer_year(start_m, start_d)


def parse_time_range(text: str) -> tuple[time | None, time | None]:
    m = TIME_RANGE_RE.search(text)
    if not m:
        return None, None
    return _parse_time_token(m.group(1)), _parse_time_token(m.group(2))


def _parse_time_token(s: str) -> time | None:
    t = s.strip().upper().replace(" ", "")
    for fmt in ("%I:%M%p", "%I%p"):
        try:
            return datetime.strptime(t, fmt).time()
        except ValueError:
            continue
    return None


def _infer_year(month_num: int, day_num: int) -> int:
    today = datetime.now(timezone.utc).date()
    candidate = date(today.year, month_num, day_num)
    if candidate < today - timedelta(days=14):
        return today.year + 1
    return today.year


def extract_audience_labels(text: str) -> list[str]:
    """Return the ordered list of audience phrases that appear in `text`.

    Matches are substring + case-insensitive. Each phrase appears at most
    once. Output order follows AUDIENCE_AGE_MAP iteration so longer
    phrases ("babies, toddlers, and preschoolers") win over their
    components ("babies").
    """
    out: list[str] = []
    seen: set[str] = set()
    low_text = text.lower()
    for key in AUDIENCE_AGE_MAP:
        if key in seen:
            continue
        if key.lower() in low_text:
            out.append(key.title() if key != "all ages" else "All Ages")
            seen.add(key)
            # Mark substrings of this key as seen too — avoids "babies"
            # double-tagging after "babies, toddlers, and preschoolers"
            # already matched.
            for other in AUDIENCE_AGE_MAP:
                if other != key and other in key.lower():
                    seen.add(other)
    return out


def audiences_to_age_range(
    audiences: list[str],
) -> tuple[int | None, int | None, str | None]:
    """Aggregate audience labels into (min_months, max_months, raw_text).

    "All ages" / "Family" widen to unbounded. Otherwise take the min of
    lower bounds and max of upper bounds across all matched labels.
    """
    if not audiences:
        return None, None, None
    raw = ", ".join(audiences)
    has_all_ages = any(a.lower() in {"all ages", "family", "families"} for a in audiences)
    if has_all_ages:
        return None, None, raw
    mins: list[int] = []
    maxs: list[int] = []
    for a in audiences:
        bounds = AUDIENCE_AGE_MAP.get(a.lower())
        if bounds is None:
            continue
        lo, hi = bounds
        if lo is not None:
            mins.append(lo)
        if hi is not None:
            maxs.append(hi)
    return (
        min(mins) if mins else None,
        max(maxs) if maxs else None,
        raw,
    )


def clean_title(title: str) -> str:
    cleaned = title
    for _ in range(3):
        new = _TITLE_STATUS_SUFFIX_RE.sub("", cleaned).strip()
        if new == cleaned:
            break
        cleaned = new
    return cleaned


def format_date(d: date | None) -> str:
    if d is None:
        return ""
    return d.strftime("%b %-d, %Y")


def format_time_range(start: time | None, end: time | None) -> str:
    if start is None and end is None:
        return ""
    return f"{_fmt_time(start)}–{_fmt_time(end)}".strip("–")


def _fmt_time(t: time | None) -> str:
    if t is None:
        return ""
    return t.strftime("%I:%M %p").lstrip("0")


def join_nonempty(*parts: str) -> str | None:
    items = [p for p in parts if p]
    return " · ".join(items) if items else None
