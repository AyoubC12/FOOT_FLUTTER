"""Map API-Football payloads into stable Flutter-facing shapes.

Missing stats stay null. Scores are copied from the provider and never invented.
"""

from __future__ import annotations


def _get(data: dict | None, *keys, default=None):
    current = data
    for key in keys:
        if not isinstance(current, dict):
            return default
        current = current.get(key)
        if current is None:
            return default
    return current


def team_ref(payload: dict | None) -> dict | None:
    if not payload:
        return None
    return {
        "id": payload.get("id"),
        "name": payload.get("name"),
        "code": payload.get("code"),
        "logo": payload.get("logo"),
        "country": payload.get("country"),
        "founded": payload.get("founded"),
        "national": payload.get("national"),
    }


def venue_ref(payload: dict | None) -> dict | None:
    if not payload:
        return None
    return {
        "id": payload.get("id"),
        "name": payload.get("name"),
        "city": payload.get("city"),
        "capacity": payload.get("capacity"),
    }


def normalize_team(item: dict) -> dict:
    team = item.get("team") or item
    venue = item.get("venue")
    return {
        **(team_ref(team) or {}),
        "venue": venue_ref(venue),
    }


def normalize_fixture(item: dict) -> dict:
    fixture = item.get("fixture") or {}
    league = item.get("league") or {}
    teams = item.get("teams") or {}
    goals = item.get("goals") or {}
    score = item.get("score") or {}
    status = fixture.get("status") or {}
    return {
        "id": fixture.get("id"),
        "timezone": fixture.get("timezone"),
        "date": fixture.get("date"),
        "timestamp": fixture.get("timestamp"),
        "referee": fixture.get("referee"),
        "periods": fixture.get("periods") or {"first": None, "second": None},
        "venue": venue_ref(fixture.get("venue") or {}),
        "status": {
            "long": status.get("long"),
            "short": status.get("short"),
            "elapsed": status.get("elapsed"),
            "extra": status.get("extra"),
        },
        "league": {
            "id": league.get("id"),
            "name": league.get("name"),
            "country": league.get("country"),
            "logo": league.get("logo"),
            "flag": league.get("flag"),
            "season": league.get("season"),
            "round": league.get("round"),
        },
        "teams": {
            "home": team_ref(teams.get("home")),
            "away": team_ref(teams.get("away")),
        },
        "goals": {
            "home": goals.get("home"),
            "away": goals.get("away"),
        },
        "score": {
            "halftime": score.get("halftime") or {"home": None, "away": None},
            "fulltime": score.get("fulltime") or {"home": None, "away": None},
            "extratime": score.get("extratime") or {"home": None, "away": None},
            "penalty": score.get("penalty") or {"home": None, "away": None},
        },
    }


def statistics_map(entries: list | None) -> dict:
    raw = {}
    for row in entries or []:
        label = row.get("type")
        if label:
            raw[label] = row.get("value")
    return {
        "shots_on_goal": raw.get("Shots on Goal"),
        "shots_off_goal": raw.get("Shots off Goal"),
        "total_shots": raw.get("Total Shots"),
        "blocked_shots": raw.get("Blocked Shots"),
        "shots_inside_box": raw.get("Shots insidebox"),
        "shots_outside_box": raw.get("Shots outsidebox"),
        "fouls": raw.get("Fouls"),
        "corner_kicks": raw.get("Corner Kicks"),
        "offsides": raw.get("Offsides"),
        "ball_possession": raw.get("Ball Possession"),
        "yellow_cards": raw.get("Yellow Cards"),
        "red_cards": raw.get("Red Cards"),
        "goalkeeper_saves": raw.get("Goalkeeper Saves"),
        "total_passes": raw.get("Total passes"),
        "passes_accurate": raw.get("Passes accurate"),
        "passes_percentage": raw.get("Passes %"),
        "expected_goals": raw.get("expected_goals"),
        "raw": raw,
    }


def normalize_fixture_statistics(entries: list | None) -> list[dict]:
    result = []
    for item in entries or []:
        result.append(
            {
                "team": team_ref(item.get("team")),
                "statistics": statistics_map(item.get("statistics")),
            }
        )
    return result


def normalize_player(item: dict) -> dict:
    player = item.get("player") or {}
    statistics = item.get("statistics") or []
    first_stat = statistics[0] if statistics else {}
    games = first_stat.get("games") or {}
    goals = first_stat.get("goals") or {}
    team = first_stat.get("team") or {}
    league = first_stat.get("league") or {}
    return {
        "id": player.get("id"),
        "name": player.get("name"),
        "firstname": player.get("firstname"),
        "lastname": player.get("lastname"),
        "age": player.get("age"),
        "nationality": player.get("nationality"),
        "height": player.get("height"),
        "weight": player.get("weight"),
        "photo": player.get("photo"),
        "injured": player.get("injured"),
        "birth": player.get("birth") or {},
        "position": games.get("position"),
        "number": games.get("number"),
        "team": team_ref(team),
        "league": {
            "id": league.get("id"),
            "name": league.get("name"),
            "country": league.get("country"),
            "season": league.get("season"),
        },
        "goals": goals.get("total"),
        "assists": goals.get("assists"),
        "rating": games.get("rating"),
    }


