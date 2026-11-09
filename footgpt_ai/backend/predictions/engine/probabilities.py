from __future__ import annotations

import numpy as np

LABELS = ("home", "draw", "away")


def to_percentages(proba) -> dict[str, float]:
    values = np.asarray(proba, dtype=float).reshape(-1)
    if values.size != 3:
        raise ValueError("Expected three class probabilities.")
    values = np.clip(values, 1e-12, None)
    values = values / values.sum()
    percents = np.round(values * 100, 2)
    percents[2] = round(100.0 - float(percents[0] + percents[1]), 2)
    return {label: float(percents[i]) for i, label in enumerate(LABELS)}


def predicted_label(percentages: dict[str, float]) -> str:
    return max(percentages, key=percentages.get)
