from __future__ import annotations

from assistant.services.football_tools import FORMATION_NOTES

ALLOWED_FORMATIONS = ("4-3-3", "4-4-2", "3-5-2", "4-2-3-1")


def _band(y: float) -> str:
    if y >= 0.80:
        return "goalkeeper"
    if y >= 0.62:
        return "defence"
    if y >= 0.38:
        return "midfield"
    return "attack"


def summarize_board(formation: str, players: list[dict]) -> dict:
    bands: dict[str, int] = {
        "goalkeeper": 0,
        "defence": 0,
        "midfield": 0,
        "attack": 0,
    }
    xs: list[float] = []
    ys: list[float] = []
    slots = []
    for item in players:
        x = float(item.get("x") or 0)
        y = float(item.get("y") or 0)
        band = _band(y)
        bands[band] += 1
        xs.append(x)
        ys.append(y)
        slots.append(
            {
                "name": item.get("name") or "Unnamed",
                "position": item.get("position") or band,
                "x": round(x, 3),
                "y": round(y, 3),
                "band": band,
            }
        )
    width = round(max(xs) - min(xs), 3) if xs else 0
    depth = round(max(ys) - min(ys), 3) if ys else 0
    note = FORMATION_NOTES.get(formation)
    return {
        "formation": formation,
        "player_count": len(players),
        "bands": bands,
        "width": width,
        "depth": depth,
        "slots": slots,
        "formation_note": note,
        "note_available": bool(note),
    }


def structural_suggestions(summary: dict, compare: dict | None = None) -> list[str]:
    tips: list[str] = []
    bands = summary["bands"]
    if summary["player_count"] < 11:
        tips.append(
            f"This board has {summary['player_count']} players. "
            "A full side is 11; the notes below describe a complete shape."
        )
    if bands["goalkeeper"] == 0:
        tips.append("No player is placed in the goalkeeper band (bottom of the pitch).")
    if bands["defence"] <= 2 and summary["player_count"] >= 8:
        tips.append("The defensive line is light. Rest defence may be exposed on turnovers.")
    if bands["attack"] == 0 and summary["player_count"] >= 8:
        tips.append("Nobody occupies the attacking third. The press and the 9's reference are missing.")
    if summary["width"] < 0.45 and summary["player_count"] >= 8:
        tips.append("The block is narrow. Wide overloads and switches may be hard to play.")
    if summary["width"] > 0.82:
        tips.append("The block is very wide. Distances between full-backs and centre-backs can grow.")
    note = summary.get("formation_note")
    if note:
        tips.append(note)
    else:
        tips.append(
            "No verified formation note exists for this shape. "
            "Ask about 4-3-3, 4-4-2, 3-5-2 or 4-2-3-1."
        )
    if compare:
        tips.extend(_compare_lines(summary, compare))
    return tips


def _compare_lines(left: dict, right: dict) -> list[str]:
    tips = [
        f"Left is a {left['formation']} with {left['player_count']} players; "
        f"right is a {right['formation']} with {right['player_count']}."
    ]
    lb, rb = left["bands"], right["bands"]
    if rb["defence"] > lb["defence"]:
        tips.append("The right board holds more players in the defensive band.")
    elif lb["defence"] > rb["defence"]:
        tips.append("The left board holds more players in the defensive band.")
    if rb["attack"] > lb["attack"]:
        tips.append("The right board occupies the attacking third with more bodies.")
    elif lb["attack"] > rb["attack"]:
        tips.append("The left board occupies the attacking third with more bodies.")
    if abs(left["width"] - right["width"]) >= 0.12:
        wider = "left" if left["width"] > right["width"] else "right"
        tips.append(f"The {wider} board is structurally wider on this pitch.")
    return tips
