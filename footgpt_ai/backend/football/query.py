from rest_framework import serializers


class PageQuerySerializer(serializers.Serializer):
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(
        required=False, min_value=1, max_value=50, default=20
    )


class FixtureQuerySerializer(PageQuerySerializer):
    id = serializers.IntegerField(required=False, min_value=1)
    live = serializers.CharField(required=False, max_length=64)
    date = serializers.DateField(required=False)
    league = serializers.IntegerField(required=False, min_value=1)
    season = serializers.IntegerField(required=False, min_value=2000, max_value=2100)
    team = serializers.IntegerField(required=False, min_value=1)
    last = serializers.IntegerField(required=False, min_value=1, max_value=50)
    next = serializers.IntegerField(required=False, min_value=1, max_value=50)
    status = serializers.CharField(required=False, max_length=8)
    timezone = serializers.CharField(required=False, max_length=64, default="UTC")
    from_date = serializers.DateField(required=False)
    to_date = serializers.DateField(required=False)

    def validate(self, attrs):
        if attrs.get("league") and not attrs.get("season"):
            raise serializers.ValidationError(
                {"season": "season is required when filtering by league."}
            )
        has_scope = any(
            attrs.get(key)
            for key in ("id", "live", "date", "league", "team", "last", "next", "from_date")
        )
        if not has_scope:
            raise serializers.ValidationError(
                "Provide at least one filter: date, league+season, team, live, next, last, or id."
            )
        return attrs


class LiveQuerySerializer(PageQuerySerializer):
    live = serializers.CharField(required=False, max_length=64, default="all")


class TeamQuerySerializer(PageQuerySerializer):
    id = serializers.IntegerField(required=False, min_value=1)
    league = serializers.IntegerField(required=False, min_value=1)
    season = serializers.IntegerField(required=False, min_value=2000, max_value=2100)
    search = serializers.CharField(required=False, max_length=64)
    country = serializers.CharField(required=False, max_length=64)

    def validate(self, attrs):
        if attrs.get("league") and not attrs.get("season"):
            raise serializers.ValidationError(
                {"season": "season is required when filtering by league."}
            )
        if not any(attrs.get(key) for key in ("id", "league", "search", "country")):
            raise serializers.ValidationError(
                "Provide id, search, country, or league+season."
            )
        return attrs


class TeamStatisticsQuerySerializer(serializers.Serializer):
    league = serializers.IntegerField(min_value=1)
    season = serializers.IntegerField(min_value=2000, max_value=2100)


class PlayerQuerySerializer(PageQuerySerializer):
    id = serializers.IntegerField(required=False, min_value=1)
    team = serializers.IntegerField(required=False, min_value=1)
    league = serializers.IntegerField(required=False, min_value=1)
    season = serializers.IntegerField(min_value=2000, max_value=2100)
    search = serializers.CharField(required=False, max_length=64)

    def validate(self, attrs):
        if not any(attrs.get(key) for key in ("id", "team", "league", "search")):
            raise serializers.ValidationError(
                "Provide id, team, league, or search together with season."
            )
        return attrs


class PlayerStatisticsQuerySerializer(serializers.Serializer):
    season = serializers.IntegerField(min_value=2000, max_value=2100)


class PlayerCompareQuerySerializer(serializers.Serializer):
    left = serializers.IntegerField(min_value=1)
    right = serializers.IntegerField(min_value=1)
    season = serializers.IntegerField(min_value=2000, max_value=2100)

    def validate(self, attrs):
        if attrs["left"] == attrs["right"]:
            raise serializers.ValidationError("Select two different players.")
        return attrs


class StandingsQuerySerializer(serializers.Serializer):
    league = serializers.IntegerField(min_value=1)
    season = serializers.IntegerField(min_value=2000, max_value=2100)
    team = serializers.IntegerField(required=False, min_value=1)


class HeadToHeadQuerySerializer(PageQuerySerializer):
    home = serializers.IntegerField(min_value=1)
    away = serializers.IntegerField(min_value=1)
    last = serializers.IntegerField(required=False, min_value=1, max_value=50)
    league = serializers.IntegerField(required=False, min_value=1)
    season = serializers.IntegerField(required=False, min_value=2000, max_value=2100)

    def validate(self, attrs):
        if attrs["home"] == attrs["away"]:
            raise serializers.ValidationError("home and away must be different teams.")
        return attrs
