"""BiblioCommons v2 events scraper (HTML).

The "v2" BiblioWeb events surface (used by Glenview, etc.) is server-rendered
HTML at::

    {base_url}v2/events?audiences={audience_id}&page={n}

with detail pages at ``{base_url}events/{24-hex-event-id}``. There is no
documented public JSON or Atom endpoint on v2 — older v1 tenants exposed
``/events/search/events.atom`` but Glenview's v2 returns the HTML page
regardless.

Audience filtering uses opaque 24-hex MongoDB-style IDs that are
**tenant-specific** — Glenview's "Kids" id is not Skokie's. Each venue
declares its audience IDs in ``custom_config.audience_ids`` (list of
strings). The scraper iterates audiences × pages and dedupes by event id.

Per-event data we can extract from the listing page:
- Title (h3)
- Detail URL (/events/{id})
- Date ("Friday, May 01")
- Time range ("6:00pm–7:00pm")
- Audience labels (Kids, Teens, Birth to 5, ...)
- Registration text (Required (N spots remaining) / Drop-in / Full / Waitlist)
- Description (short)

We do **not** hit detail pages — listing data is sufficient for the iOS
catalog and detail views deep-link to the BiblioCommons page anyway.
"""

from __future__ import annotations

import re
from collections.abc import Iterator
from datetime import date, datetime, time, timedelta, timezone
from typing import Any
from urllib.parse import urljoin

from bs4 import BeautifulSoup, Tag

from kidsactivity.logging import get_logger
from kidsactivity.models import (
    Activity,
    AgeRange,
    Price,
    Registration,
    Schedule,
    SearchQuery,
    WeeklyTime,
)
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)

_EVENT_ID_RE = re.compile(r"/events/([a-f0-9]{24})\b")
_DATE_LINE_RE = re.compile(
    r"(Mon|Tue|Wed|Thu|Fri|Sat|Sun)[a-z]*,\s*(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2})(?:,\s*(\d{4}))?",
    re.IGNORECASE,
)
_TIME_RANGE_RE = re.compile(
    r"(\d{1,2}(?::\d{2})?\s*[AaPp][Mm])\s*[–\-—to]+\s*(\d{1,2}(?::\d{2})?\s*[AaPp][Mm])",
)
_REG_REMAINING_RE = re.compile(r"\b(\d+)\s+spots?\s+remain", re.IGNORECASE)

_DAY_FULL_TO_SHORT = {
    "monday": "Mon", "tuesday": "Tue", "wednesday": "Wed", "thursday": "Thu",
    "friday": "Fri", "saturday": "Sat", "sunday": "Sun",
    "mon": "Mon", "tue": "Tue", "wed": "Wed", "thu": "Thu",
    "fri": "Fri", "sat": "Sat", "sun": "Sun",
}

_MONTH_TO_NUM = {
    "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    "january": 1, "february": 2, "march": 3, "april": 4, "june": 6,
    "july": 7, "august": 8, "september": 9, "october": 10, "november": 11, "december": 12,
}

# Audience label → (min_months, max_months). Library audiences are coarse;
# we map them as conservatively as possible. Empty means unconstrained.
_AUDIENCE_AGE_MAP: dict[str, tuple[int | None, int | None]] = {
    "birth to 5": (0, 72),
    "age 0-5": (0, 72),
    "age 0–5": (0, 72),
    "babies": (0, 18),
    "toddlers": (12, 36),
    "preschoolers": (36, 60),
    "preschool": (36, 60),
    "kids": (60, 156),
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
    "teens": (156, 216),
    "tweens": (96, 156),
    "school age": (60, 132),
    "all ages": (None, None),
}


