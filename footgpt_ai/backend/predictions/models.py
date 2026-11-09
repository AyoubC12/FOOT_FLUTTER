from django.conf import settings
from django.db import models


class HistoricalMatch(models.Model):
    """Finished matches used as training/inference history. Scores come from the provider or ingest, never invented."""

    class Status(models.TextChoices):
        FULL_TIME = "FT", "Full time"
        AFTER_ET = "AET", "After extra time"
        PENALTIES = "PEN", "Penalties"

    external_id = models.CharField(max_length=64, unique=True)
    league_id = models.IntegerField(null=True, blank=True)
    season = models.IntegerField(null=True, blank=True)
    kickoff_at = models.DateTimeField(db_index=True)
    home_team_id = models.IntegerField(db_index=True)
    away_team_id = models.IntegerField(db_index=True)
    home_team_name = models.CharField(max_length=128)
    away_team_name = models.CharField(max_length=128)
    home_goals = models.PositiveSmallIntegerField()
    away_goals = models.PositiveSmallIntegerField()
    status = models.CharField(max_length=8, choices=Status.choices, default=Status.FULL_TIME)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["kickoff_at"]
        indexes = [
            models.Index(fields=["home_team_id", "kickoff_at"]),
            models.Index(fields=["away_team_id", "kickoff_at"]),
        ]

    def __str__(self) -> str:
        return f"{self.home_team_name} {self.home_goals}-{self.away_goals} {self.away_team_name}"


class ModelEvaluation(models.Model):
    trained_at = models.DateTimeField(auto_now_add=True)
    model_name = models.CharField(max_length=64)
    n_train = models.PositiveIntegerField()
    n_test = models.PositiveIntegerField()
    log_loss = models.FloatField()
    brier_score = models.FloatField()
    accuracy = models.FloatField()
    ece = models.FloatField(null=True, blank=True)
    comparison = models.JSONField(default=dict)
    artifact_path = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["-trained_at"]


class Prediction(models.Model):
    class Result(models.TextChoices):
        HOME = "home", "Home win"
        DRAW = "draw", "Draw"
        AWAY = "away", "Away win"

    class DataQuality(models.TextChoices):
        SUFFICIENT = "sufficient", "Sufficient"
        INSUFFICIENT = "insufficient", "Insufficient"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="predictions",
    )
    home_team = models.CharField(max_length=128)
    away_team = models.CharField(max_length=128)
    home_team_id = models.IntegerField(null=True, blank=True)
    away_team_id = models.IntegerField(null=True, blank=True)
    fixture_id = models.IntegerField(null=True, blank=True)
    league_id = models.IntegerField(null=True, blank=True)
    season = models.IntegerField(null=True, blank=True)
    predicted_result = models.CharField(max_length=8, choices=Result.choices)
    probabilities = models.JSONField(default=dict)
    explanation = models.TextField(blank=True)
    data_quality = models.CharField(
        max_length=16,
        choices=DataQuality.choices,
        default=DataQuality.SUFFICIENT,
    )
    model_name = models.CharField(max_length=64, blank=True)
    feature_snapshot = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.home_team} vs {self.away_team}"
