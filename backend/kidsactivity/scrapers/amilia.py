"""Amilia Store scraper (per-activity).

Amilia stores expose three layers we chain through to reach individual
classes:

1. **Program listing** — ``GET /store/en/{org}/shop/programs``: server-
   rendered HTML; each ``<a class="store-program-result__link">`` links
   to a program detail page.
2. **Program detail page** — ``GET /shop/programs/{programId}``. The
   activity list inside is XHR-loaded, but the surrounding HTML carries
   subcategory anchors as ``<button data-program-id data-sub-category-id
   data-fetch-url=".../GetSubCategoryDetail">``. We mine those.
3. **Subcategory activity list** — ``POST /api/Program/GetSubCategoryDetail``
   with ``{programId, subCategoryId}``. Returns an HTML fragment of
   ``<li class="activity-list-item">`` rows. **No age field.**
4. **Activity detail page** — ``GET /shop/activities/{activityId}``: the
   only place ``Required age:`` appears, so age-aware filters require
   per-activity detail fetches (capped via MAX_ACTIVITY_DETAILS).
"""

from __future__ import annotations

import re
from collections.abc import Iterator
from datetime import date, datetime, time
from typing import Any
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from kidsactivity.logging import get_logger
from kidsactivity.models import (
    Activity,
    AgeRange,
    DayOfWeek,
    Price,
    Registration,
    Schedule,
    SearchQuery,
    WeeklyTime,
)
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


_DAY_TO_ABBR: dict[str, DayOfWeek] = {
    "monday": "Mon", "mon": "Mon",
    "tuesday": "Tue", "tue": "Tue", "tues": "Tue",
    "wednesday": "Wed", "wed": "Wed",
    "thursday": "Thu", "thu": "Thu", "thurs": "Thu",
    "friday": "Fri", "fri": "Fri",
    "saturday": "Sat", "sat": "Sat",
    "sunday": "Sun", "sun": "Sun",
}

_MONTHS = {
    "january": 1, "february": 2, "march": 3, "april": 4, "may": 5,
    "june": 6, "july": 7, "august": 8, "september": 9, "october": 10,
    "november": 11, "december": 12,
}