class BiblioCommonsScraper(BaseScraper):
    PAGE_SIZE = 20
    MAX_PAGES_PER_AUDIENCE = 20  # 400 events/audience cap
    DEFAULT_AUDIENCE_IDS: tuple[str, ...] = ()

    def search(self, query: SearchQuery) -> Iterator[Activity]:
        audience_ids = self._audience_ids()
        if not audience_ids:
            log.warning(
                "[%s] biblio_commons: no audience_ids in venue.custom_config; "
                "skipping (declare audience_ids in venues.yaml)",
                self.venue.slug,
            )
            return

        seen: set[str] = set()
        for audience_id in audience_ids:
            for page in range(1, self.MAX_PAGES_PER_AUDIENCE + 1):
                try:
                    html = self._fetch_listing(audience_id, page)
                except Exception as e:
                    log.warning(
                        "[%s] biblio_commons listing fetch failed audience=%s page=%d: %s",
                        self.venue.slug, audience_id, page, e,
                    )
                    break
                soup = BeautifulSoup(html, "html.parser")
                cards = self._extract_event_cards(soup)
                if not cards:
                    break
                for card in cards:
                    activity = self._parse_card(card)
                    if activity is None:
                        continue
                    if activity.activity_id in seen:
                        continue
                    seen.add(activity.activity_id)
                    yield activity
                if not self._has_next_page(soup, page):
                    break

    def _fetch_listing(self, audience_id: str, page: int) -> str:
        url = urljoin(str(self.venue.base_url), "v2/events")
        resp = self.http.get(
            url,
            params={"audiences": audience_id, "page": str(page)},
            headers={"Accept": "text/html"},
        )
        resp.raise_for_status()
        return resp.text

    def _audience_ids(self) -> list[str]:
        cfg = self.venue.custom_config or {}
        ids = cfg.get("audience_ids")
        if isinstance(ids, list) and ids:
            return [str(x) for x in ids]
        return list(self.DEFAULT_AUDIENCE_IDS)

    def _extract_event_cards(self, soup: BeautifulSoup) -> list[Tag]:
        # Each event is anchored by a link to /events/{24hex}. The card
        # container is the nearest ancestor that contains the link AND
        # the surrounding metadata text (date, time, audience).
        anchors = soup.find_all("a", href=_EVENT_ID_RE)
        cards: list[Tag] = []
        seen_ids: set[str] = set()
        for a in anchors:
            m = _EVENT_ID_RE.search(a.get("href", ""))
            if not m:
                continue
            event_id = m.group(1)
            if event_id in seen_ids:
                continue
            seen_ids.add(event_id)
            card = _ascend_to_card(a)
            if card is not None:
                cards.append(card)
        return cards

    def _has_next_page(self, soup: BeautifulSoup, current_page: int) -> bool:
        for link in soup.find_all("a", href=True):
            href = link.get("href", "")
            if "page=" not in href:
                continue
            m = re.search(r"[?&]page=(\d+)", href)
            if m and int(m.group(1)) > current_page:
                return True
        return False

    def _parse_card(self, card: Tag) -> Activity | None:
        anchor = card.find("a", href=_EVENT_ID_RE)
        if not anchor:
            return None
        m = _EVENT_ID_RE.search(anchor.get("href", ""))
        if not m:
            return None
        event_id = m.group(1)

        # Title: prefer h3 inside the card, fall back to the anchor text.
        title_el = card.find(["h3", "h2", "h4"])
        raw_title = (title_el.get_text(" ", strip=True) if title_el else anchor.get_text(" ", strip=True)).strip()
        title = _clean_title(raw_title)
        if not title:
            return None

        text_blob = card.get_text(" ", strip=True)
        start_date, day_of_week = _parse_date_line(text_blob)
        start_time, end_time = _parse_time_range(text_blob)
        location = self._guess_location(card) or self.venue.name
        audiences = _extract_audience_labels(text_blob)
        age_range = _audiences_to_age_range(audiences)
        registration = _parse_registration(text_blob)
        # Listing cards on BiblioCommons v2 don't carry a description —
        # they show only date/time/audience boilerplate. The detail page
        # (linked via source_url) has the real blurb; skip rather than
        # emit noise into the iOS detail view.
        description: str | None = None

        weekly: list[WeeklyTime] = []
        if start_time and end_time and day_of_week:
            try:
                weekly = [WeeklyTime(day_of_week=day_of_week, start=start_time, end=end_time)]
            except Exception:
                weekly = []

        schedule = Schedule(
            start_date=start_date,
            end_date=start_date,
            weekly_times=weekly,
            raw_schedule_text=_join_nonempty(
                _format_date(start_date),
                _format_time_range(start_time, end_time),
            ),
            num_sessions=1 if start_date else None,
        )

        source_url = urljoin(str(self.venue.base_url), f"events/{event_id}")
        return Activity(
            name=title,
            venue_name=self.venue.name,
            venue_slug=self.venue.slug,
            venue_type=self.venue.venue_type,
            schedule=schedule,
            price=Price(resident_price=0.0, raw_price_text="Free"),
            age_range=age_range,
            location=location,
            registration=registration,
            source_url=source_url,
            activity_id=f"biblio_commons:{self.venue.slug}:{event_id}",
            category=None,
            raw_category=", ".join(audiences) if audiences else None,
            description=description,
        )

    def _guess_location(self, card: Tag) -> str | None:
        # Listing pages usually show only the venue name; detail pages
        # carry room-level location. Fall back to None and let the caller
        # default to the venue display name.
        for el in card.find_all(string=True):
            text = str(el).strip()
            if not text:
                continue
            low = text.lower()
            if "library" in low and len(text) < 80:
                return text
        return None


