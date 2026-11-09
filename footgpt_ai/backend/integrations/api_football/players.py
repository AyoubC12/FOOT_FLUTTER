from .client import client


def list_players(params: dict) -> dict:
    return client().players(params)


def player_statistics(player_id: int, season: int) -> dict:
    return client().player_statistics({"id": player_id, "season": season})


def transfers(player_id: int) -> dict:
    return client().transfers(player_id)
