"""ActiveNet (Active Communities) scraper.

Targets the modern "ANC" REST API used by every venue hosted on
``anc.apm.activecommunities.com``. Older tenants on the bare
``apm.activecommunities.com`` host no longer expose the JSON search
endpoint we need (rest/activities/list) — point their ``base_url`` at the
``anc.`` host instead.

Request shape::

    POST {base}/rest/activities/list?locale=en-US
    Header  page_info: {"order_by":"","page_number":N,"total_records_per_page":20}
    Body    {"activity_search_pattern": {...}, "activity_transfer_pattern": {}}

The list view omits fee details, per-meeting times, and resident /
non-resident registration open dates — those live on per-activity detail
endpoints. ``enrich()`` (called by pipeline.py *after* filtering) hits
``rest/activity/detail/estimateprice/{id}`` and
``rest/activity/detail/meetingandregistrationdates/{id}`` to backfill
them, capped at MAX_ENRICH per venue.
"""

from __future__ import annotations

import json
from collections.abc import Iterator
from datetime import date, datetime, time, timedelta
from typing import Any
from urllib.parse import urljoin

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


class ActiveNetScraper(BaseScraper):
    MAX_PAGES = 150
    PAGE_SIZE = 20
    MAX_ENRICH = 60

    def search(self, query: SearchQuery) -> Iterator[Activity]:
        total_pages: int | None = None
        for page in range(1, self.MAX_PAGES + 1):
            try:
                data = self._fetch_page(query, page)
            except Exception as e:
                log.warning(
                    "[%s] ActiveNet fetch failed on page %d: %s",
                    self.venue.slug, page, e,
                )
                return
            activities = _extract_activities(data)
            if not activities:
                return
            for a in activities:
                activity = self._parse_activity(a)
                if activity is not None:
                    yield activity
            if total_pages is None:
                total_pages = _extract_total_pages(data)
            if total_pages is not None and page >= total_pages:
                return
            if len(activities) < self.PAGE_SIZE:
                return
        if total_pages is not None and total_pages > self.MAX_PAGES:
            log.warning(
                "[%s] ActiveNet has %d pages but we capped at %d — results truncated",
                self.venue.slug, total_pages, self.MAX_PAGES,
            )

    def _fetch_page(self, query: SearchQuery, page: int) -> dict[str, Any]:
        url = urljoin(str(self.venue.base_url), "rest/activities/list")
        payload = self._search_payload(query)
        page_info = json.dumps(
            {"order_by": "", "page_number": page, "total_records_per_page": self.PAGE_SIZE},
            separators=(",", ":"),
        )
        resp = self.http.post(
            f"{url}?locale=en-US",
            json=payload,
            headers={"page_info": page_info},
        )
        resp.raise_for_status()
        return resp.json()

    def enrich(self, activities: list[Activity]) -> list[Activity]:
        out: list[Activity] = []
        enriched = 0
        for a in activities:
            if enriched >= self.MAX_ENRICH or not _needs_enrichment(a):
                out.append(a)
                continue
            activity_id = a.activity_id.rsplit(":", 1)[-1] if ":" in a.activity_id else None
            if not activity_id:
                out.append(a)
                continue

            updates: dict[str, Any] = {}
            if _needs_price(a):
                try:
                    price = self._fetch_price(activity_id)
                except Exception as e:
                    log.warning(
                        "[%s] estimateprice/%s failed: %s",
                        self.venue.slug, activity_id, e,
                    )
                    price = None
                if price is not None:
                    updates["price"] = price
            if (
                _needs_meetings(a)
                or _needs_registration_dates(a)
                or _needs_num_sessions(a)
            ):
                try:
                    weekly, reg_dates, num_sessions = self._fetch_meetings(activity_id)
                except Exception as e:
                    log.warning(
                        "[%s] meetings/%s failed: %s",
                        self.venue.slug, activity_id, e,
                    )
                    weekly, reg_dates, num_sessions = [], None, None
                sched_updates: dict[str, Any] = {}
                if weekly and _needs_meetings(a):
                    sched_updates["weekly_times"] = weekly
                if num_sessions is not None and _needs_num_sessions(a):
                    sched_updates["num_sessions"] = num_sessions
                if sched_updates:
                    updates["schedule"] = a.schedule.model_copy(update=sched_updates)
                if reg_dates and _needs_registration_dates(a):
                    updates["registration"] = a.registration.model_copy(update=reg_dates)

            enriched += 1
            out.append(a.model_copy(update=updates) if updates else a)
        if enriched:
            log.info(
                "[%s] enriched %d/%d activities with detail endpoints",
                self.venue.slug, enriched, len(activities),
            )
        return out

    def _fetch_price(self, activity_id: str) -> Price | None:
        url = urljoin(
            str(self.venue.base_url),
            f"rest/activity/detail/estimateprice/{activity_id}",
        )
        resp = self.http.get(f"{url}?locale=en-US")
        resp.raise_for_status()
        return _parse_estimateprice(resp.json())

    def _fetch_meetings(
        self, activity_id: str
    ) -> tuple[list[WeeklyTime], dict[str, datetime] | None, int | None]:
        url = urljoin(
            str(self.venue.base_url),
            f"rest/activity/detail/meetingandregistrationdates/{activity_id}",
        )
        resp = self.http.get(f"{url}?locale=en-US")
        resp.raise_for_status()
        return _parse_meeting_dates(resp.json())

    def _search_payload(self, query: SearchQuery) -> dict[str, Any]:
        return {
            "activity_search_pattern": {
                "skills": [],
                "time_after_str": None,
                "days_of_week": None,
                "activity_select_param": 2,
                "center_ids": [],
                "other_category_ids": [],
                "activity_id": None,
                "activity_category_ids": [],
                "activity_other_category_ids": [],
                "activity_keyword": query.keyword or "",
                "instructor_ids": [],
                "open_spots": None,
            },
            "activity_transfer_pattern": {},
        }

    def _parse_activity(self, a: dict[str, Any]) -> Activity | None:
        name = a.get("name") or a.get("activity_name") or a.get("desc")
        anc_id = str(a.get("id") or a.get("activity_id") or "")
        if not name or not anc_id:
            return None

        schedule = _parse_schedule(a)
        price = _parse_price(a)
        age_range = _parse_age_range(a)
        registration = _parse_registration(a)
        location = _extract_location(a)
        category = a.get("category_name") or a.get("activity_category")
        description = _strip_html(a.get("desc") or a.get("description") or a.get("desc2"))

        source_url = urljoin(str(self.venue.base_url), f"activity/search/detail/{anc_id}")

        return Activity(
            name=str(name).strip(),
            venue_name=self.venue.name,
            venue_slug=self.venue.slug,
            venue_type=self.venue.venue_type,
            schedule=schedule,
            price=price,
            age_range=age_range,
            location=location,
            registration=registration,
            source_url=source_url,
            activity_id=f"activenet:{self.venue.slug}:{anc_id}",
            category=_normalize_category(category) if category else None,
            raw_category=str(category) if category else None,
            description=description,
        )


