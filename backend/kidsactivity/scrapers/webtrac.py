"""WebTrac (Vermont Systems) scraper.

Two deployment shapes are supported, both running the same NextGen HTML
template (post-2022):

1. Hosted on ``web2.myvscloud.com/wbwsc/{sitecode}.wsc/`` — 301-redirects
   to ``{sitecode}.myvscloud.com/webtrac/web/search.html``. Identified
   by the ``sitecode`` field in venues.yaml.
2. Self-hosted under the venue's own subdomain (e.g. Glenview at
   ``webtrrac.glenviewparks.org/WEB/wbwsc/webtrac.wsc/``). Identified
   by ``sitecode`` being absent.

The hosted origin sits behind Cloudflare — a real-browser TLS fingerprint
is required, so this scraper uses ``curl_cffi`` (impersonate=chrome124)
directly instead of the shared httpx ``HttpClient``. The ``http``
injected by BaseScraper is accepted but unused.

Flow: GET search page once for ``_csrf_token`` + cookies, then GET it
again with ``search=yes`` and ``page=N`` for each page. Optional detail
backfill for age + fee + holiday-adjusted session count.
"""

from __future__ import annotations

import re
import threading
import time as _time
from collections.abc import Iterator
from datetime import date, datetime, time, timedelta
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup, Tag
from curl_cffi import requests as creq

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

_DAY_MAP = {
    "m": "Mon", "tu": "Tue", "w": "Wed", "th": "Thu",
    "f": "Fri", "sa": "Sat", "su": "Sun",
}

_WEBTRAC_WEEKDAY_INDEX = {
    "Mon": 0, "Tue": 1, "Wed": 2, "Thu": 3, "Fri": 4, "Sat": 5, "Sun": 6,
}

# Per-host rate limiter — the shared HttpClient's limiter doesn't see
# these requests because curl_cffi bypasses it.
_HOST_LAST_HIT: dict[str, float] = {}
_HOST_LOCK = threading.Lock()
_HOST_MIN_INTERVAL = 1.0


def _rate_limit(host: str) -> None:
    with _HOST_LOCK:
        last = _HOST_LAST_HIT.get(host, 0.0)
        delay = _HOST_MIN_INTERVAL - (_time.monotonic() - last)
        if delay > 0:
            _time.sleep(delay)
        _HOST_LAST_HIT[host] = _time.monotonic()


