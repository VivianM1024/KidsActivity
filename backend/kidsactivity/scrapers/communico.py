"""Communico Attend events scraper.

Communico powers the events / room-booking pages at libraries like
Northbrook and Niles. Public events are exposed via JSON at
``/api/attend/events`` with audience filters; the HTML calendar at
``/eventcalendar`` is also scrapable.

This is a stub. See `biblio_commons.py` for the contract.
"""

from __future__ import annotations

from collections.abc import Iterator

from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, SearchQuery
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


class CommunicoScraper(BaseScraper):
    def search(self, query: SearchQuery) -> Iterator[Activity]:
        log.warning(
            "[%s] CommunicoScraper not yet implemented; skipping",
            self.venue.slug,
        )
        return
        yield  # pragma: no cover
