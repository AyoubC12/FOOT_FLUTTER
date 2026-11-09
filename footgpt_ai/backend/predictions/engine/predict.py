from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from django.conf import settings

from .explain import explain_prediction
from .features import FEATURE_COLUMNS, build_features_for_match, sufficient_history
from .history import gather_match_history, load_history_from_db, mean_team_player_rating
from .probabilities import predicted_label, to_percentages
from .records import DISCLAIMER, MatchRecord
from .train import LABEL_ORDER, train_and_evaluate


@dataclass
class EngineResult:
    percentages: dict[str, float]
    predicted_result: str
    explanation: str
    data_quality: str
    model_name: str
    features: dict
    metrics: dict


class PredictionEngine:
    def __init__(self, artifact_path: str | Path | None = None):
        self.artifact_path = Path(
            artifact_path
            or getattr(
                settings,
                "PREDICTION_MODEL_PATH",
                Path(settings.BASE_DIR) / "predictions" / "artifacts" / "predictor.joblib",
            )
        )
        self._bundle: dict | None = None

    def load_bundle(self) -> dict | None:
        if self._bundle is not None:
            return self._bundle
        if self.artifact_path.exists():
            self._bundle = joblib.load(self.artifact_path)
            return self._bundle
        return None

    def fit_from_history(self, matches: list[MatchRecord] | None = None) -> dict:
        history = matches if matches is not None else load_history_from_db()
        bundle = train_and_evaluate(history, artifact_path=self.artifact_path)
        self._bundle = bundle
        return bundle

    def estimate(
        self,
        *,
        home_id: int,
        away_id: int,
        kickoff_at: datetime | None = None,
        league_id: int | None = None,
        season: int | None = None,
        refresh_from_api: bool = True,
        player_ratings: bool = True,
        history: list[MatchRecord] | None = None,
    ) -> EngineResult:
        when = kickoff_at or datetime.now(timezone.utc)
        if history is None:
            history = gather_match_history(
                home_id, away_id, refresh_from_api=refresh_from_api
            )
        missing = []
        home_rating = away_rating = None
        if player_ratings and season:
            home_rating = mean_team_player_rating(home_id, season)
            away_rating = mean_team_player_rating(away_id, season)
            if home_rating is None or away_rating is None:
                missing.append(
                    "Available player performance statistics were incomplete and left missing."
                )

        features = build_features_for_match(
            history,
            home_id=home_id,
            away_id=away_id,
            kickoff_at=when,
            home_player_rating=home_rating,
            away_player_rating=away_rating,
        )
        sufficient = sufficient_history(features)
        bundle = self.load_bundle()
        model_name = "uninformative_prior"
        metrics = {}

        if bundle and sufficient:
            model = bundle["model"]
            columns = bundle.get("feature_columns", FEATURE_COLUMNS)
            row = pd.DataFrame(
                [
                    {
                        col: (
                            0.0
                            if features.get(col) is None
                            or features.get(col) != features.get(col)
                            else float(features.get(col))
                        )
                        for col in columns
                    }
                ]
            )
            proba = model.predict_proba(row)[0]
            class_index = {cls: i for i, cls in enumerate(model.classes_)}
            ordered = [
                proba[class_index[label]] if label in class_index else 1 / 3
                for label in LABEL_ORDER
            ]
            percentages = to_percentages(ordered)
            model_name = bundle.get("model_name") or model.__class__.__name__
            metrics = bundle.get("metrics") or {}
        else:
            percentages = self._prior_percentages(history)
            if bundle:
                model_name = f"prior_fallback({bundle.get('model_name')})"
                metrics = bundle.get("metrics") or {}

        quality = "sufficient" if sufficient and bundle else "insufficient"
        explanation = explain_prediction(
            features=features,
            percentages=percentages,
            model_name=model_name,
            sufficient=sufficient and bundle is not None,
            missing_notes=missing,
        )
        return EngineResult(
            percentages=percentages,
            predicted_result=predicted_label(percentages),
            explanation=explanation,
            data_quality=quality,
            model_name=model_name,
            features={key: _json_safe(features[key]) for key in FEATURE_COLUMNS},
            metrics=metrics,
        )

    def _prior_percentages(self, history: list[MatchRecord]) -> dict[str, float]:
        if not history:
            return to_percentages([1 / 3, 1 / 3, 1 / 3])
        counts = {"home": 0, "draw": 0, "away": 0}
        for match in history:
            counts[match.result] += 1
        total = sum(counts.values())
        return to_percentages(
            [counts["home"] / total, counts["draw"] / total, counts["away"] / total]
        )


def _json_safe(value):
    if value is None:
        return None
    try:
        if value != value:  # NaN
            return None
    except TypeError:
        return value
    if hasattr(value, "item"):
        return value.item()
    return float(value) if isinstance(value, (np.floating, np.integer)) else value
