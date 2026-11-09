from __future__ import annotations

from collections import defaultdict
from datetime import datetime

import numpy as np
import pandas as pd

from .records import MatchRecord

FEATURE_COLUMNS = [
    "home_prior_matches",
    "away_prior_matches",
    "h2h_matches",
    "home_gf_avg_5",
    "home_ga_avg_5",
    "home_gd_avg_5",
    "home_pts_avg_5",
    "home_gf_avg_10",
    "home_ga_avg_10",
    "home_pts_avg_10",
    "away_gf_avg_5",
    "away_ga_avg_5",
    "away_gd_avg_5",
    "away_pts_avg_5",
    "away_gf_avg_10",
    "away_ga_avg_10",
    "away_pts_avg_10",
    "home_home_gf_avg_5",
    "home_home_ga_avg_5",
    "home_home_pts_avg_5",
    "away_away_gf_avg_5",
    "away_away_ga_avg_5",
    "away_away_pts_avg_5",
    "h2h_home_win_pct",
    "h2h_draw_pct",
    "h2h_gf_avg",
    "h2h_ga_avg",
    "elo_home",
    "elo_away",
    "elo_diff",
    "home_player_rating",
    "away_player_rating",
]

MIN_PRIOR_MATCHES = 5
WINDOW_SHORT = 5
WINDOW_LONG = 10
ELO_START = 1500.0
ELO_K = 20.0
HOME_ADVANTAGE = 60.0


def _points(goals_for: int, goals_against: int) -> int:
    if goals_for > goals_against:
        return 3
    if goals_for == goals_against:
        return 1
    return 0


def _window_stats(rows: list[tuple[int, int]], size: int) -> dict[str, float]:
    sample = rows[-size:]
    if not sample:
        return {"gf": np.nan, "ga": np.nan, "gd": np.nan, "pts": np.nan, "n": 0}
    gf = [row[0] for row in sample]
    ga = [row[1] for row in sample]
    pts = [_points(a, b) for a, b in sample]
    return {
        "gf": float(np.mean(gf)),
        "ga": float(np.mean(ga)),
        "gd": float(np.mean(np.array(gf) - np.array(ga))),
        "pts": float(np.mean(pts)),
        "n": len(sample),
    }


def _expected_score(elo_a: float, elo_b: float) -> float:
    return 1.0 / (1.0 + 10 ** ((elo_b - elo_a) / 400.0))


