"""Generic CSS-selector HTML scraper for one-off venue sites.

Driven entirely by `venue.custom_config`; ships configurations for
Kohl Children's Museum and Winnetka-Northfield Public Library District.
For "platform" sites with their own scraper (BiblioCommons, ActiveNet,
WebTrac, Amilia), use those — this scraper is the fallback for venues
whose only public surface is server-rendered HTML.

Config shape (all selectors are standard CSS unless noted)::

    custom_config:
      listing_url: https://example.org/events
      # Optional: paginate by `?<param>=N`. `start` defaults to 1; Drupal
      # uses 0. The loop stops when a page yields zero items, even if
      # max_pages hasn't been reached.
      pagination:
        param: page
        start: 0
        max_pages: 5
      item_selector: ".event-card"
      fields:
        # Text-content of the first matching node, joined with spaces.
        # Append `@attr` to read an attribute instead. Use `@attr` alone
        # to read an attribute on the item element itself (handy when the
        # item element IS the link).
        name: "h3 a"
        url: "h3 a@href"          # relative URLs resolved against base_url
        date_text: ".lc-date-icon"
        date_range_text: ".date-time"   # parses "January 24 – May 10"
        time_text: ".lc-event-info-item--time"
        audience_text: ".lc-event-info__item--colors"
        location_text: ".lc-event-info__item--categories"
        description: ".desc"
      # Fallback when no audience text is present (museums often have none).
      default_age:
        min_months: 24
        max_months: 144
      # Drop items whose blob contains any of these (lowercased substring).
      exclude_terms: ["adults only", "21+"]
      # If set, keep only items whose blob contains at least one of these.
      audience_filter: ["kids","family","children","babies","toddlers","tweens","teens","preschool"]

Date parsing tries two patterns in order:
- ``Tuesday, May 5, 2026`` (or ``Tue, May 5``) — typical for library
  calendars; also matched against ``aria-label`` / ``title`` attributes
  on the item, since BiblioCommons-style themes encode the canonical
  date there.
- ``January 24 – May 10`` (range) — typical for museum special exhibits;
  fills both ``start_date`` and ``end_date``.

If neither parses, the activity is still emitted with the raw text in
``schedule.raw_schedule_text`` so the iOS detail view shows *something*.
"""

from __future__ import annotations

import hashlib
from collections.abc import Iterator
from typing import Any
from urllib.parse import urljoin, urlparse

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
from kidsactivity.scrapers._audience import (
    audiences_to_age_range,
    clean_title,
    extract_audience_labels,
    format_date,
    format_time_range,
    join_nonempty,
    parse_date_line,
    parse_date_range,
    parse_time_range,
)
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


