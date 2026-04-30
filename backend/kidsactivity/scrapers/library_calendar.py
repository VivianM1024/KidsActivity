"""LibraryCalendar / LibraryAware events scraper (CCS tenants).

Many CCS Cooperative Computer Services member libraries (Glenview,
Niles-Maine) publish events through the LibraryAware platform. The
events page is server-rendered HTML with a stable structure
(<div class="event-listing">) containing title, date, audience, and
registration link.

This is a stub. See `biblio_commons.py` for the contract.
"""

from __future__ import annotations

from collections.abc import Iterator

from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, SearchQuery
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


class LibraryCalendarScraper(BaseScraper):
    def search(self, query: SearchQuery) -> Iterator[Activity]:
        log.warning(
            "[%s] LibraryCalendarScraper not yet implemented; skipping",
            self.venue.slug,
        )
        return
        yield  # pragma: no cover
