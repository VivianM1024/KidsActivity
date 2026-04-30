from pathlib import Path

import yaml
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

DEFAULT_CACHE_DIR = Path.home() / ".cache" / "kidsactivity"


class HttpConfig(BaseModel):
    user_agent: str = "kidsactivity/0.1 (+https://github.com/VivianM1024/KidsActivity)"
    timeout_seconds: int = 30
    max_retries: int = 3


class CrawlConfig(BaseModel):
    enabled_venues: list[str] = Field(default_factory=list)
    cache_ttl_hours: int = 24
    rate_limit_per_host_rps: float = 1.0


class LoggingConfig(BaseModel):
    level: str = "INFO"


class Settings(BaseSettings):
    """Top-level settings. Env vars (prefix KA_) override defaults."""

    model_config = SettingsConfigDict(
        env_prefix="KA_",
        env_nested_delimiter="__",
        extra="ignore",
    )

    http: HttpConfig = Field(default_factory=HttpConfig)
    crawl: CrawlConfig = Field(default_factory=CrawlConfig)
    logging: LoggingConfig = Field(default_factory=LoggingConfig)
    anthropic_api_key: str | None = None
    cache_dir: Path = DEFAULT_CACHE_DIR

    @classmethod
    def load(cls, config_path: Path | None = None) -> "Settings":
        data: dict = {}
        if config_path and config_path.exists():
            data = yaml.safe_load(config_path.read_text()) or {}
        return cls(**data)