class WebTracScraper(BaseScraper):
    MAX_PAGES = 20
    MAX_DETAIL_BACKFILL = 80

    # Months value that lands on each WebTrac age bucket via
    # `_age_bucket_from_months` — covers the 0.25 / 0.5 / 0.75 / 1..17
    # selects the platform exposes. Used by `crawl_all` to vacuum every
    # age bucket in one pass.
    _CRAWL_BUCKETS_MONTHS = (
        0, 6, 9, 12, 24, 36, 48, 60, 72, 84,
        96, 108, 120, 132, 144, 156, 168, 180, 192, 204,
    )

    def crawl_all(self) -> list[Activity]:
        """Iterate every WebTrac age bucket and dedupe by activity_id.

        WebTrac's server requires ≥1 filter and only accepts a single age
        bucket per request, so a no-filter crawl needs explicit fan-out.
        Cache hits make repeat runs cheap.
        """
        seen: set[str] = set()
        out: list[Activity] = []
        for months in self._CRAWL_BUCKETS_MONTHS:
            q = SearchQuery(zipcode="00000", distance_miles=0, age_min_months=months)
            for a in self.search(q):
                if a.activity_id in seen:
                    continue
                seen.add(a.activity_id)
                out.append(a)
        return out

    def search(self, query: SearchQuery) -> Iterator[Activity]:
        entry = self._entry_url()
        if entry is None:
            log.warning(
                "[%s] WebTrac scraper: no sitecode or base_url; skipping",
                self.venue.slug,
            )
            return

        sess = creq.Session(impersonate="chrome124")

        try:
            token, results_url = self._prime(sess, entry)
        except Exception as e:
            log.warning("[%s] WebTrac session prime failed: %s", self.venue.slug, e)
            return

        common = {
            "module": "AR",
            "display": "Listing",
            "sort": "Description",
            "search": "yes",
            "_csrf_token": token,
        }
        if query.keyword:
            common["keyword"] = query.keyword
        age_bucket = _age_bucket_from_months(query.age_min_months)
        if age_bucket is not None:
            common["age"] = age_bucket

        # WebTrac NextGen refuses to return results without at least one
        # filter ("A minimum of 1 Search Filter is required…").
        if "keyword" not in common and "age" not in common:
            log.warning(
                "[%s] WebTrac requires keyword or age filter; skipping",
                self.venue.slug,
            )
            return

        host = urlparse(results_url).netloc
        collected: list[Activity] = []
        for page in range(1, self.MAX_PAGES + 1):
            _rate_limit(host)
            try:
                resp = sess.get(
                    results_url,
                    params={**common, "page": str(page)},
                    timeout=30,
                )
                resp.raise_for_status()
            except Exception as e:
                log.warning(
                    "[%s] WebTrac page %d failed: %s", self.venue.slug, page, e
                )
                break

            soup = BeautifulSoup(resp.text, "lxml")
            rows = soup.select("table#arwebsearch_output_table tr")[1:]
            if not rows:
                break
            for tr in rows:
                activity = self._parse_row(tr)
                if activity is not None:
                    collected.append(activity)
            if not _has_next_page(soup, page):
                break

        for activity in collected[: self.MAX_DETAIL_BACKFILL]:
            if str(activity.source_url) == str(self.venue.base_url):
                yield activity
                continue
            _rate_limit(host)
            yield self._backfill_from_detail(sess, activity)
        for activity in collected[self.MAX_DETAIL_BACKFILL:]:
            yield activity

    def _entry_url(self) -> str | None:
        base = str(self.venue.base_url)
        if not base:
            return None
        if not base.endswith("/"):
            base += "/"
        return base + "search.html"

    def _prime(self, sess: creq.Session, entry: str) -> tuple[str, str]:
        resp = sess.get(
            entry,
            params={"module": "AR", "display": "Listing"},
            timeout=30,
            allow_redirects=True,
        )
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
        tok = soup.find("input", attrs={"name": "_csrf_token"})
        value = tok.get("value") if tok else None
        if not value:
            raise RuntimeError("no _csrf_token on entry page")
        return value, str(resp.url)

    def _parse_row(self, row: Tag) -> Activity | None:
        def cell(*titles: str) -> str:
            for t in titles:
                c = row.select_one(f"[data-title='{t}']")
                if c:
                    text = c.get_text(" ", strip=True)
                    if text:
                        return text
            return ""

        name = cell("Description")
        if not name:
            return None
        wt_id = cell("Activity #", "Activity Code")

        raw_ages = cell("Ages") or cell("Grades")

        age_range = _parse_age_years(raw_ages)
        if age_range.min_months is None and age_range.max_months is None:
            age_range = _age_range_from_description(name) or age_range

        source_url = _pick_detail_url(row, str(self.venue.base_url))

        return Activity(
            name=name,
            venue_name=self.venue.name,
            venue_slug=self.venue.slug,
            venue_type=self.venue.venue_type,
            schedule=_parse_schedule(
                cell("Dates"), cell("Times"), cell("Days", "Day")
            ),
            price=_parse_price(
                cell(
                    "Res / NonRes", "Res/NonRes", "Res/NR Price",
                    "Res/Non-Res Fee", "Cost", "Fees", "Fee", "Price",
                )
            ),
            age_range=age_range,
            location=cell("Location"),
            registration=_parse_availability(
                cell("Availability", "Status", "Add to Cart") or _first_col_text(row)
            ),
            source_url=source_url,
            activity_id=f"webtrac:{self.venue.slug}:{wt_id or name[:40]}",
            category=None,
            raw_category=None,
            description=None,
        )

    def _backfill_from_detail(self, sess: creq.Session, activity: Activity) -> Activity:
        url = str(activity.source_url)
        try:
            resp = sess.get(url, timeout=20)
            resp.raise_for_status()
            html = resp.text
        except Exception as e:
            log.debug("[%s] detail fetch failed for %s: %s",
                      self.venue.slug, url, e)
            return activity

        text = re.sub(r"<script[\s\S]*?</script>", "", html)
        text = re.sub(r"<style[\s\S]*?</style>", "", text)
        text = re.sub(r"<[^>]+>", " ", text)
        text = re.sub(r"\s+", " ", text)

        new_age = activity.age_range
        m = _RE_AGE_RANGE_DIRECT.search(text) or _RE_AGE_RANGE_ELIGIBILITY.search(text)
        if m:
            lo = float(m.group(1))
            hi = float(m.group(2))
            new_age = AgeRange(
                min_months=int(round(lo * 12)),
                max_months=int(round(hi * 12)),
                raw_age_text=m.group(0),
            )
        else:
            m2 = _RE_AGE_SINGLE.search(text)
            if m2:
                v = float(m2.group(1))
                new_age = AgeRange(
                    min_months=int(round(v * 12)),
                    max_months=int(round(v * 12)),
                    raw_age_text=m2.group(0),
                )

        new_price = activity.price
        if activity.price.resident_price is None:
            dollars = re.findall(r"\$(\d+(?:\.\d{1,2})?)", html)
            if dollars:
                from collections import Counter
                top = Counter(dollars).most_common(1)[0][0]
                new_price = Price(
                    resident_price=float(top),
                    non_resident_price=None,
                    raw_price_text=f"${top}",
                )

        new_schedule = activity.schedule
        if new_schedule.num_sessions is None:
            sessions = _num_sessions_from_detail(text, new_schedule)
            if sessions is not None:
                new_schedule = new_schedule.model_copy(update={"num_sessions": sessions})

        if (
            new_age is activity.age_range
            and new_price is activity.price
            and new_schedule is activity.schedule
        ):
            return activity
        return activity.model_copy(
            update={
                "age_range": new_age,
                "price": new_price,
                "schedule": new_schedule,
            }
        )


