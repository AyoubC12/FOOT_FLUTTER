from .client import client


def fixtures(params: dict) -> dict:
    return client().fixtures(params)


def fixture_detail(fixture_id: int) -> dict:
    return client().fixture_detail(fixture_id)
