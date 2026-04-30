from abc import ABC, abstractmethod
from collections.abc import Iterator

from kidsactivity.http_client import HttpClient
from kidsactivity.models import Activity, SearchQuery, Venue


class BaseScraper(ABC):
    def __init__(self, venue: Venue, http: HttpClient):
        self.venue = venue
        self.http = http

    @abstractmethod
    def search(self, query: SearchQuery) -> Iterator[Activity]:
        """Yield Activities for this venue matching the query.

        Filtering on age/category/registration-open is downstream in
        pipeline.py — scrapers should return as broad a set as possible
        (respecting platform-side filters that narrow the result cheaply).
        """

    def crawl_all(self) -> list[Activity]:
        """Return *every* activity for this venue, regardless of filters.

        Default: pass an empty query to `search`. Platforms that refuse to
        respond without filters (WebTrac) override this.
        """
        empty = SearchQuery()
        seen: set[str] = set()
        out: list[Activity] = []
        for a in self.search(empty):
            if a.activity_id in seen:
                continue
            seen.add(a.activity_id)
            out.append(a)
        return out

    def enrich(self, activities: list[Activity]) -> list[Activity]:
        """Fill in fields the cheap list endpoint omits, by hitting per-item
        detail endpoints. Default is a no-op — override and cap request
        count to keep first-run latency bounded.
        """
        return activities
