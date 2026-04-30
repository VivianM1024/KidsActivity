"""Optional LLM-based parser for one-off venue HTML where CSS selectors fail.

Used by `scrapers/custom_html.py` when its configured selectors yield no
items. Gated by the ANTHROPIC_API_KEY env var — if unset, all parse calls
return None and the caller logs a warning and skips.

Currently a stub. Wire up when the first museum scraper actually needs
it; until then, the safe behavior is to return None.
"""

from __future__ import annotations

import os

from kidsactivity.logging import get_logger

log = get_logger(__name__)


def is_configured() -> bool:
    return bool(os.environ.get("ANTHROPIC_API_KEY"))


def parse_event(html: str) -> dict | None:
    """Parse a single event-card HTML fragment into structured fields.

    Returns None if no API key is configured. When implemented this should
    call Claude with prompt caching on a fixed schema and return
    {name, start_date, end_date, age_text, price_text, source_url}.
    """
    if not is_configured():
        return None
    log.debug("LLM fallback parse_event called but not yet implemented")
    return None
