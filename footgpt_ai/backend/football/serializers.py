from rest_framework import serializers

from .models import Match, Player, SavedPlayerComparison, Team


class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = (
            "id",
            "external_id",
            "name",
            "short_name",
            "country",
            "created_at",
        )
        read_only_fields = fields


class PlayerSerializer(serializers.ModelSerializer):
    team_name = serializers.CharField(source="team.name", read_only=True)

    class Meta:
        model = Player
        fields = (
            "id",
            "external_id",
            "name",
            "position",
            "nationality",
            "team",
            "team_name",
            "created_at",
        )
        read_only_fields = fields


class MatchSerializer(serializers.ModelSerializer):
    home_team = TeamSerializer(read_only=True)
    away_team = TeamSerializer(read_only=True)

    class Meta:
        model = Match
        fields = (
            "id",
            "external_id",
            "league_name",
            "home_team",
            "away_team",
            "kickoff_at",
            "status",
            "home_score",
            "away_score",
            "venue",
            "created_at",
        )
        read_only_fields = fields


class SavedPlayerComparisonSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedPlayerComparison
        fields = (
            "id",
            "season",
            "left_player_id",
            "right_player_id",
            "left_name",
            "right_name",
            "left_photo",
            "right_photo",
            "snapshot",
            "created_at",
        )
        read_only_fields = (
            "id",
            "left_name",
            "right_name",
            "left_photo",
            "right_photo",
            "snapshot",
            "created_at",
        )

    def validate(self, attrs):
        if attrs.get("left_player_id") == attrs.get("right_player_id"):
            raise serializers.ValidationError("Select two different players.")
        return attrs
