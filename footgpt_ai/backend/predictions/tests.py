from datetime import datetime, timedelta, timezone
from itertools import combinations
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from predictions.engine.features import (
    build_features_for_match,
    build_training_frame,
    chronological_split,
)
from predictions.engine.predict import PredictionEngine
from predictions.engine.probabilities import to_percentages
from predictions.engine.records import MatchRecord
from predictions.engine.train import train_and_evaluate
from predictions.models import HistoricalMatch, Prediction

User = get_user_model()


def _kickoff(day: int) -> datetime:
    return datetime(2023, 8, 1, tzinfo=timezone.utc) + timedelta(days=day)


def make_test_history() -> list[MatchRecord]:
    """Deterministic finished matches for pipeline tests — not live football data."""
    teams = [(i, f"Club {i}") for i in range(1, 9)]
    matches = []
    match_id = 1
    day = 0
    for home, away in list(combinations(teams, 2)) + [
        (away, home) for home, away in combinations(teams, 2)
    ]:
        home_goals = (home[0] + day) % 4
        away_goals = (away[0] * 2 + day) % 3
        matches.append(
            MatchRecord(
                match_id=str(match_id),
                kickoff_at=_kickoff(day),
                home_id=home[0],
                away_id=away[0],
                home_name=home[1],
                away_name=away[1],
                home_goals=home_goals,
                away_goals=away_goals,
                league_id=39,
                season=2023,
            )
        )
        match_id += 1
        day += 1
    return matches


class FeaturePipelineTests(APITestCase):
    def test_features_ignore_current_and_future_matches(self):
        history = make_test_history()
        target = history[20]
        features = build_features_for_match(
            history,
            home_id=target.home_id,
            away_id=target.away_id,
            kickoff_at=target.kickoff_at,
        )
        self.assertGreaterEqual(features["home_prior_matches"], 0)
        future_or_current = [
            match
            for match in history
            if match.kickoff_at >= target.kickoff_at
            and target.home_id in {match.home_id, match.away_id}
        ]
        self.assertTrue(future_or_current)
        self.assertEqual(
            features["home_prior_matches"],
            len(
                [
                    match
                    for match in history
                    if match.kickoff_at < target.kickoff_at
                    and target.home_id in {match.home_id, match.away_id}
                ]
            ),
        )

    def test_chronological_split_has_no_overlap(self):
        frame = build_training_frame(make_test_history())
        train, test = chronological_split(frame)
        self.assertLess(train["kickoff_at"].max(), test["kickoff_at"].min())

    def test_percentages_sum_to_100(self):
        percents = to_percentages([0.401, 0.299, 0.3])
        self.assertEqual(round(sum(percents.values()), 2), 100.0)


class TrainingAndEstimateTests(APITestCase):
    def test_train_compares_models_and_predicts(self):
        history = make_test_history()
        with TemporaryDirectory() as tmp:
            path = Path(tmp) / "model.joblib"
            bundle = train_and_evaluate(history, artifact_path=path)
            self.assertIn("dummy_prior", bundle["comparison"])
            self.assertIn("logistic_baseline", bundle["comparison"])
            self.assertIn("random_forest", bundle["comparison"])
            self.assertIn("log_loss", bundle["metrics"])
            self.assertIn("brier_score", bundle["metrics"])
            self.assertIn("ece", bundle["metrics"])
            self.assertTrue(path.exists())

            engine = PredictionEngine(artifact_path=path)
            last = history[-1]
            result = engine.estimate(
                home_id=last.home_id,
                away_id=last.away_id,
                kickoff_at=last.kickoff_at + timedelta(days=7),
                refresh_from_api=False,
                player_ratings=False,
                history=history,
            )
            self.assertEqual(round(sum(result.percentages.values()), 2), 100.0)
            self.assertIn("not a guaranteed outcome", result.explanation.lower())
            self.assertEqual(result.data_quality, "sufficient")

    def test_insufficient_history_is_flagged(self):
        tiny = make_test_history()[:4]
        engine = PredictionEngine(artifact_path=Path("missing.joblib"))
        result = engine.estimate(
            home_id=1,
            away_id=2,
            kickoff_at=_kickoff(3),
            refresh_from_api=False,
            player_ratings=False,
        )
        self.assertEqual(result.data_quality, "insufficient")
        self.assertEqual(round(sum(result.percentages.values()), 2), 100.0)
        self.assertIn("Insufficient", result.explanation)
        self.assertEqual(len(tiny), 4)


class PredictionApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="analyst",
            email="analyst@example.com",
            password="StrongPass123",
        )
        self.client.force_authenticate(self.user)

    def test_create_and_list_prediction(self):
        create = self.client.post(
            reverse("prediction-list"),
            {
                "home_team": "Arsenal",
                "away_team": "Liverpool",
                "predicted_result": "home",
                "probabilities": {"home": 42, "draw": 28, "away": 30},
                "explanation": "Preview sample.",
            },
            format="json",
        )
        self.assertEqual(create.status_code, status.HTTP_201_CREATED)
        listing = self.client.get(reverse("prediction-list"))
        self.assertEqual(listing.status_code, status.HTTP_200_OK)
        self.assertEqual(listing.data["count"], 1)

    @patch("predictions.engine.history.mean_team_player_rating", return_value=None)
    @patch("predictions.engine.history.pull_h2h", return_value=[])
    @patch("predictions.engine.history.pull_team_history", return_value=[])
    def test_estimate_endpoint_stores_prediction(self, *_mocks):
        for record in make_test_history():
            HistoricalMatch.objects.create(
                external_id=record.match_id,
                league_id=record.league_id,
                season=record.season,
                kickoff_at=record.kickoff_at,
                home_team_id=record.home_id,
                away_team_id=record.away_id,
                home_team_name=record.home_name,
                away_team_name=record.away_name,
                home_goals=record.home_goals,
                away_goals=record.away_goals,
            )
        with TemporaryDirectory() as tmp:
            path = Path(tmp) / "model.joblib"
            with override_settings(PREDICTION_MODEL_PATH=path):
                PredictionEngine(artifact_path=path).fit_from_history(
                    [
                        MatchRecord(
                            match_id=row.external_id,
                            kickoff_at=row.kickoff_at,
                            home_id=row.home_team_id,
                            away_id=row.away_team_id,
                            home_name=row.home_team_name,
                            away_name=row.away_team_name,
                            home_goals=row.home_goals,
                            away_goals=row.away_goals,
                            league_id=row.league_id,
                            season=row.season,
                        )
                        for row in HistoricalMatch.objects.all()
                    ]
                )
                response = self.client.post(
                    reverse("prediction-estimate"),
                    {
                        "home_team_id": 1,
                        "away_team_id": 2,
                        "home_team": "Club 1",
                        "away_team": "Club 2",
                        "kickoff_at": (_kickoff(80)).isoformat(),
                    },
                    format="json",
                )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(
            round(sum(response.data["probabilities"].values()), 2),
            100.0,
        )
        self.assertTrue(Prediction.objects.filter(user=self.user).exists())
        self.assertIn("disclaimer", response.data)