class AmiliaScraper(BaseScraper):
    MAX_ACTIVITY_DETAILS = 2000

    _BROWSER_HEADERS = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    }

    def search(self, query: SearchQuery) -> Iterator[Activity]:
        slug = self.venue.amilia_org_slug
        if not slug:
            log.warning(
                "[%s] Amilia scraper needs venue.amilia_org_slug; none configured",
                self.venue.slug,
            )
            return

        programs = list(self._list_programs(slug))
        log.debug("[%s] Amilia: %d programs", self.venue.slug, len(programs))

        activities: list[dict[str, Any]] = []
        for prog in programs:
            try:
                anchors = self._discover_subcategories(slug, prog["program_id"])
            except Exception as e:
                log.warning(
                    "[%s] program %s detail fetch failed: %s",
                    self.venue.slug, prog["program_id"], e,
                )
                continue
            for program_id, sub_cat_id in anchors:
                try:
                    rows = self._fetch_subcategory_activities(
                        slug, program_id, sub_cat_id
                    )
                except Exception as e:
                    log.warning(
                        "[%s] subcat %s/%s fetch failed: %s",
                        self.venue.slug, program_id, sub_cat_id, e,
                    )
                    continue
                for row in rows:
                    row["program_name"] = prog["name"]
                    activities.append(row)

        log.debug(
            "[%s] Amilia: discovered %d activities across %d programs",
            self.venue.slug, len(activities), len(programs),
        )

        seen_ids: set[str] = set()
        details_fetched = 0
        for a in activities:
            if a["activity_id"] in seen_ids:
                continue
            seen_ids.add(a["activity_id"])

            if query.keyword and query.keyword.lower() not in a["name"].lower():
                continue

            age_range = AgeRange()
            location = ""
            registration = Registration()
            description: str | None = None
            schedule_text = a.get("schedule_text") or ""
            schedule = _parse_schedule(schedule_text)
            price = _parse_price(a.get("price_text") or "")

            if details_fetched < self.MAX_ACTIVITY_DETAILS:
                details_fetched += 1
                try:
                    detail = self._fetch_activity_detail(slug, a["activity_id"])
                except Exception as e:
                    log.warning(
                        "[%s] activity %s detail fetch failed: %s",
                        self.venue.slug, a["activity_id"], e,
                    )
                    detail = {}
                if detail:
                    age_range = detail.get("age_range") or age_range
                    location = detail.get("location") or location
                    registration = detail.get("registration") or registration
                    description = detail.get("description") or description
                    if detail.get("schedule") is not None:
                        schedule = detail["schedule"]
                    if detail.get("price") is not None:
                        price = detail["price"]
                    if detail.get("name"):
                        a["name"] = detail["name"]
            elif details_fetched == self.MAX_ACTIVITY_DETAILS:
                log.warning(
                    "[%s] Amilia hit MAX_ACTIVITY_DETAILS=%d cap; remaining "
                    "activities yielded without age",
                    self.venue.slug, self.MAX_ACTIVITY_DETAILS,
                )
                details_fetched += 1  # only log once

            yield Activity(
                name=a["name"],
                venue_name=self.venue.name,
                venue_slug=self.venue.slug,
                venue_type=self.venue.venue_type,
                schedule=schedule,
                price=price,
                age_range=age_range,
                location=location,
                registration=registration,
                source_url=a["source_url"],
                activity_id=f"amilia:{self.venue.slug}:{a['activity_id']}",
                category=None,
                raw_category=a.get("program_name"),
                description=description,
            )

    def _list_programs(self, slug: str) -> Iterator[dict[str, Any]]:
        url = f"https://app.amilia.com/store/en/{slug}/shop/programs"
        resp = self.http.get(url, headers=self._BROWSER_HEADERS)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
        seen: set[str] = set()
        for link in soup.select(
            "a.store-program-result__link, a[href*='/shop/programs/']"
        ):
            href = link.get("href") or ""
            m = re.search(r"/shop/programs/(\d+)", href)
            if not m:
                continue
            program_id = m.group(1)
            if program_id in seen:
                continue
            seen.add(program_id)
            title_el = link.select_one(
                "h2.store-item-title, h2[itemprop='name'], h3, h4"
            )
            name = title_el.get_text(" ", strip=True) if title_el else ""
            yield {
                "program_id": program_id,
                "name": name,
                "url": urljoin("https://app.amilia.com", href),
            }

    def _discover_subcategories(
        self, slug: str, program_id: str
    ) -> list[tuple[str, str]]:
        url = f"https://app.amilia.com/store/en/{slug}/shop/programs/{program_id}"
        resp = self.http.get(url, headers=self._BROWSER_HEADERS)
        resp.raise_for_status()
        button_pattern = re.compile(
            r"<button[^>]*data-fetch-url=\"[^\"]*GetSubCategoryDetail\"[^>]*>",
            re.IGNORECASE,
        )
        sub_id_re = re.compile(r"data-sub-category-id=\"(\d+)\"")
        prog_id_re = re.compile(r"data-program-id=\"(\d+)\"")
        seen: set[tuple[str, str]] = set()
        out: list[tuple[str, str]] = []
        for match in button_pattern.finditer(resp.text):
            tag = match.group(0)
            sub_m = sub_id_re.search(tag)
            prog_m = prog_id_re.search(tag)
            if not sub_m or not prog_m:
                continue
            key = (prog_m.group(1), sub_m.group(1))
            if key in seen:
                continue
            seen.add(key)
            out.append(key)
        return out

    def _fetch_subcategory_activities(
        self, slug: str, program_id: str, sub_cat_id: str
    ) -> list[dict[str, Any]]:
        url = f"https://app.amilia.com/store/en/{slug}/api/Program/GetSubCategoryDetail"
        resp = self.http.post(
            url,
            json={"programId": int(program_id), "subCategoryId": int(sub_cat_id)},
            headers={**self._BROWSER_HEADERS, "X-Requested-With": "XMLHttpRequest"},
        )
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "lxml")
        out: list[dict[str, Any]] = []
        for li in soup.select("li.activity-list-item"):
            li_id = li.get("id", "")
            m = re.search(r"activity-(\d+)", li_id)
            activity_id = m.group(1) if m else None
            link = li.select_one("a[href*='/shop/activities/']")
            href = link.get("href") if link else None
            if not activity_id and href:
                m2 = re.search(r"/shop/activities/(\d+)", href)
                activity_id = m2.group(1) if m2 else None
            if not activity_id:
                continue
            title_el = li.select_one(".activity-list-item-info-header-title")
            name = title_el.get_text(" ", strip=True) if title_el else ""
            sched_el = li.select_one(".activity-list-item-info-header-schedule")
            sched_text = sched_el.get_text(" ", strip=True) if sched_el else ""
            price_el = li.select_one(".activity-list-item-info-prices .price-wrap")
            price_text = price_el.get_text(" ", strip=True) if price_el else ""
            source_url = (
                urljoin("https://app.amilia.com", href)
                if href
                else f"https://app.amilia.com/store/en/{slug}/shop/activities/{activity_id}"
            )
            out.append(
                {
                    "activity_id": activity_id,
                    "name": name,
                    "schedule_text": sched_text,
                    "price_text": price_text,
                    "source_url": source_url,
                }
            )
        return out

    def _fetch_activity_detail(
        self, slug: str, activity_id: str
    ) -> dict[str, Any]:
        url = f"https://app.amilia.com/store/en/{slug}/shop/activities/{activity_id}"
        resp = self.http.get(url, headers=self._BROWSER_HEADERS)
        resp.raise_for_status()
        return _parse_activity_detail(resp.text)


