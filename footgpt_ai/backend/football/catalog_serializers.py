from rest_framework import serializers

from football.models import (
    Competition,
    CompetitionSeason,
    Player,
    PlayerSeasonStatistics,
    PlayerTransfer,
    Team,
    TeamSeasonStatistics,
)
from integrations.api_football.seasons import is_season_complete, is_season_current, season_label


def media_url(request, file_field, fallback: str) -> str | None:
    if file_field:
        url = file_field.url
        if request:
            return request.build_absolute_uri(url)
        return url
    return fallback or None


class CompetitionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Competition
        fields = ("id", "external_id", "name", "country", "type", "logo_url", "is_enabled")


class CompetitionSeasonSerializer(serializers.ModelSerializer):
    label = serializers.SerializerMethodField()
    is_complete = serializers.SerializerMethodField()
    availability = serializers.SerializerMethodField()

    class Meta:
        model = CompetitionSeason
        fields = (
            "year",
            "label",
            "is_current",
            "is_complete",
            "coverage_fixtures",
            "coverage_standings",
            "coverage_players",
            "coverage_statistics",
            "synced_at",
            "availability",
        )

    def get_label(self, obj):
        return season_label(obj.year)

    def get_is_complete(self, obj):
        if obj.is_current or is_season_current(obj.year):
            return False
        return is_season_complete(obj.year)

    def get_availability(self, obj):
        if obj.synced_at is None and obj.coverage_standings is None:
            return "not_synced"
        return "provider"


class CatalogTeamSerializer(serializers.ModelSerializer):
    id = serializers.SerializerMethodField()
    code = serializers.CharField(source="short_name")
    logo = serializers.SerializerMethodField()
    venue = serializers.SerializerMethodField()

    class Meta:
        model = Team
        fields = (
            "id",
            "name",
            "code",
            "country",
            "city",
            "founded",
            "website",
            "coach_name",
            "national",
            "logo",
            "venue",
        )

    def get_id(self, obj):
        try:
            return int(obj.external_id)
        except (TypeError, ValueError):
            return None

    def get_logo(self, obj):
        return media_url(self.context.get("request"), obj.logo_file, obj.logo_url)

    def get_venue(self, obj):
        if not obj.stadium_name and not obj.city and obj.stadium_capacity is None:
            return None
        return {
            "name": obj.stadium_name or None,
            "city": obj.city or None,
            "capacity": obj.stadium_capacity,
        }


class TeamSeasonStatisticsSerializer(serializers.ModelSerializer):
    label = serializers.SerializerMethodField()
    is_complete = serializers.SerializerMethodField()
    competition_name = serializers.CharField(source="competition.name", read_only=True)
    missing_fields = serializers.SerializerMethodField()

    class Meta:
        model = TeamSeasonStatistics
        fields = (
            "year",
            "label",
            "is_complete",
            "competition_name",
            "played",
            "wins",
            "draws",
            "losses",
            "goals_for",
            "goals_against",
            "goal_diff",
            "points",
            "rank",
            "clean_sheets",
            "possession_avg",
            "shots_per_game",
            "shots_on_target",
            "yellow_cards",
            "red_cards",
            "home_played",
            "home_wins",
            "home_draws",
            "home_losses",
            "away_played",
            "away_wins",
            "away_draws",
            "away_losses",
            "form",
            "missing_fields",
        )

    def get_label(self, obj):
        return season_label(obj.year)

    def get_is_complete(self, obj):
        return is_season_complete(obj.year) and not is_season_current(obj.year)

    def get_missing_fields(self, obj):
        tracked = [
            "played",
            "wins",
            "draws",
            "losses",
            "goals_for",
            "goals_against",
            "points",
            "rank",
            "clean_sheets",
            "possession_avg",
            "shots_per_game",
            "shots_on_target",
            "yellow_cards",
            "red_cards",
        ]
        return [name for name in tracked if getattr(obj, name) is None]


class CatalogPlayerSerializer(serializers.ModelSerializer):
    id = serializers.SerializerMethodField()
    photo = serializers.SerializerMethodField()
    team = serializers.SerializerMethodField()
    firstname = serializers.CharField(source="first_name")
    lastname = serializers.CharField(source="last_name")
    number = serializers.IntegerField(source="shirt_number", allow_null=True)
    height = serializers.SerializerMethodField()
    weight = serializers.SerializerMethodField()
    birth = serializers.SerializerMethodField()

    class Meta:
        model = Player
        fields = (
            "id",
            "name",
            "firstname",
            "lastname",
            "nationality",
            "position",
            "number",
            "preferred_foot",
            "photo",
            "team",
            "height",
            "weight",
            "birth",
        )

    def get_id(self, obj):
        try:
            return int(obj.external_id)
        except (TypeError, ValueError):
            return None

    def get_photo(self, obj):
        return media_url(self.context.get("request"), obj.photo_file, obj.photo_url)

    def get_team(self, obj):
        if not obj.team:
            return None
        return CatalogTeamSerializer(obj.team, context=self.context).data

    def get_height(self, obj):
        return f"{obj.height_cm} cm" if obj.height_cm else None

    def get_weight(self, obj):
        return f"{obj.weight_kg} kg" if obj.weight_kg else None

    def get_birth(self, obj):
        return {"date": obj.birth_date.isoformat() if obj.birth_date else None}


class PlayerSeasonStatisticsSerializer(serializers.ModelSerializer):
    label = serializers.SerializerMethodField()
    team_name = serializers.CharField(source="team.name", read_only=True)
    competition_name = serializers.CharField(source="competition.name", read_only=True)
    missing_fields = serializers.SerializerMethodField()

    class Meta:
        model = PlayerSeasonStatistics
        fields = (
            "year",
            "label",
            "team_name",
            "competition_name",
            "appearances",
            "lineups",
            "minutes",
            "goals",
            "assists",
            "yellow_cards",
            "red_cards",
            "shots",
            "shots_on",
            "passes",
            "passes_accurate",
            "pass_accuracy",
            "dribbles",
            "duels_won",
            "clean_sheets",
            "saves",
            "goals_conceded",
            "rating",
            "missing_fields",
        )

    def get_label(self, obj):
        return season_label(obj.year)

    def get_missing_fields(self, obj):
        tracked = [
            "appearances",
            "lineups",
            "minutes",
            "goals",
            "assists",
            "rating",
            "shots",
            "passes",
        ]
        return [name for name in tracked if getattr(obj, name) is None]


class PlayerTransferSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayerTransfer
        fields = (
            "date",
            "transfer_type",
            "team_in_external_id",
            "team_in_name",
            "team_out_external_id",
            "team_out_name",
        )