_RE_AGE_RANGE_DIRECT = re.compile(
    r"(?:Ages?|Grades?)\s+(\d+(?:\.\d+)?)\s*(?:[-–—]|\bto\b)\s*(\d+(?:\.\d+)?)",
    re.I,
)
_RE_AGE_RANGE_ELIGIBILITY = re.compile(
    r"above\s+(?:Age|Grade)\s+(\d+(?:\.\d+)?)[\s\S]{0,80}?"
    r"below\s+(?:Age|Grade)\s+(\d+(?:\.\d+)?)",
    re.I,
)
_RE_AGE_SINGLE = re.compile(
    r"(?:\bAges?|\bGrades?)\s+(\d+(?:\.\d+)?)\b",
    re.I,
)


_RE_DETAIL_DATE_RANGE = re.compile(
    r"Date\(s\):\s*(\d{1,2}/\d{1,2}/\d{2,4})\s*[-–]\s*(\d{1,2}/\d{1,2}/\d{2,4})"
)
_RE_DETAIL_HOLIDAYS = re.compile(
    r"Holiday\(s\)\s*(.*?)(?:\s*(?:Eligibility|Registration Event|Activity Details|Fees|$))",
    re.I,
)
_RE_HOLIDAY_DATE = re.compile(r"(\d{1,2}/\d{1,2}(?:/\d{2,4})?)")


def _num_sessions_from_detail(text: str, schedule: Schedule) -> int | None:
    start, end = None, None
    m = _RE_DETAIL_DATE_RANGE.search(text)
    if m:
        start = _parse_date(m.group(1))
        end = _parse_date(m.group(2))
    if start is None or end is None:
        start = schedule.start_date
        end = schedule.end_date
    if start is None or end is None:
        return None
    weekday_indices = {
        _WEBTRAC_WEEKDAY_INDEX[wt.day_of_week]
        for wt in schedule.weekly_times
        if wt.day_of_week in _WEBTRAC_WEEKDAY_INDEX
    }
    if not weekday_indices:
        return None

    total = 0
    d = start
    while d <= end:
        if d.weekday() in weekday_indices:
            total += 1
        d += timedelta(days=1)

    skipped: set[date] = set()
    h = _RE_DETAIL_HOLIDAYS.search(text)
    if h:
        for raw in _RE_HOLIDAY_DATE.findall(h.group(1)):
            hd = _parse_holiday_date(raw, year=start.year, end_year=end.year)
            if hd is not None and start <= hd <= end and hd.weekday() in weekday_indices:
                skipped.add(hd)

    return max(total - len(skipped), 0)


def _parse_holiday_date(raw: str, year: int, end_year: int) -> date | None:
    parts = raw.split("/")
    if len(parts) == 3:
        return _parse_date(raw)
    if len(parts) != 2:
        return None
    try:
        month, day = int(parts[0]), int(parts[1])
    except ValueError:
        return None
    try:
        candidate = date(year, month, day)
    except ValueError:
        return None
    if end_year != year:
        try:
            alt = date(end_year, month, day)
        except ValueError:
            return candidate
        if month < 6 and end_year > year:
            return alt
    return candidate


def _first_col_text(row: Tag) -> str:
    cells = row.find_all(["td", "th"])
    return cells[0].get_text(" ", strip=True) if cells else ""


def _pick_detail_url(row: Tag, base: str) -> str:
    desc_cell = row.select_one("[data-title='Description']")
    if desc_cell:
        a = desc_cell.find("a", href=True)
        if a:
            return urljoin(base, a["href"])
    a2 = row.find("a", href=lambda h: h and "iteminfo.html" in h)
    if a2:
        return urljoin(base, a2["href"])
    return base