def _extract_activities(data: dict[str, Any]) -> list[dict]:
    body = data.get("body") or data
    if not isinstance(body, dict):
        return []
    for key in ("activity_items", "activities", "items", "records", "data"):
        value = body.get(key)
        if isinstance(value, list):
            return value
    result = body.get("result")
    if isinstance(result, dict):
        for key in ("items", "activities", "records"):
            value = result.get(key)
            if isinstance(value, list):
                return value
    return []


def _extract_total_pages(data: dict[str, Any]) -> int | None:
    headers = data.get("headers")
    if not isinstance(headers, dict):
        return None
    page_info = headers.get("page_info")
    if not isinstance(page_info, dict):
        return None
    tp = page_info.get("total_page")
    try:
        return int(tp) if tp is not None else None
    except (TypeError, ValueError):
        return None


def _extract_location(a: dict[str, Any]) -> str:
    loc = a.get("location") or a.get("location_name") or a.get("site_name")
    if isinstance(loc, dict):
        return str(loc.get("label") or loc.get("title") or "").strip()
    return str(loc or "").strip()


def _parse_schedule(a: dict[str, Any]) -> Schedule:
    raw = a.get("date_range") or a.get("date_range_description") or a.get("schedule_description")
    start_date = _parse_date(a.get("date_range_start") or a.get("beginning_date") or a.get("start_date"))
    end_date = _parse_date(a.get("date_range_end") or a.get("ending_date") or a.get("end_date"))
    return Schedule(
        start_date=start_date,
        end_date=end_date,
        weekly_times=[],
        raw_schedule_text=str(raw) if raw else None,
    )