def _parse_activity_detail(html: str) -> dict[str, Any]:
    soup = BeautifulSoup(html, "lxml")
    out: dict[str, Any] = {}

    title_el = soup.select_one("h1.store-h1")
    if title_el:
        out["name"] = title_el.get_text(" ", strip=True)

    age_text = _strong_value(soup, "Required age")
    if age_text:
        out["age_range"] = _parse_age_range(age_text)

    location_text = _strong_value(soup, "Location")
    if location_text:
        out["location"] = location_text

    price_text = _strong_value(soup, "Price")
    if price_text:
        out["price"] = _parse_price(price_text)

    description_el = soup.select_one("[itemprop='description']")
    if description_el:
        out["description"] = description_el.get_text(" ", strip=True)

    schedule = _parse_schedule_from_detail(soup)
    if schedule.start_date or schedule.end_date or schedule.weekly_times:
        out["schedule"] = schedule

    avail_meta = soup.select_one("meta[itemprop='availability']")
    if avail_meta is not None:
        is_open = (avail_meta.get("content") or "").strip().lower() == "available"
        out["registration"] = Registration(is_open=is_open)

    return out


def _strong_value(soup: BeautifulSoup, label: str) -> str | None:
    for strong in soup.find_all("strong"):
        s = strong.get_text(" ", strip=True).rstrip(":")
        if s.lower() == label.lower():
            parent = strong.parent
            if parent is None:
                continue
            text = parent.get_text(" ", strip=True)
            text = re.sub(rf"^{re.escape(s)}\s*:\s*", "", text, flags=re.IGNORECASE)
            return text.strip() or None
    return None


def _parse_age_range(text: str) -> AgeRange:
    raw = text.strip()
    low = raw.lower()

    def _to_months(value: float, unit: str) -> int:
        return int(round(value * 12)) if unit.startswith(("year", "yr")) else int(round(value))

    m = re.search(
        r"(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)\s*(year|yr|month|mo)s?",
        low,
    )
    if m:
        lo = _to_months(float(m.group(1)), m.group(3))
        hi = _to_months(float(m.group(2)), m.group(3))
        return AgeRange(min_months=lo, max_months=hi, raw_age_text=raw)

    m = re.search(
        r"(\d+(?:\.\d+)?)\s*(year|yr|month|mo)s?\s+and\s+(?:up|older|over)",
        low,
    )
    if m:
        lo = _to_months(float(m.group(1)), m.group(2))
        return AgeRange(min_months=lo, max_months=None, raw_age_text=raw)

    m = re.search(
        r"up\s+to\s+(\d+(?:\.\d+)?)\s*(year|yr|month|mo)s?",
        low,
    )
    if m:
        hi = _to_months(float(m.group(1)), m.group(2))
        return AgeRange(min_months=None, max_months=hi, raw_age_text=raw)
    m = re.search(
        r"(\d+(?:\.\d+)?)\s*(year|yr|month|mo)s?\s+and\s+(?:under|younger|below)",
        low,
    )
    if m:
        hi = _to_months(float(m.group(1)), m.group(2))
        return AgeRange(min_months=None, max_months=hi, raw_age_text=raw)

    m = re.search(
        r"(\d+(?:\.\d+)?)\s*(year|yr|month|mo)s?\s+old",
        low,
    )
    if m:
        v = _to_months(float(m.group(1)), m.group(2))
        return AgeRange(min_months=v, max_months=v, raw_age_text=raw)

    return AgeRange(raw_age_text=raw)


