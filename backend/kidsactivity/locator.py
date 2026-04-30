from functools import lru_cache
from pathlib import Path

import yaml

from kidsactivity.geo import haversine_miles, zip_to_latlon
from kidsactivity.models import Venue

_DATA_DIR = Path(__file__).parent / "data"


@lru_cache(maxsize=1)
def load_all_venues() -> list[Venue]:
    raw = yaml.safe_load((_DATA_DIR / "venues.yaml").read_text())
    return [Venue.model_validate(v) for v in raw.get("venues", [])]


def find_nearby_venues(
    zipcode: str,
    distance_miles: float,
    enabled_slugs: list[str] | None = None,
) -> list[tuple[Venue, float]]:
    """Return (venue, miles) within radius, sorted nearest-first."""
    user_lat, user_lon = zip_to_latlon(zipcode)
    enabled_set = set(enabled_slugs) if enabled_slugs else None
    results: list[tuple[Venue, float]] = []
    for v in load_all_venues():
        if enabled_set is not None and v.slug not in enabled_set:
            continue
        miles = haversine_miles(user_lat, user_lon, v.center_lat, v.center_lon)
        if miles <= distance_miles:
            results.append((v, miles))
    results.sort(key=lambda x: x[1])
    return results
