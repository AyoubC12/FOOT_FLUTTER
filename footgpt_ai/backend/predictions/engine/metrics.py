from __future__ import annotations

import numpy as np
from sklearn.metrics import accuracy_score, log_loss

from .probabilities import LABELS


def multiclass_brier(y_true: np.ndarray, proba: np.ndarray) -> float:
    one_hot = np.zeros_like(proba)
    one_hot[np.arange(len(y_true)), y_true] = 1.0
    return float(np.mean(np.sum((proba - one_hot) ** 2, axis=1)))


def expected_calibration_error(
    y_true: np.ndarray, proba: np.ndarray, n_bins: int = 10
) -> float:
    """Mean ECE across the three 1X2 classes."""
    scores = []
    bins = np.linspace(0.0, 1.0, n_bins + 1)
    for class_index in range(proba.shape[1]):
        p = proba[:, class_index]
        y = (y_true == class_index).astype(float)
        ece = 0.0
        for i in range(n_bins):
            mask = (p >= bins[i]) & (p < bins[i + 1] if i < n_bins - 1 else p <= bins[i + 1])
            if not np.any(mask):
                continue
            ece += abs(p[mask].mean() - y[mask].mean()) * mask.mean()
        scores.append(ece)
    return float(np.mean(scores))


def evaluate_proba(y_true: np.ndarray, proba: np.ndarray) -> dict[str, float]:
    labels = list(range(len(LABELS)))
    return {
        "log_loss": float(log_loss(y_true, proba, labels=labels)),
        "brier_score": multiclass_brier(y_true, proba),
        "accuracy": float(accuracy_score(y_true, proba.argmax(axis=1))),
        "ece": expected_calibration_error(y_true, proba),
    }
