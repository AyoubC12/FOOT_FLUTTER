from __future__ import annotations

from datetime import datetime, timezone

from django.utils.dateparse import parse_datetime

from football.exceptions import FootballProviderError
from football.services.api_football import ApiFootballService

from ..models import HistoricalMatch
from .records import FINISHED_STATUSES, MatchRecord


def match_from_model(row: HistoricalMatch) -> MatchRecord:
    return MatchRecord(
        match_id=row.external_id,
        kickoff_at=row.kickoff_at,
        home_id=row.home_team_id,
        away_id=row.away_team_id,
        home_name=row.home_team_name,
        away_name=row.away_team_name,
        home_goals=row.home_goals,
        away_goals=row.away_goals,
        league_id=row.league_id,
        season=row.season,
    )


def load_history_from_db() -> list[MatchRecord]:
    rows = HistoricalMatch.objects.all().order_by("kickoff_at")
    return [match_from_model(row) for row in rows]


def fixture_to_record(item: dict) -> MatchRecord | None:
    status = ((item.get("status") or {}).get("short") or "").upper()
    goals = item.get("goals") or {}
    if status not in FINISHED_STATUSES:
        return None
    if goals.get("home") is None or goals.get("away") is None:
        return None
    kickoff = parse_datetime(item.get("date") or "")
    if kickoff is None:
        return None
    if kickoff.tzinfo is None:
        kickoff = kickoff.replace(tzinfo=timezone.utc)
    home = (item.get("teams") or {}).get("home") or {}
    away = (item.get("teams") or {}).get("away") or {}
    if not home.get("id") or not away.get("id"):
        return None
    league = item.get("league") or {}
    return MatchRecord(
        match_id=str(item.get("id")),
        kickoff_at=kickoff,
        home_id=int(home["id"]),
        away_id=int(away["id"]),
        home_name=home.get("name") or f"Team {home['id']}",
        away_name=away.get("name") or f"Team {away['id']}",
        home_goals=int(goals["home"]),
        away_goals=int(goals["away"]),
        league_id=league.get("id"),
        season=league.get("season"),
    )


def upsert_record(record: MatchRecord) -> HistoricalMatch:
    obj, _ = HistoricalMatch.objects.update_or_create(
        external_id=record.match_id,
        defaults={
            "league_id": record.league_id,
            "season": record.season,
            "kickoff_at": record.kickoff_at,
            "home_team_id": record.home_id,
            "away_team_id": record.away_id,
            "home_team_name": record.home_name,
            "away_team_name": record.away_name,
            "home_goals": record.home_goals,
            "away_goals": record.away_goals,
            "status": "FT",
        },
    )
    return obj


def pull_team_history(team_id: int, *, last: int = 10) -> list[MatchRecord]:
    """Fetch finished matches from API-Football. Skip rows with missing scores."""
    service = ApiFootballService()
    try:
        payload = service.fixtures({"team": team_id, "last": last})
    except FootballProviderError:
        return []
    records = []
    for item in payload.get("results") or []:
        record = fixture_to_record(item)
        if record:
            records.append(record)
            upsert_record(record)
    return records


def pull_h2h(home_id: int, away_id: int, *, last: int = 10) -> list[MatchRecord]:
    service = ApiFootballService()
    try:
        payload = service.head_to_head(
            {"h2h": f"{home_id}-{away_id}", "last": last}
        )
    except FootballProviderError:
        return []
    records = []
    for item in payload.get("results") or []:
        record = fixture_to_record(item)
        if record:
            records.append(record)
            upsert_record(record)
    return records


def pull_league_season(league_id: int, season: int) -> int:
    service = ApiFootballService()
    payload = service.fixtures(
        {"league": league_id, "season": season, "status": "FT"}
    )
    stored = 0
    for item in payload.get("results") or []:
        record = fixture_to_record(item)
        if record:
            upsert_record(record)
            stored += 1
    return stored


def mean_team_player_rating(team_id: int, season: int | None) -> float | None:
    """Season-to-date ratings are only used for upcoming matches, never backfilled into training labels."""
    if season is None:
        return None
    service = ApiFootballService()
    try:
        payload = service.players({"team": team_id, "season": season, "page": 1})
    except FootballProviderError:
        return None
    ratings = []
    for player in payload.get("results") or []:
        raw = player.get("rating")
        if raw in (None, ""):
            continue
        try:
            ratings.append(float(raw))
        except (TypeError, ValueError):
            continue
    if not ratings:
        return None
    return sum(ratings) / len(ratings)


def gather_match_history(
    home_id: int,
    away_id: int,
    *,
    refresh_from_api: bool = True,
) -> list[MatchRecord]:
    if refresh_from_api:
        pull_team_history(home_id, last=10)
        pull_team_history(away_id, last=10)
        pull_h2h(home_id, away_id, last=10)
    return load_history_from_db()
