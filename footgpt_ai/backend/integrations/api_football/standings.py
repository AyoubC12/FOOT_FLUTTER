from .client import client


def standings(*, league: int, season: int, team: int | None = None) -> dict:
    params = {"league": league, "season": season}
    if team:
        params["team"] = team
    return client().standings(params)
