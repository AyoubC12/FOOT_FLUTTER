from __future__ import annotations

import hashlib
import json
import logging
from typing import Any

import requests
from django.conf import settings
from django.core.cache import cache

from football.exceptions import (
    FootballConfigError,
    FootballProviderError,
    FootballRateLimitError,
)
from football.services import normalizers

logger = logging.getLogger(__name__)

TTL_LIVE = 15
TTL_FIXTURES = 300
TTL_TEAMS = 60 * 60 * 12
TTL_PLAYERS = 60 * 60 * 6
TTL_STANDINGS = 60 * 30
TTL_TEAM_STATS = 60 * 60
TTL_PLAYER_STATS = 60 * 60
TTL_H2H = 60 * 60 * 6
TTL_FIXTURE_DETAIL = 60


class ApiFootballService:
    """Server-side API-Football client. The API key never leaves this process."""

    def __init__(self) -> None:
        self.base_url = (
            getattr(settings, "FOOTBALL_API_BASE_URL", "") or "https://v3.football.api-sports.io"
        ).rstrip("/")
        self.api_key = getattr(settings, "FOOTBALL_API_KEY", "") or ""
        self.api_host = getattr(settings, "FOOTBALL_API_HOST", "") or ""
        self.timeout = 12

    def fixtures(self, params: dict[str, Any]) -> dict:
        payload = self._get("/fixtures", params, ttl=self._fixture_ttl(params))
        return self._collection(payload, normalizers.normalize_fixture)

    def live_fixtures(self, live: str = "all") -> dict:
        payload = self._get("/fixtures", {"live": live}, ttl=TTL_LIVE)
        return self._collection(payload, normalizers.normalize_fixture)

    def fixture_detail(self, fixture_id: int) -> dict:
        payload = self._get("/fixtures", {"id": fixture_id}, ttl=TTL_FIXTURE_DETAIL)
        items = payload.get("response") or []
        if not items:
            raise FootballProviderError("Fixture not found.", status_code=404)
        fixture = normalizers.normalize_fixture(items[0])
        statistics = items[0].get("statistics")
        if not statistics:
            stats_payload = self._get(
                "/fixtures/statistics",
                {"fixture": fixture_id},
                ttl=TTL_FIXTURE_DETAIL,
            )
            statistics = stats_payload.get("response") or []
        fixture["statistics"] = normalizers.normalize_fixture_statistics(statistics)
        return {
            "results": fixture,
            "errors": payload.get("errors") or {},
        }

    def teams(self, params: dict[str, Any]) -> dict:
        payload = self._get("/teams", params, ttl=TTL_TEAMS)
        return self._collection(payload, normalizers.normalize_team)

    def team_detail(self, team_id: int) -> dict:
        payload = self._get("/teams", {"id": team_id}, ttl=TTL_TEAMS)
        items = payload.get("response") or []
        if not items:
            raise FootballProviderError("Team not found.", status_code=404)
        return {"results": normalizers.normalize_team(items[0]), "errors": {}}

    def team_statistics(self, params: dict[str, Any]) -> dict:
        payload = self._get("/teams/statistics", params, ttl=TTL_TEAM_STATS)
        body = payload.get("response") or {}
        return {
            "results": normalizers.normalize_team_statistics(body),
            "errors": payload.get("errors") or {},
        }

    def players(self, params: dict[str, Any]) -> dict:
        payload = self._get("/players", params, ttl=TTL_PLAYERS)
        return self._collection(payload, normalizers.normalize_player)

    def player_statistics(self, params: dict[str, Any]) -> dict:
        payload = self._get("/players", params, ttl=TTL_PLAYER_STATS)
        items = payload.get("response") or []
        if not items:
            raise FootballProviderError("Player statistics not found.", status_code=404)
        return {
            "results": normalizers.normalize_player_statistics(items[0]),
            "errors": payload.get("errors") or {},
            "paging": payload.get("paging") or {"current": 1, "total": 1},
        }

    def standings(self, params: dict[str, Any]) -> dict:
        payload = self._get("/standings", params, ttl=TTL_STANDINGS)
        return {
            "results": normalizers.normalize_standings(payload.get("response") or []),
            "errors": payload.get("errors") or {},
            "paging": payload.get("paging") or {"current": 1, "total": 1},
        }

    def head_to_head(self, params: dict[str, Any]) -> dict:
        payload = self._get("/fixtures/headtohead", params, ttl=TTL_H2H)
        return self._collection(payload, normalizers.normalize_fixture)

    def leagues(self, params: dict[str, Any]) -> dict:
        from integrations.api_football.cache import TTL_LEAGUES

        payload = self._get("/leagues", params, ttl=TTL_LEAGUES)
        return {
            "results": payload.get("response") or [],
            "errors": payload.get("errors") or {},
            "paging": payload.get("paging") or {"current": 1, "total": 1},
        }

    def squads(self, team_id: int) -> dict:
        from integrations.api_football.cache import TTL_SQUADS

        payload = self._get("/players/squads", {"team": team_id}, ttl=TTL_SQUADS)
        return {
            "results": payload.get("response") or [],
            "errors": payload.get("errors") or {},
        }

    def transfers(self, player_id: int) -> dict:
        from integrations.api_football.cache import TTL_TRANSFERS

        payload = self._get("/transfers", {"player": player_id}, ttl=TTL_TRANSFERS)
        return {
            "results": payload.get("response") or [],
            "errors": payload.get("errors") or {},
        }

    def coaches(self, params: dict[str, Any]) -> dict:
        from integrations.api_football.cache import TTL_COACHES

        payload = self._get("/coachs", params, ttl=TTL_COACHES)
        return {
            "results": payload.get("response") or [],
            "errors": payload.get("errors") or {},
        }

    def _fixture_ttl(self, params: dict[str, Any]) -> int:
        if params.get("live"):
            return TTL_LIVE
        status = str(params.get("status") or "").upper()
        if status in {"1H", "2H", "HT", "ET", "BT", "P", "LIVE"}:
            return TTL_LIVE
        return TTL_FIXTURES

    def _collection(self, payload: dict, mapper) -> dict:
        items = [mapper(item) for item in payload.get("response") or []]
        return {
            "results": items,
            "errors": payload.get("errors") or {},
            "paging": payload.get("paging") or {"current": 1, "total": 1},
            "results_count": payload.get("results", len(items)),
        }

    def _get(self, path: str, params: dict[str, Any], ttl: int) -> dict:
        if not self.api_key:
            raise FootballConfigError()

        clean = {key: value for key, value in params.items() if value not in (None, "")}
        cache_key = self._cache_key(path, clean)
        cached = cache.get(cache_key)
        if cached is not None:
            return cached

        try:
            response = requests.get(
                f"{self.base_url}{path}",
                params=clean,
                headers=self._headers(),
                timeout=self.timeout,
            )
        except requests.RequestException as exc:
            logger.warning("API-Football request failed for %s", path)
            raise FootballProviderError("Could not reach the football data provider.") from exc

        if response.status_code == 429:
            retry_after = response.headers.get("Retry-After")
            raise FootballRateLimitError(
                int(retry_after) if retry_after and retry_after.isdigit() else None
            )
        if response.status_code == 401:
            logger.error("API-Football rejected the configured key.")
            raise FootballProviderError(
                "Football data provider authentication failed.",
                status_code=502,
            )
        if response.status_code >= 500:
            raise FootballProviderError("Football data provider is unavailable.")
        if response.status_code >= 400:
            raise FootballProviderError(
                "Football data provider rejected the request.",
                status_code=400,
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise FootballProviderError("Football data provider returned invalid JSON.") from exc

        errors = payload.get("errors") or {}
        if errors:
            error_keys = errors.keys() if isinstance(errors, dict) else errors
            if "rateLimit" in error_keys or "plan" in error_keys:
                raise FootballRateLimitError()
            logger.info("API-Football returned errors for %s", path)

        cache.set(cache_key, payload, ttl)
        return payload

    def _headers(self) -> dict[str, str]:
        if self.api_host:
            return {
                "x-rapidapi-key": self.api_key,
                "x-rapidapi-host": self.api_host,
            }
        return {"x-apisports-key": self.api_key}

    def _cache_key(self, path: str, params: dict[str, Any]) -> str:
        encoded = json.dumps(params, sort_keys=True, default=str)
        digest = hashlib.sha256(f"{path}:{encoded}".encode()).hexdigest()
        return f"api-football:{digest}"
