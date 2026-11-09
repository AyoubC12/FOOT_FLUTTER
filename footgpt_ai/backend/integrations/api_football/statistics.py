from .client import client


def team_statistics(*, team_id: int, league: int, season: int) -> dict:
    return client().team_statistics(
        {"team": team_id, "league": league, "season": season}
    )
