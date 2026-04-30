from pathlib import Path

import diskcache


def get_http_cache(cache_dir: Path, ttl_hours: int = 24) -> diskcache.Cache:
    cache_dir.mkdir(parents=True, exist_ok=True)
    return diskcache.Cache(str(cache_dir / "http"), expire=ttl_hours * 3600)


def get_llm_cache(cache_dir: Path) -> diskcache.Cache:
    cache_dir.mkdir(parents=True, exist_ok=True)
    return diskcache.Cache(str(cache_dir / "llm"))