def build_features_for_match(
    history: list[MatchRecord],
    *,
    home_id: int,
    away_id: int,
    kickoff_at: datetime,
    home_player_rating: float | None = None,
    away_player_rating: float | None = None,
) -> dict[str, float]:
    """Use only matches strictly before kickoff_at."""
    prior = [match for match in history if match.kickoff_at < kickoff_at]
    prior.sort(key=lambda match: match.kickoff_at)

    team_all: dict[int, list[tuple[int, int]]] = defaultdict(list)
    team_home: dict[int, list[tuple[int, int]]] = defaultdict(list)
    team_away: dict[int, list[tuple[int, int]]] = defaultdict(list)
    h2h: list[tuple[int, int]] = []
    elo: dict[int, float] = defaultdict(lambda: ELO_START)

    for match in prior:
        home_gf, home_ga = match.home_goals, match.away_goals
        away_gf, away_ga = match.away_goals, match.home_goals
        team_all[match.home_id].append((home_gf, home_ga))
        team_all[match.away_id].append((away_gf, away_ga))
        team_home[match.home_id].append((home_gf, home_ga))
        team_away[match.away_id].append((away_gf, away_ga))
        pair = {match.home_id, match.away_id}
        if pair == {home_id, away_id}:
            if match.home_id == home_id:
                h2h.append((home_gf, home_ga))
            else:
                h2h.append((away_gf, away_ga))

        home_elo = elo[match.home_id]
        away_elo = elo[match.away_id]
        exp_home = _expected_score(home_elo + HOME_ADVANTAGE, away_elo)
        if match.home_goals > match.away_goals:
            score_home = 1.0
        elif match.home_goals < match.away_goals:
            score_home = 0.0
        else:
            score_home = 0.5
        elo[match.home_id] = home_elo + ELO_K * (score_home - exp_home)
        elo[match.away_id] = away_elo + ELO_K * ((1 - score_home) - (1 - exp_home))

    home_5 = _window_stats(team_all[home_id], WINDOW_SHORT)
    home_10 = _window_stats(team_all[home_id], WINDOW_LONG)
    away_5 = _window_stats(team_all[away_id], WINDOW_SHORT)
    away_10 = _window_stats(team_all[away_id], WINDOW_LONG)
    home_home = _window_stats(team_home[home_id], WINDOW_SHORT)
    away_away = _window_stats(team_away[away_id], WINDOW_SHORT)
    h2h_stats = _window_stats(h2h, WINDOW_LONG)
    h2h_wins = sum(1 for gf, ga in h2h if gf > ga)
    h2h_draws = sum(1 for gf, ga in h2h if gf == ga)

    return {
        "home_prior_matches": float(len(team_all[home_id])),
        "away_prior_matches": float(len(team_all[away_id])),
        "h2h_matches": float(len(h2h)),
        "home_gf_avg_5": home_5["gf"],
        "home_ga_avg_5": home_5["ga"],
        "home_gd_avg_5": home_5["gd"],
        "home_pts_avg_5": home_5["pts"],
        "home_gf_avg_10": home_10["gf"],
        "home_ga_avg_10": home_10["ga"],
        "home_pts_avg_10": home_10["pts"],
        "away_gf_avg_5": away_5["gf"],
        "away_ga_avg_5": away_5["ga"],
        "away_gd_avg_5": away_5["gd"],
        "away_pts_avg_5": away_5["pts"],
        "away_gf_avg_10": away_10["gf"],
        "away_ga_avg_10": away_10["ga"],
        "away_pts_avg_10": away_10["pts"],
        "home_home_gf_avg_5": home_home["gf"],
        "home_home_ga_avg_5": home_home["ga"],
        "home_home_pts_avg_5": home_home["pts"],
        "away_away_gf_avg_5": away_away["gf"],
        "away_away_ga_avg_5": away_away["ga"],
        "away_away_pts_avg_5": away_away["pts"],
        "h2h_home_win_pct": (h2h_wins / len(h2h)) if h2h else np.nan,
        "h2h_draw_pct": (h2h_draws / len(h2h)) if h2h else np.nan,
        "h2h_gf_avg": h2h_stats["gf"],
        "h2h_ga_avg": h2h_stats["ga"],
        "elo_home": float(elo[home_id]),
        "elo_away": float(elo[away_id]),
        "elo_diff": float(elo[home_id] - elo[away_id]),
        "home_player_rating": (
            float(home_player_rating) if home_player_rating is not None else np.nan
        ),
        "away_player_rating": (
            float(away_player_rating) if away_player_rating is not None else np.nan
        ),
    }


def sufficient_history(features: dict[str, float]) -> bool:
    return (
        features.get("home_prior_matches", 0) >= MIN_PRIOR_MATCHES
        and features.get("away_prior_matches", 0) >= MIN_PRIOR_MATCHES
    )


def build_training_frame(matches: list[MatchRecord]) -> pd.DataFrame:
    ordered = sorted(matches, key=lambda match: match.kickoff_at)
    rows = []
    for index, match in enumerate(ordered):
        history = ordered[:index]
        features = build_features_for_match(
            history,
            home_id=match.home_id,
            away_id=match.away_id,
            kickoff_at=match.kickoff_at,
        )
        if not sufficient_history(features):
            continue
        row = {
            **features,
            "kickoff_at": match.kickoff_at,
            "match_id": match.match_id,
            "label": match.result,
        }
        rows.append(row)
    if not rows:
        return pd.DataFrame(columns=[*FEATURE_COLUMNS, "kickoff_at", "match_id", "label"])
    return pd.DataFrame(rows)


def chronological_split(frame: pd.DataFrame, test_frac: float = 0.2) -> tuple[pd.DataFrame, pd.DataFrame]:
    if frame.empty:
        return frame, frame
    ordered = frame.sort_values("kickoff_at").reset_index(drop=True)
    cut = max(1, int(len(ordered) * (1 - test_frac)))
    if cut >= len(ordered):
        cut = len(ordered) - 1
    train = ordered.iloc[:cut].copy()
    test = ordered.iloc[cut:].copy()
    return train, test
