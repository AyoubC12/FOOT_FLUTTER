"""Tool callbacks that return verified backend/provider data only."""

from __future__ import annotations

from football.exceptions import FootballProviderError
from football.services.api_football import ApiFootballService
from predictions.models import Prediction

FORMATION_NOTES = {
    "4-3-3": (
        "A 4-3-3 uses a back four, a midfield three and a front three. "
        "The holding midfielder often screens the centre-backs while the 8s join attacks. "
        "The front three can press the opposition centre-backs and full-backs. "
        "This is general tactics, not a claim about a specific club's current lineup."
    ),
    "4-2-3-1": (
        "A 4-2-3-1 uses a double pivot, an attacking midfielder and a lone striker. "
        "The 10 links midfield to the 9; wide 10s/wingers supply crosses or underlaps. "
        "The double pivot helps against central overloads. General tactics only."
    ),
    "3-5-2": (
        "A 3-5-2 uses three centre-backs and wing-backs who supply width. "
        "The midfield three can dominate the centre; two strikers occupy both centre-backs. "
        "Rest defence depends on the wing-backs recovering. General tactics only."
    ),
    "4-4-2": (
        "A 4-4-2 uses two banks of four and two strikers. "
        "Wide midfielders must track full-backs; the strikers can press the first pass. "
        "General tactics only."
    ),
}


def _service() -> ApiFootballService:
    return ApiFootballService()


def _unavailable(reason: str) -> dict:
    return {"available": False, "reason": reason, "data": None}


def get_player_statistics(search: str | None, player_id: int | None, season: int) -> dict:
    try:
        params = {"season": season}
        if player_id:
            params["id"] = player_id
        elif search:
            params["search"] = search.strip()
        else:
            return _unavailable("Provide a player search name or player_id.")
        payload = _service().players(params)
        results = payload.get("results") or []
        if not results:
            return _unavailable("No verified player statistics were returned for that query.")
        trimmed = []
        for row in results[:3]:
            trimmed.append(
                {
                    "id": row.get("id"),
                    "name": row.get("name"),
                    "team": (row.get("team") or {}).get("name"),
                    "position": row.get("position"),
                    "goals": row.get("goals"),
                    "assists": row.get("assists"),
                    "rating": row.get("rating"),
                    "nationality": row.get("nationality"),
                    "league": (row.get("league") or {}).get("name"),
                    "season": (row.get("league") or {}).get("season"),
                }
            )
        return {"available": True, "data": trimmed}
    except FootballProviderError as exc:
        return _unavailable(exc.message)


def get_team_statistics(team_id: int, league: int, season: int) -> dict:
    try:
        payload = _service().team_statistics(
            {"team": team_id, "league": league, "season": season}
        )
        results = payload.get("results") or {}
        if not results:
            return _unavailable("No verified team statistics were returned.")
        return {
            "available": True,
            "data": {
                "team": (results.get("team") or {}).get("name"),
                "form": results.get("form"),
                "fixtures": results.get("fixtures"),
                "goals": results.get("goals"),
            },
        }
    except FootballProviderError as exc:
        return _unavailable(exc.message)


def get_head_to_head(home_id: int, away_id: int, last: int = 5) -> dict:
    try:
        payload = _service().head_to_head(
            {"h2h": f"{home_id}-{away_id}", "last": min(last, 10)}
        )
        rows = []
        for item in payload.get("results") or []:
            goals = item.get("goals") or {}
            if goals.get("home") is None or goals.get("away") is None:
                continue
            teams = item.get("teams") or {}
            rows.append(
                {
                    "date": item.get("date"),
                    "home": (teams.get("home") or {}).get("name"),
                    "away": (teams.get("away") or {}).get("name"),
                    "goals": goals,
                    "status": (item.get("status") or {}).get("short"),
                }
            )
        if not rows:
            return _unavailable("No finished head-to-head matches with scores were available.")
        return {"available": True, "data": rows}
    except FootballProviderError as exc:
        return _unavailable(exc.message)


def get_formation_guide(formation: str) -> dict:
    key = formation.strip().replace(" ", "")
    note = FORMATION_NOTES.get(key)
    if not note:
        return _unavailable(
            "That formation is not in the verified tactics notes. "
            "Ask about 4-3-3, 4-2-3-1, 3-5-2 or 4-4-2."
        )
    return {"available": True, "data": {"formation": key, "explanation": note}}


def get_stored_prediction(user, home_team: str | None, away_team: str | None) -> dict:
    qs = Prediction.objects.filter(user=user).order_by("-created_at")
    if home_team:
        qs = qs.filter(home_team__icontains=home_team.strip())
    if away_team:
        qs = qs.filter(away_team__icontains=away_team.strip())
    row = qs.first()
    if row is None:
        return _unavailable("No stored FootGPT prediction matched that query.")
    return {
        "available": True,
        "data": {
            "home_team": row.home_team,
            "away_team": row.away_team,
            "probabilities": row.probabilities,
            "predicted_result": row.predicted_result,
            "data_quality": row.data_quality,
            "explanation": row.explanation,
            "disclaimer": "Probabilistic estimate only, not a guaranteed outcome.",
        },
    }


TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "get_player_statistics",
            "description": "Fetch verified player statistics from the football data provider.",
            "parameters": {
                "type": "object",
                "properties": {
                    "search": {"type": "string"},
                    "player_id": {"type": "integer"},
                    "season": {"type": "integer"},
                },
                "required": ["season"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_team_statistics",
            "description": "Fetch verified team season statistics.",
            "parameters": {
                "type": "object",
                "properties": {
                    "team_id": {"type": "integer"},
                    "league": {"type": "integer"},
                    "season": {"type": "integer"},
                },
                "required": ["team_id", "league", "season"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_head_to_head",
            "description": "Fetch finished head-to-head matches with scores from the provider.",
            "parameters": {
                "type": "object",
                "properties": {
                    "home_id": {"type": "integer"},
                    "away_id": {"type": "integer"},
                    "last": {"type": "integer"},
                },
                "required": ["home_id", "away_id"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_formation_guide",
            "description": "Explain a generic tactical formation from verified notes.",
            "parameters": {
                "type": "object",
                "properties": {"formation": {"type": "string"}},
                "required": ["formation"],
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "get_stored_prediction",
            "description": "Explain a FootGPT prediction stored for this user.",
            "parameters": {
                "type": "object",
                "properties": {
                    "home_team": {"type": "string"},
                    "away_team": {"type": "string"},
                },
            },
        },
    },
]


def dispatch_tool(name: str, arguments: dict, user) -> dict:
    try:
        return _dispatch_tool(name, arguments, user)
    except (KeyError, TypeError, ValueError):
        return _unavailable("The tool was called with incomplete arguments.")


def _dispatch_tool(name: str, arguments: dict, user) -> dict:
    if name == "get_player_statistics":
        return get_player_statistics(
            arguments.get("search"),
            arguments.get("player_id"),
            int(arguments.get("season")),
        )
    if name == "get_team_statistics":
        return get_team_statistics(
            int(arguments["team_id"]),
            int(arguments["league"]),
            int(arguments["season"]),
        )
    if name == "get_head_to_head":
        return get_head_to_head(
            int(arguments["home_id"]),
            int(arguments["away_id"]),
            int(arguments.get("last") or 5),
        )
    if name == "get_formation_guide":
        return get_formation_guide(str(arguments.get("formation") or ""))
    if name == "get_stored_prediction":
        return get_stored_prediction(
            user,
            arguments.get("home_team"),
            arguments.get("away_team"),
        )
    return _unavailable("Unknown tool.")
