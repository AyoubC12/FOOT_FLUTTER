from .client import client


def list_teams(params: dict) -> dict:
    return client().teams(params)


def team_detail(team_id: int) -> dict:
    return client().team_detail(team_id)


def squad(team_id: int) -> dict:
    return client().squads(team_id)


def coaches(team_id: int) -> dict:
    return client().coaches({"team": team_id})
