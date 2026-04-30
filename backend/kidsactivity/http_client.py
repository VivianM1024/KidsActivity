import threading
import time

import httpx
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential

from kidsactivity.config import HttpConfig


class RateLimiter:
    def __init__(self, requests_per_second: float):
        self.min_interval = 1.0 / requests_per_second if requests_per_second > 0 else 0.0
        self._last_hit: dict[str, float] = {}
        self._lock = threading.Lock()

    def wait(self, host: str) -> None:
        if self.min_interval <= 0:
            return
        with self._lock:
            last = self._last_hit.get(host, 0.0)
            delay = self.min_interval - (time.monotonic() - last)
            if delay > 0:
                time.sleep(delay)
            self._last_hit[host] = time.monotonic()


class HttpClient:
    """httpx.Client wrapper with rate limiting + retries + optional caching."""

    def __init__(self, config: HttpConfig, rate_limiter: RateLimiter | None = None, cache=None):
        self._client = httpx.Client(
            headers={"User-Agent": config.user_agent},
            timeout=config.timeout_seconds,
            follow_redirects=True,
        )
        self._rate_limiter = rate_limiter or RateLimiter(requests_per_second=1.0)
        self._max_retries = config.max_retries
        self._cache = cache

    def get(
        self,
        url: str,
        *,
        params: dict | None = None,
        headers: dict | None = None,
        use_cache: bool = True,
    ) -> httpx.Response:
        cache_key = None
        if use_cache and self._cache is not None:
            cache_key = f"GET {url} {params or ''} {headers or ''}"
            cached = self._cache.get(cache_key)
            if cached is not None:
                return _deserialize_response(cached)
        host = httpx.URL(url).host
        self._rate_limiter.wait(host)
        resp = self._do_get(url, params=params, headers=headers)
        if cache_key and 200 <= resp.status_code < 300:
            self._cache.set(cache_key, _serialize_response(resp))
        return resp

    def post(
        self,
        url: str,
        *,
        json: dict | None = None,
        data: dict | None = None,
        headers: dict | None = None,
        use_cache: bool = True,
    ) -> httpx.Response:
        cache_key = None
        if use_cache and self._cache is not None:
            cache_key = f"POST {url} {json or data or ''} {headers or ''}"
            cached = self._cache.get(cache_key)
            if cached is not None:
                return _deserialize_response(cached)
        host = httpx.URL(url).host
        self._rate_limiter.wait(host)
        resp = self._do_post(url, json=json, data=data, headers=headers)
        if cache_key and 200 <= resp.status_code < 300:
            self._cache.set(cache_key, _serialize_response(resp))
        return resp

    @retry(
        reraise=True,
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((httpx.TransportError, httpx.HTTPStatusError)),
    )
    def _do_get(
        self, url: str, *, params: dict | None = None, headers: dict | None = None
    ) -> httpx.Response:
        resp = self._client.get(url, params=params, headers=headers)
        if resp.status_code >= 500:
            resp.raise_for_status()
        return resp

    @retry(
        reraise=True,
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        retry=retry_if_exception_type((httpx.TransportError, httpx.HTTPStatusError)),
    )
    def _do_post(
        self,
        url: str,
        *,
        json: dict | None = None,
        data: dict | None = None,
        headers: dict | None = None,
    ) -> httpx.Response:
        resp = self._client.post(url, json=json, data=data, headers=headers)
        if resp.status_code >= 500:
            resp.raise_for_status()
        return resp

    def close(self) -> None:
        self._client.close()


def _serialize_response(resp: httpx.Response) -> dict:
    # Strip transfer-encoding metadata: httpx already decompressed the body,
    # so persisting Content-Encoding alongside decoded bytes makes the next
    # read attempt to decompress plain text.
    headers = {
        k: v for k, v in resp.headers.items()
        if k.lower() not in ("content-encoding", "content-length", "transfer-encoding")
    }
    return {
        "status_code": resp.status_code,
        "headers": headers,
        "content": resp.content,
        "url": str(resp.url),
    }


def _deserialize_response(data: dict) -> httpx.Response:
    return httpx.Response(
        status_code=data["status_code"],
        headers=data["headers"],
        content=data["content"],
        request=httpx.Request("GET", data["url"]),
    )


def build_http_client(
    config: HttpConfig,
    cache=None,
    requests_per_second: float = 1.0,
) -> HttpClient:
    return HttpClient(config, RateLimiter(requests_per_second), cache)
