from __future__ import annotations

from .features import FEATURE_COLUMNS
from .records import DISCLAIMER


def explain_prediction(
    *,
    features: dict,
    percentages: dict[str, float],
    model_name: str,
    sufficient: bool,
    missing_notes: list[str],
) -> str:
    parts = []
    if not sufficient:
        parts.append(
            "Insufficient finished-match history: at least 5 prior results per team "
            "are required for a trained matchup estimate. Probabilities below use a "
            "weak prior from available outcomes, not a full model."
        )
    else:
        home_pts = features.get("home_pts_avg_5")
        away_pts = features.get("away_pts_avg_5")
        if home_pts == home_pts and away_pts == away_pts:
            parts.append(
                f"Recent form (points per game, last 5): home {home_pts:.2f} vs away {away_pts:.2f}."
            )
        home_home = features.get("home_home_pts_avg_5")
        away_away = features.get("away_away_pts_avg_5")
        if home_home == home_home and away_away == away_away:
            parts.append(
                f"Venue splits (last 5): home side at home {home_home:.2f} ppg, "
                f"away side on the road {away_away:.2f} ppg."
            )
        h2h_n = features.get("h2h_matches") or 0
        if h2h_n:
            win_pct = features.get("h2h_home_win_pct")
            if win_pct == win_pct:
                parts.append(
                    f"Head-to-head sample: {int(h2h_n)} prior meetings, "
                    f"home-win share {win_pct:.0%}."
                )
            else:
                parts.append(f"Head-to-head sample: {int(h2h_n)} prior meetings.")
        else:
            parts.append("No usable head-to-head meetings were found before kickoff.")
        elo_diff = features.get("elo_diff")
        if elo_diff == elo_diff:
            stronger = "home" if elo_diff > 0 else "away"
            parts.append(f"Walking Elo before kickoff leans {stronger} ({elo_diff:+.0f}).")
        if features.get("home_player_rating") != features.get("home_player_rating"):
            parts.append("Player ratings were unavailable and were treated as missing.")

    if missing_notes:
        parts.extend(missing_notes)
    parts.append(
        f"Model: {model_name}. Estimated chances — home {percentages['home']:.1f}%, "
        f"draw {percentages['draw']:.1f}%, away {percentages['away']:.1f}%."
    )
    parts.append(DISCLAIMER)
    return " ".join(parts)


def top_numeric_drivers(features: dict) -> list[str]:
    interesting = []
    for key in FEATURE_COLUMNS:
        value = features.get(key)
        if value is None or value != value:
            continue
        interesting.append(f"{key}={value:.3f}")
    return interesting[:8]
