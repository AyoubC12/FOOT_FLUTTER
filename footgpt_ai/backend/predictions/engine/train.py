from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.dummy import DummyClassifier
from sklearn.ensemble import HistGradientBoostingClassifier, RandomForestClassifier
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

from .features import FEATURE_COLUMNS, build_training_frame, chronological_split
from .metrics import evaluate_proba
from .records import MatchRecord

LABEL_ORDER = ["home", "draw", "away"]


def _align_proba(estimator, proba: np.ndarray) -> np.ndarray:
    class_index = {cls: i for i, cls in enumerate(estimator.classes_)}
    columns = []
    for label in LABEL_ORDER:
        if label in class_index:
            columns.append(proba[:, class_index[label]])
        else:
            columns.append(np.zeros(len(proba)))
    ordered = np.column_stack(columns)
    totals = ordered.sum(axis=1, keepdims=True)
    totals[totals == 0] = 1.0
    return ordered / totals


def _pipelines() -> dict:
    return {
        "dummy_prior": DummyClassifier(strategy="prior"),
        "logistic_baseline": Pipeline(
            [
                ("imputer", SimpleImputer(strategy="constant", fill_value=0)),
                ("scaler", StandardScaler()),
                (
                    "model",
                    LogisticRegression(
                        max_iter=500,
                        class_weight="balanced",
                        solver="lbfgs",
                    ),
                ),
            ]
        ),
        "hist_gradient_boosting": HistGradientBoostingClassifier(
            max_depth=3,
            learning_rate=0.08,
            max_iter=150,
            l2_regularization=0.1,
            min_samples_leaf=10,
        ),
        "random_forest": Pipeline(
            [
                ("imputer", SimpleImputer(strategy="constant", fill_value=0)),
                (
                    "model",
                    RandomForestClassifier(
                        n_estimators=120,
                        min_samples_leaf=3,
                        class_weight="balanced",
                        random_state=42,
                    ),
                ),
            ]
        ),
    }


def train_and_evaluate(matches: list[MatchRecord], artifact_path: str | Path | None = None) -> dict:
    frame = build_training_frame(matches)
    if len(frame) < 20:
        raise ValueError(
            "Insufficient labelled history to train (need at least 20 matches "
            "where both teams already have 5 prior results)."
        )
    train, test = chronological_split(frame)
    if train.empty or test.empty:
        raise ValueError("Chronological split produced an empty train or test set.")
    if test["kickoff_at"].min() < train["kickoff_at"].max():
        raise ValueError("Data leakage: test kickoffs overlap the training window.")

    y_train = train["label"].to_numpy()
    y_test = test["label"].to_numpy()
    x_train = train[FEATURE_COLUMNS].apply(pd.to_numeric, errors="coerce").fillna(0)
    x_test = test[FEATURE_COLUMNS].apply(pd.to_numeric, errors="coerce").fillna(0)
    varying = [col for col in FEATURE_COLUMNS if x_train[col].nunique(dropna=False) > 1]
    if varying:
        x_train = x_train[varying]
        x_test = x_test[varying]
    else:
        varying = FEATURE_COLUMNS
    y_test_codes = np.array([LABEL_ORDER.index(label) for label in y_test])

    comparison = {}
    best_name = None
    best_model = None
    best_loss = float("inf")
    best_metrics = {}

    for name, estimator in _pipelines().items():
        try:
            estimator.fit(x_train, y_train)
            proba = _align_proba(estimator, estimator.predict_proba(x_test))
        except ValueError:
            comparison[name] = {"error": "model failed to fit on this sample"}
            continue
        metrics = {key: float(value) for key, value in evaluate_proba(y_test_codes, proba).items()}
        comparison[name] = metrics
        if metrics["log_loss"] < best_loss:
            best_loss = metrics["log_loss"]
            best_name = name
            best_model = estimator
            best_metrics = metrics

    if best_model is None:
        raise ValueError("No classification model fitted successfully.")

    bundle = {
        "model": best_model,
        "model_name": best_name,
        "feature_columns": varying,
        "label_order": LABEL_ORDER,
        "metrics": best_metrics,
        "comparison": comparison,
        "n_train": int(len(train)),
        "n_test": int(len(test)),
        "trained_at": datetime.now(timezone.utc).isoformat(),
    }
    if artifact_path:
        path = Path(artifact_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(bundle, path)
        bundle["artifact_path"] = str(path)
    return bundle
