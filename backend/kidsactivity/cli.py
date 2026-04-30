"""CLI entry point: `kidsactivity publish` is what GitHub Actions runs."""

from __future__ import annotations

from pathlib import Path

import typer
from rich.console import Console
from rich.table import Table

from kidsactivity.config import Settings
from kidsactivity.locator import load_all_venues
from kidsactivity.logging import get_logger, setup_logging
from kidsactivity.models import Venue
from kidsactivity.pipeline import crawl_all_venues, crawl_one_venue
from kidsactivity.publisher import publish as publish_to_disk
from kidsactivity.scrapers import get_scraper_class

app = typer.Typer(no_args_is_help=True, help="KidsActivity scraper CLI")
console = Console()
log = get_logger(__name__)


def _load_settings() -> Settings:
    settings = Settings()
    setup_logging(settings.logging.level)
    return settings


def _resolve_out_dir(out_dir: Path | None) -> Path:
    if out_dir is not None:
        return out_dir
    # Default: <repo_root>/docs/data, where repo_root = parents[2] of this
    # file (kidsactivity/ → backend/ → repo).
    return Path(__file__).resolve().parents[2] / "docs" / "data"


@app.command(name="list-venues")
def list_venues_cmd() -> None:
    """List every venue configured in venues.yaml."""
    venues = load_all_venues()
    table = Table(title=f"Venues ({len(venues)})")
    for col in ("Slug", "Name", "Type", "Platform"):
        table.add_column(col)
    for v in venues:
        table.add_row(v.slug, v.name, v.venue_type.value, v.platform.value)
    console.print(table)


@app.command()
def crawl(
    venue: str | None = typer.Option(None, "--venue", help="Slug of a single venue (default: all)"),
) -> None:
    """Crawl venues and print a summary table (no JSON output)."""
    settings = _load_settings()
    if venue:
        v = _find_venue(venue)
        activities = crawl_one_venue(v, settings)
    else:
        activities = crawl_all_venues(settings)

    table = Table(title=f"Crawled {len(activities)} activities")
    for col in ("Venue", "Name", "Age (mo)", "Reg open"):
        table.add_column(col)
    for a in activities[:50]:
        age = (
            f"{a.age_range.min_months or '?'}-{a.age_range.max_months or '?'}"
            if (a.age_range.min_months or a.age_range.max_months)
            else "—"
        )
        reg = "Y" if a.registration.is_open else ("N" if a.registration.is_open is False else "?")
        table.add_row(a.venue_slug, a.name[:60], age, reg)
    console.print(table)
    if len(activities) > 50:
        console.print(f"[dim]... {len(activities) - 50} more rows omitted[/dim]")


@app.command()
def publish(
    out_dir: Path | None = typer.Option(None, "--out-dir", help="Where to write JSON (default: ../docs/data)"),
) -> None:
    """Crawl every venue and publish JSON for the iOS app."""
    settings = _load_settings()
    activities = crawl_all_venues(settings)
    publish_to_disk(activities, _resolve_out_dir(out_dir))


@app.command(name="test-scraper")
def test_scraper(
    venue: str = typer.Option(..., "--venue", help="Slug of the venue to test"),
) -> None:
    """Run a single venue's scraper end-to-end and print results."""
    settings = _load_settings()
    v = _find_venue(venue)
    scraper_cls = get_scraper_class(v.platform)
    if scraper_cls is None:
        console.print(f"[red]No scraper registered for platform {v.platform.value}[/red]")
        raise typer.Exit(code=1)
    activities = crawl_one_venue(v, settings)
    console.print(f"[green]{v.name}[/green] → {len(activities)} activities")
    for a in activities[:10]:
        console.print(f"  • {a.name} (id={a.activity_id})")


def _find_venue(slug: str) -> Venue:
    for v in load_all_venues():
        if v.slug == slug:
            return v
    raise typer.BadParameter(f"Unknown venue slug: {slug}")


if __name__ == "__main__":
    app()