def _ascend_to_card(anchor: Tag, max_levels: int = 6) -> Tag | None:
    cur: Tag | None = anchor
    for _ in range(max_levels):
        if cur is None:
            return None
        parent = cur.parent
        if parent is None or not isinstance(parent, Tag):
            return cur
        # Heuristic: a "card" parent contains a date string AND a time
        # range AND the audience labels — i.e. it's not just the link's
        # immediate wrapper.
        text = parent.get_text(" ", strip=True)
        if (
            _DATE_LINE_RE.search(text)
            and _TIME_RANGE_RE.search(text)
            and len(text) < 1500
        ):
            return parent
        cur = parent
    return cur


def _parse_date_line(text: str) -> tuple[date | None, str | None]:
    m = _DATE_LINE_RE.search(text)
    if not m:
        return None, None
    day_token, month_token, day_num, year_token = m.groups()
    month_num = _MONTH_TO_NUM.get(month_token.lower())
    if month_num is None:
        return None, _DAY_FULL_TO_SHORT.get(day_token.lower())
    if year_token:
        year = int(year_token)
    else:
        year = _infer_year(month_num, int(day_num))
    try:
        d = date(year, month_num, int(day_num))
    except ValueError:
        return None, _DAY_FULL_TO_SHORT.get(day_token.lower())
    return d, _DAY_FULL_TO_SHORT.get(day_token.lower())


def _infer_year(month_num: int, day_num: int) -> int:
    # Listings with no year — assume the closest upcoming occurrence
    # within ~1 month of today (in UTC). If the date already passed this
    # year, roll over to next.
    today = datetime.now(timezone.utc).date()
    candidate = date(today.year, month_num, day_num)
    if candidate < today - timedelta(days=14):
        return today.year + 1
    return today.year


def _parse_time_range(text: str) -> tuple[time | None, time | None]:
    m = _TIME_RANGE_RE.search(text)
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


def _extract_audience_labels(text: str) -> list[str]:
    labels: list[str] = []
    seen: set[str] = set()
    for key in _AUDIENCE_AGE_MAP:
        if key.lower() in text.lower() and key not in seen:
            labels.append(key.title() if key not in {"all ages"} else "All Ages")
            seen.add(key)
    return labels