def _parse_price(text: str) -> Price:
    if not text:
        return Price()
    m = re.search(r"\$\s*(\d[\d,]*(?:\.\d{1,2})?)", text)
    if not m:
        return Price(raw_price_text=text)
    try:
        amount = float(m.group(1).replace(",", ""))
    except ValueError:
        return Price(raw_price_text=text)
    return Price(
        resident_price=amount,
        non_resident_price=amount,
        raw_price_text=text,
    )


def _parse_schedule(text: str) -> Schedule:
    if not text:
        return Schedule()
    weekly_times = _extract_weekly_times(text)
    start, end = _extract_date_range(text)
    return Schedule(
        weekly_times=weekly_times,
        start_date=start,
        end_date=end,
        raw_schedule_text=text or None,
    )


def _parse_schedule_from_detail(soup: BeautifulSoup) -> Schedule:
    container = soup.select_one("div.schedule-container")
    if container is None:
        text = " ".join(
            p.get_text(" ", strip=True) for p in soup.select("p")
            if p.find("strong")
            and p.find("strong").get_text(strip=True).rstrip(":").lower()
            in {"start date", "schedule", "end date"}
        )
        return _parse_schedule(text)
    parent = container.parent or container
    text = parent.get_text(" ", strip=True)
    return _parse_schedule(text)


def _extract_weekly_times(text: str) -> list[WeeklyTime]:
    out: list[WeeklyTime] = []
    seen: set[tuple[str, time, time]] = set()
    pattern = re.compile(
        r"((?:(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday|"
        r"mon|tue|tues|wed|thu|thurs|fri|sat|sun)s?(?:\s*[,&]\s*|\s+and\s+|\s+)?)+)"
        r"[,\s]+"
        r"(\d{1,2}):(\d{2})(?:\s*|\s*&nbsp;)*([AaPp][Mm])"
        r"\s*[-–]\s*"
        r"(\d{1,2}):(\d{2})(?:\s*|\s*&nbsp;)*([AaPp][Mm])",
        re.IGNORECASE,
    )
    for m in pattern.finditer(text):
        days_blob = m.group(1)
        start = _to_time(int(m.group(2)), int(m.group(3)), m.group(4))
        end = _to_time(int(m.group(5)), int(m.group(6)), m.group(7))
        for day in _extract_days(days_blob):
            key = (day, start, end)
            if key in seen:
                continue
            seen.add(key)
            out.append(WeeklyTime(day_of_week=day, start=start, end=end))
    return out


def _extract_days(blob: str) -> list[DayOfWeek]:
    days: list[DayOfWeek] = []
    for token in re.split(r"[,&]|\band\b|\s+", blob.strip(), flags=re.IGNORECASE):
        token = token.strip().lower().rstrip("s")
        if not token:
            continue
        abbr = _DAY_TO_ABBR.get(token)
        if abbr and abbr not in days:
            days.append(abbr)
    return days


def _to_time(hour: int, minute: int, ampm: str) -> time:
    h = hour % 12
    if ampm.lower().startswith("p"):
        h += 12
    return time(h, minute)


def _extract_date_range(text: str) -> tuple[date | None, date | None]:
    m = re.search(
        r"from\s+([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})\s+until\s+"
        r"([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})",
        text,
        re.IGNORECASE,
    )
    if m:
        start = _make_date(m.group(1), m.group(2), m.group(3))
        end = _make_date(m.group(4), m.group(5), m.group(6))
        return start, end
    m = re.search(
        r"start\s+date[:\s]+(?:[A-Za-z]+,\s+)?([A-Za-z]+)\s+(\d{1,2})\s*,?\s*(\d{4})",
        text,
        re.IGNORECASE,
    )
    if m:
        start = _make_date(m.group(1), m.group(2), m.group(3))
        return start, None
    m = re.search(
        r"\bon\s+([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})",
        text,
        re.IGNORECASE,
    )
    if m:
        d = _make_date(m.group(1), m.group(2), m.group(3))
        return d, d
    return None, None


def _make_date(month_name: str, day: str, year: str) -> date | None:
    month = _MONTHS.get(month_name.lower())
    if not month:
        return None
    try:
        return date(int(year), month, int(day))
    except (ValueError, TypeError):
        return None