def _parse_date(val: Any) -> date | None:
    if not val:
        return None
    s = str(val)
    for fmt in ("%Y-%m-%d", "%m/%d/%Y", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(s[: len(fmt) + 2], fmt).date()
        except ValueError:
            continue
    return None


def _parse_price(a: dict[str, Any]) -> Price:
    fees = a.get("fees") or a.get("fee_groups")
    resident: float | None = None
    non_resident: float | None = None
    raw_text: str | None = None

    if isinstance(fees, list) and fees:
        for f in fees:
            if not isinstance(f, dict):
                continue
            label = str(f.get("label") or f.get("fee_label") or "").lower()
            amt = f.get("amount") or f.get("fee_amount") or f.get("total_fee")
            if amt is None:
                continue
            try:
                amt = float(amt)
            except (TypeError, ValueError):
                continue
            if "non" in label and "resident" in label:
                non_resident = amt
            elif "resident" in label or "member" in label:
                resident = amt
            elif resident is None:
                resident = amt
        raw_text = ", ".join(
            f"{f.get('label', '?')}: {f.get('amount')}"
            for f in fees if isinstance(f, dict)
        ) or None
    else:
        sfp = a.get("search_from_price")
        try:
            if sfp is not None:
                resident = float(sfp)
        except (TypeError, ValueError):
            pass
        nr = a.get("non_resident_fee") or a.get("non_resident_price")
        try:
            if nr is not None:
                non_resident = float(nr)
        except (TypeError, ValueError):
            pass
        raw_text = a.get("search_from_price_desc") or None

    return Price(resident_price=resident, non_resident_price=non_resident, raw_price_text=raw_text)


def _parse_age_range(a: dict[str, Any]) -> AgeRange:
    min_m = _split_age_to_months(
        a.get("age_min_year"), a.get("age_min_month"), a.get("age_min_week")
    )
    max_m = _split_age_to_months(
        a.get("age_max_year"), a.get("age_max_month"), a.get("age_max_week")
    )
    if min_m is None:
        min_m = _coerce_int(a.get("age_min") or a.get("activity_age_min"))
    if max_m is None:
        max_m = _coerce_int(a.get("age_max") or a.get("activity_age_max"))

    raw = a.get("age_description") or a.get("ages") or a.get("age_range_text")
    return AgeRange(
        min_months=min_m,
        max_months=max_m,
        raw_age_text=str(raw).strip().rstrip(",") if raw else None,
    )


def _split_age_to_months(years: Any, months: Any, weeks: Any) -> int | None:
    if years is None and months is None and weeks is None:
        return None
    y = _coerce_int(years) or 0
    m = _coerce_int(months) or 0
    w = _coerce_int(weeks) or 0
    if not (y or m or w):
        return None
    return y * 12 + m + (w // 4)


def _coerce_int(val: Any) -> int | None:
    if val is None:
        return None
    try:
        return int(val)
    except (TypeError, ValueError):
        return None


def _parse_registration(a: dict[str, Any]) -> Registration:
    is_open: bool | None = a.get("registration_open") or a.get("is_registration_open")
    raw_status = a.get("registration_status_description") or a.get("availability")
    msg = a.get("urgent_message")
    if isinstance(msg, dict):
        status = (msg.get("status_description") or "").strip()
        if status:
            raw_status = raw_status or status
            lo = status.lower()
            if is_open is None:
                if any(k in lo for k in ("in progress", "open", "available", "register now")):
                    is_open = True
                elif any(k in lo for k in ("full", "closed", "waitlist", "coming soon", "ended")):
                    is_open = False
    if is_open is None:
        total_open = _coerce_int(a.get("total_open"))
        if total_open is not None:
            is_open = total_open > 0

    opens_at = _parse_dt(a.get("registration_start") or a.get("registration_open_date"))
    closes_at = _parse_dt(a.get("registration_end") or a.get("registration_close_date"))
    return Registration(
        is_open=bool(is_open) if is_open is not None else None,
        opens_at=opens_at,
        closes_at=closes_at,
        raw_text=str(raw_status) if raw_status else None,
    )


def _parse_dt(val: Any) -> datetime | None:
    if not val:
        return None
    s = str(val)
    for fmt in (
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%d %H:%M:%S",
        "%Y-%m-%d",
        "%m/%d/%Y %H:%M:%S",
        "%m/%d/%Y",
    ):
        try:
            return datetime.strptime(s[: len(fmt) + 2], fmt)
        except ValueError:
            continue
    return None


def _strip_html(s: Any) -> str | None:
    if not s:
        return None
    text = str(s)
    import re
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text or None


def _needs_price(a: Activity) -> bool:
    return a.price.resident_price is None and a.price.non_resident_price is None


def _needs_meetings(a: Activity) -> bool:
    return not a.schedule.weekly_times


def _needs_registration_dates(a: Activity) -> bool:
    return (
        a.registration.resident_opens_at is None
        and a.registration.non_resident_opens_at is None
    )


def _needs_num_sessions(a: Activity) -> bool:
    return a.schedule.num_sessions is None


def _needs_enrichment(a: Activity) -> bool:
    return (
        _needs_price(a)
        or _needs_meetings(a)
        or _needs_registration_dates(a)
        or _needs_num_sessions(a)
    )


_DAY_TOKEN_MAP = {
    "mon": "Mon", "monday": "Mon",
    "tue": "Tue", "tues": "Tue", "tuesday": "Tue",
    "wed": "Wed", "weds": "Wed", "wednesday": "Wed",
    "thu": "Thu", "thur": "Thu", "thurs": "Thu", "thursday": "Thu",
    "fri": "Fri", "friday": "Fri",
    "sat": "Sat", "saturday": "Sat",
    "sun": "Sun", "sunday": "Sun",
}


def _parse_meeting_dates(
    data: dict[str, Any],
) -> tuple[list[WeeklyTime], dict[str, datetime] | None, int | None]:
    body = data.get("body") or {}
    mrd = body.get("meeting_and_registration_dates") or {}

    weekly: list[WeeklyTime] = []
    seen: set[tuple[str, time, time]] = set()
    num_sessions: int = 0
    any_pattern = False
    for pattern in mrd.get("activity_patterns") or []:
        if not isinstance(pattern, dict):
            continue
        any_pattern = True
        weekday_tokens: set[str] = set()
        for pd in pattern.get("pattern_dates") or []:
            if not isinstance(pd, dict):
                continue
            start = _parse_clock(pd.get("starting_time"))
            end = _parse_clock(pd.get("ending_time"))
            if start is None or end is None:
                continue
            for token in _split_weekday_tokens(pd.get("weekdays")):
                canon = _DAY_TOKEN_MAP.get(token.lower())
                if not canon:
                    continue
                weekday_tokens.add(canon)
                key = (canon, start, end)
                if key in seen:
                    continue
                seen.add(key)
                weekly.append(WeeklyTime(day_of_week=canon, start=start, end=end))
        num_sessions += _count_pattern_sessions(
            pattern.get("beginning_date"),
            pattern.get("ending_date"),
            weekday_tokens,
            pattern.get("exception_dates") or [],
        )
    additional = mrd.get("additional_dates") or []
    if isinstance(additional, list):
        num_sessions += sum(1 for _ in additional)

    reg_dates: dict[str, datetime] = {}
    enrollments = mrd.get("enrollment_datetimes") or []
    if isinstance(enrollments, list) and enrollments:
        first = enrollments[0]
        if isinstance(first, dict):
            res = _parse_dt(first.get("first_daytime_internet"))
            non_res = _parse_dt(first.get("first_daytime_internet_nonresidents"))
            if res is not None:
                reg_dates["resident_opens_at"] = res
                reg_dates["opens_at"] = res
            if non_res is not None:
                reg_dates["non_resident_opens_at"] = non_res

    sessions_out: int | None = num_sessions if any_pattern else None
    return weekly, (reg_dates or None), sessions_out


_WEEKDAY_INDEX = {"Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6}


def _count_pattern_sessions(
    beg: Any, end: Any, weekdays: set[str], exception_dates: list[Any]
) -> int:
    start_d = _parse_date(beg)
    end_d = _parse_date(end)
    if start_d is None or end_d is None or end_d < start_d or not weekdays:
        return 0
    indices = {_WEEKDAY_INDEX[w] for w in weekdays if w in _WEEKDAY_INDEX}
    if not indices:
        return 0
    total = 0
    d = start_d
    while d <= end_d:
        if d.weekday() in indices:
            total += 1
        d += timedelta(days=1)
    skipped = 0
    for ex in exception_dates:
        ex_d = _parse_exception_date(ex)
        if ex_d is None or ex_d < start_d or ex_d > end_d:
            continue
        if ex_d.weekday() in indices:
            skipped += 1
    return max(total - skipped, 0)


_EXCEPTION_DATE_FORMATS = (
    "%d %B %Y",
    "%d %b %Y",
    "%Y-%m-%d",
    "%m/%d/%Y",
)


def _parse_exception_date(val: Any) -> date | None:
    if val is None:
        return None
    if isinstance(val, dict):
        for k in ("date", "exception_date", "value"):
            out = _parse_exception_date(val.get(k))
            if out is not None:
                return out
        return None
    s = str(val).strip()
    for fmt in _EXCEPTION_DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return _parse_date(s)


def _split_weekday_tokens(s: Any) -> list[str]:
    if not s:
        return []
    import re as _re
    return [t for t in _re.split(r"[\s,;/]+|-", str(s)) if t]


def _parse_clock(s: Any) -> time | None:
    if not s:
        return None
    text = str(s).strip().upper().replace(" ", "")
    for fmt in ("%H:%M:%S", "%H:%M", "%I:%M%p", "%I:%M:%S%p"):
        try:
            return datetime.strptime(text, fmt).time()
        except ValueError:
            continue
    return None


def _parse_estimateprice(data: dict[str, Any]) -> Price | None:
    body = data.get("body") or {}
    ep = body.get("estimateprice") or {}
    prices = ep.get("prices")
    if not isinstance(prices, list) or not prices:
        return None

    resident: float | None = None
    non_resident: float | None = None
    raw_parts: list[str] = []
    for group in prices:
        details = group.get("details") if isinstance(group, dict) else None
        if not isinstance(details, list):
            continue
        for d in details:
            if not isinstance(d, dict):
                continue
            label = str(d.get("description") or "").strip()
            amt = _coerce_money(d.get("price"))
            if amt is None:
                continue
            raw_parts.append(f"{label}: {d.get('price')}")
            lo = label.lower()
            if "non" in lo and "resident" in lo and non_resident is None:
                non_resident = amt
            elif ("resident" in lo or "member" in lo) and resident is None:
                resident = amt
            elif resident is None:
                resident = amt
    if resident is None and non_resident is None:
        return None
    return Price(
        resident_price=resident,
        non_resident_price=non_resident,
        raw_price_text="; ".join(raw_parts) or None,
    )


def _coerce_money(s: Any) -> float | None:
    if s is None:
        return None
    text = str(s).replace("$", "").replace(",", "").strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def _normalize_category(raw: Any) -> str | None:
    if not raw:
        return None
    s = str(raw).lower()
    for canonical, keywords in _CATEGORY_KEYWORDS.items():
        if any(k in s for k in keywords):
            return canonical
    return str(raw)


_CATEGORY_KEYWORDS = {
    "swim": ["swim", "aquatic", "water"],
    "gymnastics": ["gymnast", "tumbling"],
    "music": ["music", "sing", "kindermusik"],
    "dance": ["dance", "ballet"],
    "art": ["art", "craft"],
    "sports": ["soccer", "basketball", "t-ball", "multisport", "sport"],
    "general": ["parent & tot", "toddler", "preschool", "early childhood"],
}