def _audiences_to_age_range(audiences: list[str]) -> AgeRange:
    if not audiences:
        return AgeRange()
    has_all_ages = any(a.lower() == "all ages" for a in audiences)
    mins: list[int] = []
    maxs: list[int] = []
    for a in audiences:
        bounds = _AUDIENCE_AGE_MAP.get(a.lower())
        if bounds is None:
            continue
        lo, hi = bounds
        if lo is not None:
            mins.append(lo)
        if hi is not None:
            maxs.append(hi)
    # "All ages" wins over any narrow audience tag — return unconstrained.
    return AgeRange(
        min_months=None if has_all_ages else (min(mins) if mins else None),
        max_months=None if has_all_ages else (max(maxs) if maxs else None),
        raw_age_text=", ".join(audiences) or None,
    )


def _parse_registration(text: str) -> Registration:
    low = text.lower()
    is_open: bool | None = None
    raw_text: str | None = None
    if "drop-in" in low or "drop in" in low or "no registration" in low:
        is_open = True
        raw_text = "Drop-in"
    elif "waitlist" in low or "wait list" in low:
        is_open = False
        raw_text = "Waitlist"
    elif "full" in low and "spots" not in low:
        is_open = False
        raw_text = "Full"
    elif "registration required" in low or "registration:" in low:
        m = _REG_REMAINING_RE.search(text)
        if m:
            is_open = int(m.group(1)) > 0
            raw_text = f"{m.group(1)} spots remaining"
        else:
            is_open = True
            raw_text = "Registration required"
    return Registration(is_open=is_open, raw_text=raw_text)


# BiblioCommons sometimes appends a status badge (e.g. "In Progress",
# "Cancelled", "Online", "In Person") right after the title in the same
# h3 — strip those so the title doesn't read "Storytime In Progress".
_TITLE_STATUS_SUFFIX_RE = re.compile(
    r"\s+(In Progress|Cancelled|Canceled|Postponed|Online|In Person|Hybrid|"
    r"Registration Required|Drop[- ]?in|Full|Waitlist|Sold Out)\s*$",
    re.IGNORECASE,
)


def _clean_title(title: str) -> str:
    cleaned = title
    # Repeat to handle "Title In Progress Drop-in" → trim once per pass.
    for _ in range(3):
        new = _TITLE_STATUS_SUFFIX_RE.sub("", cleaned).strip()
        if new == cleaned:
            break
        cleaned = new
    return cleaned


def _extract_description(card: Tag, title: str) -> str | None:
    # The card's text minus the title and the date/time/audience boilerplate
    # tends to leave a short blurb. Cap to a sensible length to avoid
    # accidentally inhaling the whole sidebar.
    paragraphs: list[str] = []
    for p in card.find_all(["p", "div", "span"]):
        text = p.get_text(" ", strip=True)
        if not text or text == title:
            continue
        if _DATE_LINE_RE.fullmatch(text) or _TIME_RANGE_RE.fullmatch(text):
            continue
        if len(text) < 25 or len(text) > 600:
            continue
        # Skip pure metadata lines.
        low = text.lower()
        if any(low.startswith(p) for p in ("ages ", "audience", "location:")):
            continue
        paragraphs.append(text)
        if len(paragraphs) >= 1:
            break
    return paragraphs[0] if paragraphs else None


def _format_date(d: date | None) -> str:
    if d is None:
        return ""
    return d.strftime("%b %-d, %Y") if hasattr(d, "strftime") else ""


def _format_time_range(start: time | None, end: time | None) -> str:
    if start is None and end is None:
        return ""
    return f"{_fmt_time(start)}–{_fmt_time(end)}".strip("–")


def _fmt_time(t: time | None) -> str:
    if t is None:
        return ""
    return t.strftime("%I:%M %p").lstrip("0")


def _join_nonempty(*parts: str) -> str | None:
    items = [p for p in parts if p]
    return " · ".join(items) if items else None
