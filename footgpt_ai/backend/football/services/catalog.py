from __future__ import annotations

import re
from datetime import datetime
from typing import Any

from django.utils import timezone

from football.models import (
    Competition,
    CompetitionSeason,
    Player,
    PlayerSeasonStatistics,
    PlayerTransfer,
    Season,
    Team,
    TeamCompetition,
    TeamSeasonStatistics,
)
from integrations.api_football import competitions as competition_catalog
from integrations.api_football import images, seasons as season_lib
from integrations.api_football import players as player_api
from integrations.api_football import standings as standings_api
from integrations.api_football import statistics as stats_api
from integrations.api_football import teams as team_api


def ensure_season(year: int) -> Season:
    label = season_lib.season_label(year)
    season, _ = Season.objects.get_or_create(year=year, defaults={"label": label})
    if season.label != label:
        season.label = label
        season.save(update_fields=["label"])
    return season


def seed_competitions() -> int:
    created = 0
    for row in competition_catalog.CATALOG:
        _, was_created = Competition.objects.get_or_create(
            external_id=str(row["external_id"]),
            defaults={
                "name": row["name"],
                "country": row["country"],
                "type": row["type"],
            },
        )
        created += int(was_created)
    for year in season_lib.season_years():
        ensure_season(year)
    return created


def _parse_int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return int(value)
    match = re.search(r"\d+", str(value))
    return int(match.group()) if match else None


def _parse_float(value: Any) -> float | None:
    if value is None or value == "":
        return None
    if isinstance(value, (int, float)):
        return float(value)
    text = str(value).replace("%", "").strip()
    try:
        return float(text)
    except ValueError:
        return None


