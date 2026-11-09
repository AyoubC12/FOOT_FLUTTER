"""HTTP access goes through ApiFootballService so existing tests keep patching it."""

from football.services.api_football import ApiFootballService


def client() -> ApiFootballService:
    return ApiFootballService()
