from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


FINISHED_STATUSES = {"FT", "AET", "PEN"}


@dataclass(frozen=True)
class MatchRecord:
    match_id: str
    kickoff_at: datetime
    home_id: int
    away_id: int
    home_name: str
    away_name: str
    home_goals: int
    away_goals: int
    league_id: int | None = None
    season: int | None = None

    @property
    def result(self) -> str:
        if self.home_goals > self.away_goals:
            return "home"
        if self.home_goals < self.away_goals:
            return "away"
        return "draw"


DISCLAIMER = (
    "This is a probabilistic estimate, not a guaranteed outcome. "
    "Football results remain uncertain even with strong historical signals."
)