def normalize_player_statistics(item: dict) -> dict:
    player = normalize_player(item)
    seasons = []
    for block in item.get("statistics") or []:
        games = block.get("games") or {}
        shots = block.get("shots") or {}
        goals = block.get("goals") or {}
        passes = block.get("passes") or {}
        tackles = block.get("tackles") or {}
        duels = block.get("duels") or {}
        dribbles = block.get("dribbles") or {}
        fouls = block.get("fouls") or {}
        cards = block.get("cards") or {}
        penalty = block.get("penalty") or {}
        seasons.append(
            {
                "team": team_ref(block.get("team")),
                "league": block.get("league") or {},
                "games": {
                    "appearences": games.get("appearences"),
                    "lineups": games.get("lineups"),
                    "minutes": games.get("minutes"),
                    "number": games.get("number"),
                    "position": games.get("position"),
                    "rating": games.get("rating"),
                    "captain": games.get("captain"),
                },
                "substitutes": block.get("substitutes") or {},
                "shots": {
                    "total": shots.get("total"),
                    "on": shots.get("on"),
                },
                "goals": {
                    "total": goals.get("total"),
                    "conceded": goals.get("conceded"),
                    "assists": goals.get("assists"),
                    "saves": goals.get("saves"),
                },
                "passes": {
                    "total": passes.get("total"),
                    "key": passes.get("key"),
                    "accuracy": passes.get("accuracy"),
                },
                "tackles": {
                    "total": tackles.get("total"),
                    "blocks": tackles.get("blocks"),
                    "interceptions": tackles.get("interceptions"),
                },
                "duels": {
                    "total": duels.get("total"),
                    "won": duels.get("won"),
                },
                "dribbles": {
                    "attempts": dribbles.get("attempts"),
                    "success": dribbles.get("success"),
                    "past": dribbles.get("past"),
                },
                "fouls": {
                    "drawn": fouls.get("drawn"),
                    "committed": fouls.get("committed"),
                },
                "cards": {
                    "yellow": cards.get("yellow"),
                    "yellowred": cards.get("yellowred"),
                    "red": cards.get("red"),
                },
                "penalty": penalty,
            }
        )
    player["statistics"] = seasons
    return player


def normalize_team_statistics(payload: dict | None) -> dict:
    data = payload or {}
    fixtures = data.get("fixtures") or {}
    goals = data.get("goals") or {}
    clean_sheet = data.get("clean_sheet") or {}
    failed_to_score = data.get("failed_to_score") or {}
    lineups = data.get("lineups") or []
    return {
        "league": data.get("league") or {},
        "team": team_ref(data.get("team")),
        "form": data.get("form"),
        "fixtures": {
            "played": fixtures.get("played") or {"home": None, "away": None, "total": None},
            "wins": fixtures.get("wins") or {"home": None, "away": None, "total": None},
            "draws": fixtures.get("draws") or {"home": None, "away": None, "total": None},
            "loses": fixtures.get("loses") or {"home": None, "away": None, "total": None},
        },
        "goals": {
            "for": _get(goals, "for", "total", default={"home": None, "away": None, "total": None}),
            "against": _get(
                goals, "against", "total", default={"home": None, "away": None, "total": None}
            ),
            "average_for": _get(goals, "for", "average"),
            "average_against": _get(goals, "against", "average"),
        },
        "clean_sheet": clean_sheet,
        "failed_to_score": failed_to_score,
        "penalty": data.get("penalty") or {},
        "lineups": lineups,
        "cards": data.get("cards") or {},
    }


def normalize_standings(payload: list | None) -> list[dict]:
    tables = []
    for league_block in payload or []:
        league = league_block.get("league") or {}
        groups = []
        for group in league.get("standings") or []:
            rows = []
            for row in group:
                all_stats = row.get("all") or {}
                rows.append(
                    {
                        "rank": row.get("rank"),
                        "team": team_ref(row.get("team")),
                        "points": row.get("points"),
                        "goals_diff": row.get("goalsDiff"),
                        "group": row.get("group"),
                        "form": row.get("form"),
                        "status": row.get("status"),
                        "description": row.get("description"),
                        "played": _get(all_stats, "played"),
                        "win": _get(all_stats, "win"),
                        "draw": _get(all_stats, "draw"),
                        "lose": _get(all_stats, "lose"),
                        "goals_for": _get(all_stats, "goals", "for"),
                        "goals_against": _get(all_stats, "goals", "against"),
                        "home": row.get("home") or {},
                        "away": row.get("away") or {},
                    }
                )
            groups.append(rows)
        tables.append(
            {
                "league": {
                    "id": league.get("id"),
                    "name": league.get("name"),
                    "country": league.get("country"),
                    "logo": league.get("logo"),
                    "season": league.get("season"),
                },
                "standings": groups,
            }
        )
    return tables
