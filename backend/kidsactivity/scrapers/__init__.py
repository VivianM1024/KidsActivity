"""Scraper registry.

To add a new platform: drop a new scraper class in this directory
(subclass `BaseScraper`, implement `search()` and optionally `enrich()`),
add a value to `Platform` in `models.py`, and register it here.
"""

from kidsactivity.models import Platform
from kidsactivity.scrapers.activenet import ActiveNetScraper
from kidsactivity.scrapers.amilia import AmiliaScraper
from kidsactivity.scrapers.base import BaseScraper
from kidsactivity.scrapers.biblio_commons import BiblioCommonsScraper
from kidsactivity.scrapers.communico import CommunicoScraper
from kidsactivity.scrapers.custom_html import CustomHtmlScraper
from kidsactivity.scrapers.library_calendar import LibraryCalendarScraper
from kidsactivity.scrapers.webtrac import WebTracScraper

PLATFORM_SCRAPERS: dict[Platform, type[BaseScraper]] = {
    Platform.ACTIVENET: ActiveNetScraper,
    Platform.AMILIA: AmiliaScraper,
    Platform.WEBTRAC: WebTracScraper,
    Platform.BIBLIO_COMMONS: BiblioCommonsScraper,
    Platform.LIBRARY_CALENDAR: LibraryCalendarScraper,
    Platform.COMMUNICO: CommunicoScraper,
    Platform.CUSTOM_HTML: CustomHtmlScraper,
}


def get_scraper_class(platform: Platform) -> type[BaseScraper] | None:
    return PLATFORM_SCRAPERS.get(platform)


__all__ = [
    "BaseScraper",
    "ActiveNetScraper",
    "AmiliaScraper",
    "WebTracScraper",
    "BiblioCommonsScraper",
    "LibraryCalendarScraper",
    "CommunicoScraper",
    "CustomHtmlScraper",
    "PLATFORM_SCRAPERS",
    "get_scraper_class",
]
