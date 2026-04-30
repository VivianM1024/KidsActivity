"""BiblioCommons library scraper.

Many North-Shore libraries (Skokie, Evanston, Wilmette) run BiblioCommons
events. The public events feed is JSON at
``{base_url}/api/v2/events?audiences=children&audiences=teens`` and the
HTML index lives at ``/events/search/index/c=audiences&audiences=children``.

This is a stub — implement when you wire up library venues. The scraper
contract is the same as the park-district ones: yield Activities from
``search()``, with age_range / schedule / registration populated.
"""

from __future__ import annotations

from collections.abc import Iterator

from kidsactivity.logging import get_logger
from kidsactivity.models import Activity, SearchQuery
from kidsactivity.scrapers.base import BaseScraper

log = get_logger(__name__)


class BiblioCommonsScraper(BaseScraper):
    def search(self, query: SearchQuery) -> Iterator[Activity]:
        log.warning(
            "[%s] BiblioCommonsScraper not yet implemented; skipping",
            self.venue.slug,
        )
        return
        yield  # pragma: no cover
