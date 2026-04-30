import math

import pgeocode

_NOMI = pgeocode.Nominatim("us")


class UnknownZipcode(ValueError):
    pass


def zip_to_latlon(zipcode: str) -> tuple[float, float]:
    row = _NOMI.query_postal_code(zipcode)
    lat, lon = row.latitude, row.longitude
    if lat is None or lon is None or (isinstance(lat, float) and math.isnan(lat)):
        raise UnknownZipcode(f"Zipcode {zipcode!r} not found in US postal database")
    return float(lat), float(lon)


def haversine_miles(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r_miles = 3958.7613
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    c = 2 * math.asin(math.sqrt(a))
    return r_miles * c
