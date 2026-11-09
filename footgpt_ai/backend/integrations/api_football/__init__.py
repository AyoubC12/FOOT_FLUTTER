from .client import client
from .competitions import CATALOG
from .seasons import FIRST_YEAR, LAST_YEAR, is_season_complete, is_season_current, season_label

__all__ = [
    "CATALOG",
    "FIRST_YEAR",
    "LAST_YEAR",
    "client",
    "is_season_complete",
    "is_season_current",
    "season_label",
]
