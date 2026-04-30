"""Domain models for kids activities, generalized across venue types.

Adapted from `personalAgent/agents/park_district/models.py`. The previous
`ParkDistrict` becomes `Venue` (with a `venue_type` enum so libraries,
museums, and community centers fit the same shape). `Course` becomes
`Activity` and drops the `park_district_*` fields in favor of `venue_*`.

Adding a new platform = add a value to the `Platform` enum below and
register a `BaseScraper` subclass in `scrapers/__init__.py`.
"""

from datetime import date, datetime, time, timezone
from enum import StrEnum
from typing import Any, Literal

from pydantic import BaseModel, Field, HttpUrl


class VenueType(StrEnum):
    PARK_DISTRICT = "park_district"
    LIBRARY = "library"
    COMMUNITY_CENTER = "community_center"
    MUSEUM = "museum"


class Platform(StrEnum):
    # Park-district registration platforms (lifted from the old project).
    ACTIVENET = "activenet"
    WEBTRAC = "webtrac"
    AMILIA = "amilia"
    # New library platforms.
    BIBLIO_COMMONS = "biblio_commons"
    LIBRARY_CALENDAR = "library_calendar"
    COMMUNICO = "communico"
    # Generic CSS-selector + LLM-fallback scraper for one-off venue sites
    # (most museums, some smaller community centers).
    CUSTOM_HTML = "custom_html"


class Venue(BaseModel):
    slug: str
    name: str
    venue_type: VenueType
    platform: Platform
    base_url: HttpUrl
    search_url: HttpUrl | None = None
    center_lat: float
    center_lon: float
    served_zipcodes: list[str] = Field(default_factory=list)
    aliases: list[str] = Field(default_factory=list)
    # Vermont Systems WebTrac tenant code (e.g. "ilwilmettewt").
    sitecode: str | None = None
    # Amilia store organization slug (e.g. "cityofevanston").
    amilia_org_slug: str | None = None
    # Per-platform free-form config. The CUSTOM_HTML scraper reads this
    # for { listing_url, item_selector, fields: {...}, llm_fallback: bool }.
    custom_config: dict[str, Any] | None = None


DayOfWeek = Literal["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]


class WeeklyTime(BaseModel):
    day_of_week: DayOfWeek
    start: time
    end: time


class Schedule(BaseModel):
    start_date: date | None = None
    end_date: date | None = None
    weekly_times: list[WeeklyTime] = Field(default_factory=list)
    raw_schedule_text: str | None = None
    # Canonical session count (already accounts for mid-term skipped meetings).
    num_sessions: int | None = None


class Price(BaseModel):
    resident_price: float | None = None
    non_resident_price: float | None = None
    currency: str = "USD"
    raw_price_text: str | None = None


class AgeRange(BaseModel):
    min_months: int | None = None
    max_months: int | None = None
    raw_age_text: str | None = None

    def covers(self, age_months: int) -> bool:
        lo = self.min_months if self.min_months is not None else 0
        hi = self.max_months if self.max_months is not None else 10_000
        return lo <= age_months <= hi

    def overlaps(self, query_min: int | None, query_max: int | None) -> bool:
        if self.min_months is None and self.max_months is None:
            return True
        lo = self.min_months if self.min_months is not None else 0
        hi = self.max_months if self.max_months is not None else 10_000
        qlo = query_min if query_min is not None else 0
        qhi = query_max if query_max is not None else 10_000
        return lo <= qhi and hi >= qlo


class Registration(BaseModel):
    is_open: bool | None = None
    opens_at: datetime | None = None
    closes_at: datetime | None = None
    resident_opens_at: datetime | None = None
    non_resident_opens_at: datetime | None = None
    raw_text: str | None = None


class Activity(BaseModel):
    name: str
    venue_name: str
    venue_slug: str
    venue_type: VenueType
    schedule: Schedule
    price: Price
    age_range: AgeRange
    location: str = ""
    registration: Registration = Field(default_factory=Registration)
    source_url: HttpUrl
    activity_id: str
    category: str | None = None
    raw_category: str | None = None
    description: str | None = None
    scraped_at: datetime = Field(default_factory=lambda: datetime.now(tz=timezone.utc))


class SearchQuery(BaseModel):
    """Query passed to scrapers' `search()`. For weekly bulk crawls use the
    default values — the JSON publisher writes everything and the iOS app
    filters client-side.
    """

    zipcode: str = "00000"
    distance_miles: float = 9999.0
    age_min_months: int | None = None
    age_max_months: int | None = None
    categories: list[str] | None = None
    keyword: str | None = None
    registration_open_only: bool = False
