from __future__ import annotations

METRIC_FIELDS = (
    ("appearances", "Appearances"),
    ("minutes", "Minutes"),
    ("rating", "Rating"),
    ("goals", "Goals"),
    ("assists", "Assists"),
    ("shots", "Shots"),
    ("shots_on", "Shots on target"),
    ("passes", "Passes"),
    ("key_passes", "Key passes"),
    ("pass_accuracy", "Pass accuracy"),
    ("tackles", "Tackles"),
    ("interceptions", "Interceptions"),
    ("blocks", "Blocks"),
    ("duels_won", "Duels won"),
    ("dribbles_success", "Successful dribbles"),
)


def as_number(value) -> int | float | None:
    if value is None or value == "":
        return None
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return value
    try:
        text = str(value).strip()
        if not text:
            return None
        if "." in text:
            return float(text)
        return int(text)
    except (TypeError, ValueError):
        return None


def primary_statistics(player: dict | None) -> dict | None:
    blocks = (player or {}).get("statistics") or []
    if not blocks:
        return None

    def _appearances(block: dict) -> int:
        games = block.get("games") or {}
        value = as_number(games.get("appearences"))
        return int(value) if value is not None else -1

    return max(blocks, key=_appearances)


def extract_metrics(block: dict | None) -> dict:
    if not block:
        return {key: None for key, _ in METRIC_FIELDS}
    games = block.get("games") or {}
    goals = block.get("goals") or {}
    shots = block.get("shots") or {}
    passes = block.get("passes") or {}
    tackles = block.get("tackles") or {}
    duels = block.get("duels") or {}
    dribbles = block.get("dribbles") or {}
    return {
        "appearances": as_number(games.get("appearences")),
        "minutes": as_number(games.get("minutes")),
        "rating": as_number(games.get("rating")),
        "goals": as_number(goals.get("total")),
        "assists": as_number(goals.get("assists")),
        "shots": as_number(shots.get("total")),
        "shots_on": as_number(shots.get("on")),
        "passes": as_number(passes.get("total")),
        "key_passes": as_number(passes.get("key")),
        "pass_accuracy": as_number(passes.get("accuracy")),
        "tackles": as_number(tackles.get("total")),
        "interceptions": as_number(tackles.get("interceptions")),
        "blocks": as_number(tackles.get("blocks")),
        "duels_won": as_number(duels.get("won")),
        "dribbles_success": as_number(dribbles.get("success")),
    }


def decorate_player(player: dict | None) -> dict:
    data = dict(player or {})
    block = primary_statistics(data)
    data["primary"] = block
    data["metrics"] = extract_metrics(block)
    return data


def comparison_rows(left_metrics: dict, right_metrics: dict) -> list[dict]:
    rows = []
    for key, label in METRIC_FIELDS:
        left = left_metrics.get(key)
        right = right_metrics.get(key)
        winner = None
        if left is not None and right is not None:
            if left > right:
                winner = "left"
            elif right > left:
                winner = "right"
            else:
                winner = "tie"
        rows.append(
            {
                "key": key,
                "label": label,
                "left": left,
                "right": right,
                "winner": winner,
            }
        )
    return rows