class CustomHtmlScraper(BaseScraper):
    DEFAULT_MAX_PAGES = 10

    def search(self, query: SearchQuery) -> Iterator[Activity]:
        cfg = self.venue.custom_config or {}
        listing_url: str | None = cfg.get("listing_url")
        item_selector: str | None = cfg.get("item_selector")
        if not listing_url or not item_selector:
            log.warning(
                "[%s] custom_html: listing_url + item_selector required in "
                "custom_config; skipping",
                self.venue.slug,
            )
            return
        if cfg.get("llm_fallback"):
            log.info(
                "[%s] custom_html: llm_fallback configured but not yet "
                "implemented — selectors must yield items on their own.",
                self.venue.slug,
            )

        seen: set[str] = set()
        for page_url in self._iter_page_urls(listing_url, cfg.get("pagination")):
            try:
                resp = self.http.get(page_url, headers={"Accept": "text/html"})
                resp.raise_for_status()
            except Exception as e:
                log.warning("[%s] custom_html fetch failed %s: %s", self.venue.slug, page_url, e)
                break
            soup = BeautifulSoup(resp.text, "html.parser")
            items = soup.select(item_selector)
            if not items:
                # Empty page = end of pagination.
                break
            emitted_on_page = 0
            for item in items:
                activity = self._parse_item(item, cfg)
                if activity is None:
                    continue
                if activity.activity_id in seen:
                    continue
                seen.add(activity.activity_id)
                emitted_on_page += 1
                yield activity
            if emitted_on_page == 0:
                # All items filtered out — usually means subsequent pages
                # are similarly off-target. Stop early to save bandwidth.
                break

    def _iter_page_urls(
        self,
        listing_url: str,
        pagination: dict[str, Any] | None,
    ) -> Iterator[str]:
        if not pagination:
            yield listing_url
            return
        param = pagination.get("param", "page")
        start = int(pagination.get("start", 1))
        max_pages = int(pagination.get("max_pages", self.DEFAULT_MAX_PAGES))
        for offset in range(max_pages):
            page_n = start + offset
            sep = "&" if "?" in listing_url else "?"
            yield f"{listing_url}{sep}{param}={page_n}"

    def _parse_item(self, item: Tag, cfg: dict[str, Any]) -> Activity | None:
        fields: dict[str, str] = cfg.get("fields") or {}
        name_raw = _extract_field(item, fields.get("name", "h3"))
        if not name_raw:
            return None
        name = clean_title(name_raw)
        if not name:
            return None

        url_raw = _extract_field(item, fields.get("url", "@href"))
        detail_url = self._resolve_url(url_raw)
        listing_url = cfg.get("listing_url") or str(self.venue.base_url)
        source_url = detail_url or listing_url

        # Build the searchable text blob from item text + selected attributes
        # (BiblioCommons-style themes hide the canonical date in aria-label).
        blob = item.get_text(" ", strip=True)
        for attr_name in ("aria-label", "title", "alt"):
            for el in item.find_all(attrs={attr_name: True}):
                v = el.get(attr_name)
                if v:
                    blob = f"{blob} {v}"
        low_blob = blob.lower()

        for term in (cfg.get("exclude_terms") or []):
            if term.lower() in low_blob:
                return None
        audience_filter = cfg.get("audience_filter") or []
        if audience_filter and not any(t.lower() in low_blob for t in audience_filter):
            return None

        # Date: try the explicit fields, then fall back to scanning the whole
        # blob. parse_date_line handles "Tuesday, May 5, 2026"; parse_date_range
        # handles "January 24 - May 10".
        date_text = _extract_field(item, fields.get("date_text"))
        date_range_text = _extract_field(item, fields.get("date_range_text"))
        time_text = _extract_field(item, fields.get("time_text"))
        audience_text = _extract_field(item, fields.get("audience_text"))
        location_text = _extract_field(item, fields.get("location_text"))
        description_text = _extract_field(item, fields.get("description"))

        start_date, day_of_week = parse_date_line(date_text or blob)
        end_date = start_date
        if start_date is None:
            r_start, r_end = parse_date_range(date_range_text or blob)
            start_date = r_start
            end_date = r_end
        start_time, end_time = parse_time_range(time_text or blob)

        weekly: list[WeeklyTime] = []
        if start_time and end_time and day_of_week:
            try:
                weekly = [WeeklyTime(day_of_week=day_of_week, start=start_time, end=end_time)]
            except Exception:
                weekly = []

        # Audience → age range. If no audience text on the item, use the
        # venue-level default (museums without per-event audience tags).
        audiences = extract_audience_labels(audience_text or blob)
        age_min, age_max, age_raw = audiences_to_age_range(audiences)
        default_age = cfg.get("default_age") or {}
        if age_min is None and age_max is None and (default_age.get("min_months") is not None or default_age.get("max_months") is not None):
            age_min = default_age.get("min_months")
            age_max = default_age.get("max_months")
            age_raw = age_raw or default_age.get("raw_age_text")
        age_range = AgeRange(min_months=age_min, max_months=age_max, raw_age_text=age_raw)

        schedule = Schedule(
            start_date=start_date,
            end_date=end_date,
            weekly_times=weekly,
            raw_schedule_text=join_nonempty(
                date_text or date_range_text or format_date(start_date),
                time_text or format_time_range(start_time, end_time),
            ),
            num_sessions=1 if start_date else None,
        )

        location = location_text or self.venue.name
        activity_id = self._activity_id(detail_url, name, start_date)
        description = (description_text or None) if description_text and len(description_text) > 20 else None

        return Activity(
            name=name,
            venue_name=self.venue.name,
            venue_slug=self.venue.slug,
            venue_type=self.venue.venue_type,
            schedule=schedule,
            price=Price(resident_price=0.0, raw_price_text="Free"),
            age_range=age_range,
            location=location,
            registration=Registration(),  # custom_html sites rarely surface reg state in the listing
            source_url=source_url,
            activity_id=activity_id,
            category=None,
            raw_category=", ".join(audiences) if audiences else None,
            description=description,
        )

    def _resolve_url(self, raw: str) -> str | None:
        if not raw:
            return None
        if raw.startswith(("http://", "https://")):
            return raw
        # urljoin handles "/event/foo" and "event/foo" against the base_url.
        return urljoin(str(self.venue.base_url), raw)

    def _activity_id(self, detail_url: str | None, name: str, start_date) -> str:
        if detail_url:
            path = urlparse(detail_url).path.strip("/")
            if path:
                return f"custom_html:{self.venue.slug}:{path}"
        # Last resort: hash name + date so reruns are stable.
        h = hashlib.sha1(
            f"{self.venue.slug}|{name}|{start_date or ''}".encode("utf-8")
        ).hexdigest()[:16]
        return f"custom_html:{self.venue.slug}:{h}"


def _extract_field(item: Tag, selector: str | None) -> str:
    """Extract text or attribute from the first node matching `selector`.

    `"a@href"`     → attribute on the first <a> descendant.
    `"@href"`      → attribute on the item element itself.
    `".x .y"`      → joined text content of the first match.
    Returns "" when the selector finds nothing.
    """
    if not selector:
        return ""
    sel, _, attr = selector.partition("@")
    sel = sel.strip()
    attr = attr.strip()
    if not sel:
        # `@attr` form: read attribute on the item itself.
        if attr:
            v = item.get(attr) or ""
            return v if isinstance(v, str) else " ".join(v)
        return ""
    target = item.select_one(sel)
    if target is None:
        return ""
    if attr:
        v = target.get(attr) or ""
        return v if isinstance(v, str) else " ".join(v)
    return target.get_text(" ", strip=True)
