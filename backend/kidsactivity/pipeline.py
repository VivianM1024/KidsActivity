"""Crawl orchestration.

The weekly publisher always calls `crawl_all_venues`, which scrapes
every configured venue with no user-side filters and yields a flat list
of Activities. Filtering by age / category / distance happens client-side
in the iOS app.
"""

from kidsactivity.cache import get_http_cache
from kidsactivity.config import Settings
from kidsactivity.http_client import HttpClient, build_http_client
from kidsactivity.locator import load_all_venues
from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, SearchQuery, Venue
from kidsactivity.scrapers import get_scraper_class

log = get_logger(__name__)


def crawl_all_venues(settings: Settings) -> list[Activity]:
    cache = get_http_cache(settings.cache_dir, ttl_hours=settings.crawl.cache_ttl_hours)
    http = build_http_client(
        settings.http,
        cache=cache,
        requests_per_second=settings.crawl.rate_limit_per_host_rps,
    )

    enabled = set(settings.crawl.enabled_venues) if settings.crawl.enabled_venues else None
    all_activities: list[Activity] = []
    try:
        for venue in load_all_venues():
            if enabled is not None and venue.slug not in enabled:
                continue
            log.info("Crawling %s (%s/%s)", venue.name, venue.venue_type, venue.platform)
            try:
                activities = _crawl_one(venue, http)
            except Exception as e:
                log.warning("Scraper failed for %s: %s", venue.slug, e)
                continue
            log.info("  %s → %d activities", venue.slug, len(activities))
            all_activities.extend(activities)
    finally:
        http.close()

    filtered = _filter_excluded(all_activities)
    log.info(
        "Crawl complete: %d activities (filtered %d exclusions)",
        len(filtered),
        len(all_activities) - len(filtered),
    )
    return _dedupe(filtered)


def crawl_one_venue(venue: Venue, settings: Settings) -> list[Activity]:
    cache = get_http_cache(settings.cache_dir, ttl_hours=settings.crawl.cache_ttl_hours)
    http = build_http_client(
        settings.http,
        cache=cache,
        requests_per_second=settings.crawl.rate_limit_per_host_rps,
    )
    try:
        return _crawl_one(venue, http)
    finally:
        http.close()


def _crawl_one(venue: Venue, http: HttpClient) -> list[Activity]:
    scraper_cls = get_scraper_class(venue.platform)
    if scraper_cls is None:
        log.debug("No scraper for platform=%s (%s)", venue.platform, venue.slug)
        return []
    scraper = scraper_cls(venue, http)
    try:
        raw = scraper.crawl_all()
    except Exception as e:
        log.warning("crawl_all failed for %s: %s", venue.slug, e)
        return []
    try:
        enriched = scraper.enrich(raw)
    except Exception as e:
        log.warning("Enrich failed for %s: %s — keeping raw", venue.slug, e)
        enriched = raw
    return _dedupe(enriched)


# Activity names containing any of these are dropped — the catalog is for
# kids' enrichment classes, not daycare/aftercare placeholders.
_EXCLUDE_KEYWORDS = (
    "preschool",
    "pre-school",
    "pre school",
    "after care",
    "aftercare",
    "after-care",
    "after school care",
    "after-school care",
    "pre care",
    "precare",
    "pre-care",
    "before care",
    "before-care",
)


def _excluded(a: Activity) -> bool:
    hay = f"{a.name} {a.category or ''} {a.raw_category or ''}".lower()
    return any(k in hay for k in _EXCLUDE_KEYWORDS)


def _filter_excluded(activities: list[Activity]) -> list[Activity]:
    return [a for a in activities if not _excluded(a)]


def _dedupe(activities: list[Activity]) -> list[Activity]:
    seen: set[str] = set()
    out: list[Activity] = []
    for a in activities:
        if a.activity_id in seen:
            continue
        seen.add(a.activity_id)
        out.append(a)
    return out
