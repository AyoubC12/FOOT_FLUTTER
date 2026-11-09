"""Fetch-on-read from API-Football into the catalog. Never invents values."""

from __future__ import annotations

from football.exceptions import FootballProviderError
from football.models import Competition, Player, Team, TeamSeasonStatistics
from football.services.catalog import (
    persist_player_season,
    persist_squad_players,
    persist_standings_row,
    persist_transfers,
    seed_competitions,
    sync_team_statistics,
    upsert_player,
    upsert_team,
)
from integrations.api_football import players as player_api
from integrations.api_football import standings as standings_api
from integrations.api_football import teams as team_api
from integrations.api_football.seasons import LAST_YEAR, is_season_current, season_years


def ensure_team(team_id: int) -> Team:
    team = Team.objects.filter(external_id=str(team_id)).first()
    if team:
        return team
    payload = team_api.team_detail(team_id)
    body = payload.get("results") or {}
    if not body.get("id"):
        raise FootballProviderError("Team not found.", status_code=404)
    return upsert_team(body)


def refresh_squad(team_id: int) -> list[Player]:
    team = ensure_team(team_id)
    payload = team_api.squad(team_id)
    return persist_squad_players(team, payload)


def refresh_team_seasons(
    team_id: int,
    league_id: int,
    *,
    max_seasons: int = 8,
) -> list[TeamSeasonStatistics]:
    seed_competitions()
    team = ensure_team(team_id)
    competition = Competition.objects.filter(external_id=str(league_id)).first()
    if not competition:
        raise FootballProviderError("Unknown competition.", status_code=404)

    years = [year for year in reversed(season_years()) if year <= LAST_YEAR][:max_seasons]
    for year in years:
        exists = TeamSeasonStatistics.objects.filter(
            team=team, competition=competition, year=year
        ).exists()
        if exists and not is_season_current(year):
            continue
        try:
            payload = standings_api.standings(
                league=league_id, season=year, team=team_id
            )
        except FootballProviderError:
            continue
        for table in payload.get("results") or []:
            for group in table.get("standings") or []:
                for row in group:
                    persist_standings_row(row, competition, year)
        try:
            sync_team_statistics(team, league_id, year)
        except FootballProviderError:
            continue

    return list(
        TeamSeasonStatistics.objects.filter(team=team, competition=competition)
        .select_related("competition")
        .order_by("-year")
    )


def refresh_player_seasons(player_id: int, *, max_seasons: int = 8) -> Player | None:
    years = [year for year in reversed(season_years()) if year <= LAST_YEAR][:max_seasons]
    player = None
    for year in years:
        try:
            payload = player_api.player_statistics(player_id, year)
        except FootballProviderError:
            continue
        body = payload.get("results") or {}
        if not body.get("id"):
            continue
        player = upsert_player(body)
        for block in body.get("statistics") or []:
            persist_player_season(player, block, year)
    if player is None:
        return Player.objects.filter(external_id=str(player_id)).first()
    try:
        persist_transfers(player, player_api.transfers(player_id))
    except FootballProviderError:
        pass
    return player
