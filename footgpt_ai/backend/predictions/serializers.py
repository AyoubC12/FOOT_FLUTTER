from rest_framework import serializers

from .models import Prediction

REQUIRED_PROB_KEYS = ("home", "draw", "away")


class PredictionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Prediction
        fields = (
            "id",
            "home_team",
            "away_team",
            "home_team_id",
            "away_team_id",
            "fixture_id",
            "league_id",
            "season",
            "predicted_result",
            "probabilities",
            "explanation",
            "data_quality",
            "model_name",
            "created_at",
        )
        read_only_fields = (
            "id",
            "created_at",
            "data_quality",
            "model_name",
        )

    def validate_home_team(self, value: str) -> str:
        return _required_name(value, "Home team")

    def validate_away_team(self, value: str) -> str:
        return _required_name(value, "Away team")

    def validate_probabilities(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("Probabilities must be an object.")
        missing = [key for key in REQUIRED_PROB_KEYS if key not in value]
        if missing:
            raise serializers.ValidationError(
                f"Missing probability keys: {', '.join(missing)}."
            )
        numbers = {}
        for key in REQUIRED_PROB_KEYS:
            try:
                numbers[key] = float(value[key])
            except (TypeError, ValueError) as exc:
                raise serializers.ValidationError(
                    f"Probability '{key}' must be a number."
                ) from exc
            if numbers[key] < 0:
                raise serializers.ValidationError("Probabilities cannot be negative.")
        total = sum(numbers.values())
        if total <= 1.5:
            numbers = {key: val * 100 for key, val in numbers.items()}
            total = sum(numbers.values())
        if abs(total - 100) > 1.5:
            raise serializers.ValidationError("Probabilities must sum to 100.")
        return {key: round(numbers[key], 2) for key in REQUIRED_PROB_KEYS}

    def validate(self, attrs):
        if attrs.get("home_team") and attrs.get("away_team"):
            if attrs["home_team"].lower() == attrs["away_team"].lower():
                raise serializers.ValidationError(
                    "Home and away teams must be different."
                )
        return attrs

    def create(self, validated_data):
        return Prediction.objects.create(
            user=self.context["request"].user,
            **validated_data,
        )


def _required_name(value: str, label: str) -> str:
    name = value.strip()
    if not name:
        raise serializers.ValidationError(f"{label} is required.")
    return name


class EstimateRequestSerializer(serializers.Serializer):
    home_team_id = serializers.IntegerField(min_value=1)
    away_team_id = serializers.IntegerField(min_value=1)
    home_team = serializers.CharField(required=False, allow_blank=True, max_length=128)
    away_team = serializers.CharField(required=False, allow_blank=True, max_length=128)
    league_id = serializers.IntegerField(required=False, min_value=1)
    season = serializers.IntegerField(required=False, min_value=2000, max_value=2100)
    fixture_id = serializers.IntegerField(required=False, min_value=1)
    kickoff_at = serializers.DateTimeField(required=False)

    def validate(self, attrs):
        if attrs["home_team_id"] == attrs["away_team_id"]:
            raise serializers.ValidationError("Home and away teams must be different.")
        return attrs
