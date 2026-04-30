"""Generic CSS-selector HTML scraper for one-off venue sites.

Reads its config from ``venue.custom_config``::

    custom_config:
      listing_url: https://example.org/events
      item_selector: ".event-card"
      fields:
        name: ".event-title"
        date: ".event-date"
        time: ".event-time"
        location: ".event-location"
        url: "a@href"           # @attr to read attribute
      llm_fallback: true        # if selectors yield 0 items, try Claude
      audience_filter: ["kids", "family", "children", "toddler"]

Use this for museums and small community-center sites that don't run a
known platform. Falls back to ``llm_fallback.parse_event(html)`` when
selectors yield nothing — gated by ANTHROPIC_API_KEY env var.

This is a stub — flesh out when you start adding museum venues.
"""

from __future__ import annotations

from collections.abc import Iterator

from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, SearchQuery
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


class CustomHtmlScraper(BaseScraper):
    def search(self, query: SearchQuery) -> Iterator[Activity]:
        log.warning(
            "[%s] CustomHtmlScraper not yet implemented; skipping",
            self.venue.slug,
        )
        return
        yield  # pragma: no cover
