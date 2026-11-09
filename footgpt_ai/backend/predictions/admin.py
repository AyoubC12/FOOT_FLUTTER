from django.contrib import admin

from .models import HistoricalMatch, ModelEvaluation, Prediction


@admin.register(Prediction)
class PredictionAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "home_team",
        "away_team",
        "predicted_result",
        "data_quality",
        "created_at",
    )
    list_filter = ("predicted_result", "data_quality")
    search_fields = ("home_team", "away_team", "user__email")


@admin.register(HistoricalMatch)
class HistoricalMatchAdmin(admin.ModelAdmin):
    list_display = (
        "kickoff_at",
        "home_team_name",
        "home_goals",
        "away_goals",
        "away_team_name",
        "league_id",
        "season",
    )
    search_fields = ("home_team_name", "away_team_name", "external_id")


@admin.register(ModelEvaluation)
class ModelEvaluationAdmin(admin.ModelAdmin):
    list_display = (
        "trained_at",
        "model_name",
        "n_train",
        "n_test",
        "log_loss",
        "brier_score",
        "accuracy",
    )