def _has_next_page(soup: BeautifulSoup, current: int) -> bool:
    for btn in soup.select("button[data-click-set-name='page']"):
        try:
            if int(btn.get("data-click-set-value") or "0") > current:
                return True
        except ValueError:
            continue
    return False


def _parse_schedule(raw_dates: str, raw_times: str, raw_days: str) -> Schedule:
    start_date = end_date = None
    dates = re.findall(r"(\d{1,2}/\d{1,2}/\d{2,4})", raw_dates)
    if len(dates) >= 1:
        start_date = _parse_date(dates[0])
    if len(dates) >= 2:
        end_date = _parse_date(dates[1])

    weekly: list[WeeklyTime] = []
    tm = re.search(
        r"(\d{1,2}:\d{2}\s*(?:am|pm))\s*[-–]\s*(\d{1,2}:\d{2}\s*(?:am|pm))",
        raw_times,
        re.I,
    )
    if tm:
        start = _parse_time(tm.group(1))
        end = _parse_time(tm.group(2))
        if start and end:
            seen: set[str] = set()
            for tok in re.findall(r"[A-Z][a-z]?", raw_days):
                canon = _DAY_MAP.get(tok.lower())
                if canon and canon not in seen:
                    seen.add(canon)
                    weekly.append(
                        WeeklyTime(day_of_week=canon, start=start, end=end)
                    )

    raw = " ".join(x for x in (raw_dates, raw_days, raw_times) if x)
    return Schedule(
        start_date=start_date,
        end_date=end_date,
        weekly_times=weekly,
        raw_schedule_text=raw or None,
    )


def _parse_price(raw: str) -> Price:
    amounts: list[float] = []
    for m in re.findall(r"\$?\s*(\d[\d,]*(?:\.\d{1,2})?)", raw):
        try:
            amounts.append(float(m.replace(",", "")))
        except ValueError:
            continue
    res = amounts[0] if amounts else None
    non = amounts[1] if len(amounts) >= 2 else None
    return Price(
        resident_price=res, non_resident_price=non, raw_price_text=raw or None
    )


def _parse_age_years(raw: str) -> AgeRange:
    m = re.match(r"\s*(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)", raw)
    min_m = max_m = None
    if m:
        min_m = int(round(float(m.group(1)) * 12))
        max_m = int(round(float(m.group(2)) * 12))
    return AgeRange(min_months=min_m, max_months=max_m, raw_age_text=raw or None)


def _age_range_from_description(description: str) -> AgeRange | None:
    m = re.search(
        r"\b(?:ages?|age)\s+(\d+(?:\.\d+)?)\s*[-–]\s*(\d+(?:\.\d+)?)",
        description,
        re.I,
    )
    if m:
        return AgeRange(
            min_months=int(round(float(m.group(1)) * 12)),
            max_months=int(round(float(m.group(2)) * 12)),
            raw_age_text=m.group(0),
        )
    m2 = re.search(
        r"\b(\d+(?:\.\d+)?)\s*(?:yr|year)s?\s*old\b|\bage\s+(\d+(?:\.\d+)?)\b",
        description,
        re.I,
    )
    if m2:
        raw = next(g for g in m2.groups() if g)
        months = int(round(float(raw) * 12))
        return AgeRange(min_months=months, max_months=months, raw_age_text=m2.group(0))
    return None


def _age_bucket_from_months(age_min_months: int | None) -> str | None:
    if age_min_months is None:
        return None
    if age_min_months < 12:
        for threshold, bucket in ((9, "0.75"), (6, "0.5"), (3, "0.25")):
            if age_min_months >= threshold:
                return bucket
        return "0.25"
    years = min(17, age_min_months // 12)
    return str(years)


def _parse_availability(raw: str) -> Registration:
    low = raw.lower()
    is_open = None
    if any(k in low for k in ("unavailable", "waitlist", "closed", "full", "not accepting", "cancelled")):
        is_open = False
    elif any(k in low for k in ("available", "add to selection", "add to cart", "enroll", "open")):
        is_open = True
    return Registration(is_open=is_open, raw_text=raw or None)


def _parse_date(s: str) -> date | None:
    for fmt in ("%m/%d/%Y", "%m/%d/%y"):
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None


def _parse_time(s: str) -> time | None:
    s = s.strip().upper().replace(" ", "")
    for fmt in ("%I:%M%p", "%H:%M"):
        try:
            return datetime.strptime(s, fmt).time()
        except ValueError:
            continue
    return None