def _parse_date(value: Any):
    if not value:
        return None
    try:
        return datetime.strptime(str(value)[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def upsert_team(payload: dict, *, download_logo: bool = False) -> Team:
    team_id = payload.get("id")
    if not team_id:
        raise ValueError("Team payload is missing a provider id.")
    venue = payload.get("venue") or {}
    defaults = {
        "name": payload.get("name") or f"Team {team_id}",
        "short_name": (payload.get("code") or "")[:16],
        "country": payload.get("country") or "",
        "city": venue.get("city") or "",
        "stadium_name": venue.get("name") or "",
        "stadium_capacity": _parse_int(venue.get("capacity")),
        "founded": _parse_int(payload.get("founded")),
        "logo_url": payload.get("logo") or "",
        "national": bool(payload.get("national")),
    }
    team, _ = Team.objects.update_or_create(
        external_id=str(team_id),
        defaults=defaults,
    )
    if download_logo and team.logo_url and not team.logo_file:
        relative = images.download_jpeg(team.logo_url, "teams", team.external_id)
        if relative:
            team.logo_file.name = relative
            team.save(update_fields=["logo_file"])
    return team


def upsert_player(payload: dict, *, team: Team | None = None, download_photo: bool = False) -> Player:
    player_id = payload.get("id")
    if not player_id:
        raise ValueError("Player payload is missing a provider id.")
    birth = payload.get("birth") or {}
    defaults = {
        "name": payload.get("name") or f"Player {player_id}",
        "first_name": payload.get("firstname") or "",
        "last_name": payload.get("lastname") or "",
        "nationality": payload.get("nationality") or "",
        "position": payload.get("position") or "",
        "birth_date": _parse_date(birth.get("date")),
        "height_cm": _parse_int(payload.get("height")),
        "weight_kg": _parse_int(payload.get("weight")),
        "shirt_number": _parse_int(payload.get("number")),
        "photo_url": payload.get("photo") or "",
    }
    if team is not None:
        defaults["team"] = team
    player, _ = Player.objects.update_or_create(
        external_id=str(player_id),
        defaults=defaults,
    )
    if download_photo and player.photo_url and not player.photo_file:
        relative = images.download_jpeg(player.photo_url, "players", player.external_id)
        if relative:
            player.photo_file.name = relative
            player.save(update_fields=["photo_file"])
    return player


def link_team_competition(team: Team, competition: Competition, year: int) -> TeamCompetition:
    ensure_season(year)
    link, _ = TeamCompetition.objects.get_or_create(
        team=team, competition=competition, year=year
    )
    return link


def persist_team_statistics(team: Team, competition: Competition, year: int, payload: dict) -> TeamSeasonStatistics:
    fixtures = payload.get("fixtures") or {}
    goals = payload.get("goals") or {}
    played = fixtures.get("played") or {}
    wins = fixtures.get("wins") or {}
    draws = fixtures.get("draws") or {}
    loses = fixtures.get("loses") or {}
    goals_for = (goals.get("for") or {}) if isinstance(goals.get("for"), dict) else {}
    goals_against = (goals.get("against") or {}) if isinstance(goals.get("against"), dict) else {}
    clean = payload.get("clean_sheet") or {}
    cards = payload.get("cards") or {}
    yellow = cards.get("yellow") or {}
    red = cards.get("red") or {}
    stats, _ = TeamSeasonStatistics.objects.update_or_create(
        team=team,
        competition=competition,
        year=year,
        defaults={
            "played": _parse_int(played.get("total")),
            "wins": _parse_int(wins.get("total")),
            "draws": _parse_int(draws.get("total")),
            "losses": _parse_int(loses.get("total")),
            "goals_for": _parse_int(goals_for.get("total")),
            "goals_against": _parse_int(goals_against.get("total")),
            "clean_sheets": _parse_int(clean.get("total")),
            "home_played": _parse_int(played.get("home")),
            "home_wins": _parse_int(wins.get("home")),
            "home_draws": _parse_int(draws.get("home")),
            "home_losses": _parse_int(loses.get("home")),
            "away_played": _parse_int(played.get("away")),
            "away_wins": _parse_int(wins.get("away")),
            "away_draws": _parse_int(draws.get("away")),
            "away_losses": _parse_int(loses.get("away")),
            "yellow_cards": _parse_int((yellow.get("total") or {}).get("total") if isinstance(yellow.get("total"), dict) else yellow.get("total")),
            "red_cards": _parse_int((red.get("total") or {}).get("total") if isinstance(red.get("total"), dict) else red.get("total")),
            "form": payload.get("form") or "",
            "raw": payload,
        },
    )
    if stats.goals_for is not None and stats.goals_against is not None:
        stats.goal_diff = stats.goals_for - stats.goals_against
        stats.save(update_fields=["goal_diff"])
    return stats


def persist_standings_row(row: dict, competition: Competition, year: int) -> TeamSeasonStatistics | None:
    team_payload = row.get("team") or {}
    if not team_payload.get("id"):
        return None
    team = upsert_team(team_payload)
    link_team_competition(team, competition, year)
    played = _parse_int(row.get("played"))
    wins = _parse_int(row.get("win"))
    draws = _parse_int(row.get("draw"))
    losses = _parse_int(row.get("lose"))
    goals_for = _parse_int(row.get("goals_for"))
    goals_against = _parse_int(row.get("goals_against"))
    home = row.get("home") or {}
    away = row.get("away") or {}
    stats, _ = TeamSeasonStatistics.objects.update_or_create(
        team=team,
        competition=competition,
        year=year,
        defaults={
            "played": played,
            "wins": wins,
            "draws": draws,
            "losses": losses,
            "goals_for": goals_for,
            "goals_against": goals_against,
            "goal_diff": _parse_int(row.get("goals_diff")),
            "points": _parse_int(row.get("points")),
            "rank": _parse_int(row.get("rank")),
            "form": row.get("form") or "",
            "home_played": _parse_int(home.get("played")),
            "home_wins": _parse_int(home.get("win")),
            "home_draws": _parse_int(home.get("draw")),
            "home_losses": _parse_int(home.get("lose")),
            "away_played": _parse_int(away.get("played")),
            "away_wins": _parse_int(away.get("win")),
            "away_draws": _parse_int(away.get("draw")),
            "away_losses": _parse_int(away.get("lose")),
            "raw": row,
        },
    )
    return stats


def persist_player_season(player: Player, block: dict, year: int) -> PlayerSeasonStatistics:
    games = block.get("games") or {}
    goals = block.get("goals") or {}
    shots = block.get("shots") or {}
    passes = block.get("passes") or {}
    dribbles = block.get("dribbles") or {}
    duels = block.get("duels") or {}
    cards = block.get("cards") or {}
    team = None
    team_payload = block.get("team") or {}
    if team_payload.get("id"):
        team = upsert_team(team_payload)
        player.team = team
        if team_payload.get("id"):
            player.save(update_fields=["team"])
    competition = None
    league = block.get("league") or {}
    if league.get("id"):
        competition, _ = Competition.objects.get_or_create(
            external_id=str(league["id"]),
            defaults={
                "name": league.get("name") or f"League {league['id']}",
                "country": league.get("country") or "",
            },
        )
    stats, _ = PlayerSeasonStatistics.objects.update_or_create(
        player=player,
        competition=competition,
        year=year,
        defaults={
            "team": team,
            "appearances": _parse_int(games.get("appearences")),
            "lineups": _parse_int(games.get("lineups")),
            "minutes": _parse_int(games.get("minutes")),
            "goals": _parse_int(goals.get("total")),
            "assists": _parse_int(goals.get("assists")),
            "yellow_cards": _parse_int(cards.get("yellow")),
            "red_cards": _parse_int(cards.get("red")),
            "shots": _parse_int(shots.get("total")),
            "shots_on": _parse_int(shots.get("on")),
            "passes": _parse_int(passes.get("total")),
            "passes_accurate": _parse_int(passes.get("accurate") or passes.get("key")),
            "pass_accuracy": _parse_float(passes.get("accuracy")),
            "dribbles": _parse_int(dribbles.get("success") or dribbles.get("attempts")),
            "duels_won": _parse_int(duels.get("won")),
            "saves": _parse_int(goals.get("saves")),
            "goals_conceded": _parse_int(goals.get("conceded")),
            "rating": _parse_float(games.get("rating")),
            "raw": block,
        },
    )
    return stats


def persist_squad_players(team: Team, payload: dict) -> list[Player]:
    stored: list[Player] = []
    for block in payload.get("results") or []:
        for row in block.get("players") or []:
            if not row.get("id"):
                continue
            stored.append(
                upsert_player(
                    {
                        "id": row.get("id"),
                        "name": row.get("name"),
                        "photo": row.get("photo"),
                        "position": row.get("position"),
                        "number": row.get("number"),
                        "age": row.get("age"),
                    },
                    team=team,
                )
            )
    return stored


def persist_transfers(player: Player, payload: dict) -> int:
    stored = 0
    for item in payload.get("results") or []:
        for row in item.get("transfers") or []:
            teams = row.get("teams") or {}
            team_in = teams.get("in") or {}
            team_out = teams.get("out") or {}
            _, created = PlayerTransfer.objects.get_or_create(
                player=player,
                date=_parse_date(row.get("date")),
                team_in_external_id=str(team_in.get("id") or ""),
                team_out_external_id=str(team_out.get("id") or ""),
                defaults={
                    "transfer_type": row.get("type") or "",
                    "team_in_name": team_in.get("name") or "",
                    "team_out_name": team_out.get("name") or "",
                },
            )
            stored += int(created)
    return stored


def sync_league_teams(league_id: int, year: int, *, download_media: bool = False) -> list[Team]:
    seed_competitions()
    competition = Competition.objects.get(external_id=str(league_id))
    ensure_season(year)
    payload = team_api.list_teams({"league": league_id, "season": year})
    teams = []
    for item in payload.get("results") or []:
        team = upsert_team(item, download_logo=download_media)
        link_team_competition(team, competition, year)
        teams.append(team)
    CompetitionSeason.objects.update_or_create(
        competition=competition,
        year=year,
        defaults={
            "is_current": season_lib.is_season_current(year),
            "synced_at": timezone.now(),
        },
    )
    return teams


def sync_standings(league_id: int, year: int) -> int:
    seed_competitions()
    competition, _ = Competition.objects.get_or_create(
        external_id=str(league_id),
        defaults={"name": f"League {league_id}"},
    )
    payload = standings_api.standings(league=league_id, season=year)
    count = 0
    for table in payload.get("results") or []:
        for group in table.get("standings") or []:
            for row in group:
                if persist_standings_row(row, competition, year):
                    count += 1
    return count


def sync_team_statistics(team: Team, league_id: int, year: int) -> TeamSeasonStatistics:
    competition = Competition.objects.get(external_id=str(league_id))
    payload = stats_api.team_statistics(
        team_id=int(team.external_id), league=league_id, season=year
    )
    body = payload.get("results") or {}
    return persist_team_statistics(team, competition, year, body)


def sync_player_season(player_id: int, year: int, *, download_photo: bool = False) -> Player | None:
    payload = player_api.player_statistics(player_id, year)
    body = payload.get("results") or {}
    if not body.get("id"):
        return None
    player = upsert_player(body, download_photo=download_photo)
    for block in body.get("statistics") or []:
        persist_player_season(player, block, year)
    return player
