from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework.response import Response

from football.catalog_serializers import (
    CatalogPlayerSerializer,
    CatalogTeamSerializer,
    CompetitionSeasonSerializer,
    CompetitionSerializer,
    PlayerSeasonStatisticsSerializer,
    PlayerTransferSerializer,
    TeamSeasonStatisticsSerializer,
)
from football.models import (
    Competition,
    CompetitionSeason,
    Player,
    PlayerSeasonStatistics,
    PlayerTransfer,
    Team,
    TeamCompetition,
    TeamSeasonStatistics,
)
from football.exceptions import FootballProviderError
from football.services.catalog import seed_competitions
from football.services.live_catalog import (
    refresh_player_seasons,
    refresh_squad,
    refresh_team_seasons,
)
from football.views import FootballAPIView
from integrations.api_football.seasons import (
    is_season_complete,
    is_season_current,
    season_label,
    season_years,
)


class CompetitionsView(FootballAPIView):
    serializer_class = CompetitionSerializer

    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request):
        seed_competitions()
        rows = Competition.objects.filter(is_enabled=True)
        return Response(
            {
                "results": CompetitionSerializer(rows, many=True).data,
                "disclaimer": "Competition ids are API-Football league ids. Seasons are not marked complete while they are in progress.",
            }
        )


class CompetitionSeasonsView(FootballAPIView):
    serializer_class = CompetitionSeasonSerializer

    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, league_id: int):
        seed_competitions()
        competition = Competition.objects.filter(external_id=str(league_id)).first()
        if not competition:
            return Response({"detail": "Unknown competition."}, status=404)
        stored = {
            row.year: row
            for row in CompetitionSeason.objects.filter(competition=competition)
        }
        results = []
        for year in reversed(season_years()):
            row = stored.get(year)
            if row:
                results.append(CompetitionSeasonSerializer(row).data)
            else:
                results.append(
                    {
                        "year": year,
                        "label": season_label(year),
                        "is_current": is_season_current(year),
                        "is_complete": is_season_complete(year),
                        "coverage_fixtures": None,
                        "coverage_standings": None,
                        "coverage_players": None,
                        "coverage_statistics": None,
                        "synced_at": None,
                        "availability": "not_synced",
                    }
                )
        return Response({"results": results, "competition": CompetitionSerializer(competition).data})


class TeamSeasonsView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, team_id: int):
        league = request.query_params.get("league")
        fetch_error = None
        if league:
            try:
                refresh_team_seasons(team_id, int(league))
            except FootballProviderError as exc:
                fetch_error = exc.message
        team = Team.objects.filter(external_id=str(team_id)).first()
        if not team:
            return Response(
                {
                    "results": [],
                    "missing": True,
                    "detail": fetch_error
                    or "Provide league= to load verified standings from API-Football.",
                }
            )
        stats = TeamSeasonStatistics.objects.filter(team=team).select_related("competition")
        if league:
            stats = stats.filter(competition__external_id=str(league))
        return Response(
            {
                "results": TeamSeasonStatisticsSerializer(stats, many=True).data,
                "team": CatalogTeamSerializer(team, context={"request": request}).data,
                "provider_error": fetch_error,
            }
        )


class TeamSquadView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, team_id: int):
        fetch_error = None
        try:
            refresh_squad(team_id)
        except FootballProviderError as exc:
            fetch_error = exc.message
        team = Team.objects.filter(external_id=str(team_id)).first()
        if not team:
            return Response(
                {"results": [], "missing": True, "detail": fetch_error or "Squad unavailable."}
            )
        players = Player.objects.filter(team=team)
        return Response(
            {
                "results": CatalogPlayerSerializer(
                    players, many=True, context={"request": request}
                ).data,
                "team": CatalogTeamSerializer(team, context={"request": request}).data,
                "provider_error": fetch_error,
            }
        )


class PlayerDetailView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, player_id: int):
        player = Player.objects.filter(external_id=str(player_id)).first()
        if not player:
            try:
                player = refresh_player_seasons(player_id, max_seasons=1)
            except FootballProviderError as exc:
                return Response(
                    {"results": None, "missing": True, "detail": exc.message},
                    status=exc.status_code,
                )
        if not player:
            return Response(
                {
                    "results": None,
                    "missing": True,
                    "detail": "No verified player record was returned.",
                },
                status=404,
            )
        return Response(
            {
                "results": CatalogPlayerSerializer(player, context={"request": request}).data,
            }
        )


class PlayerSeasonsView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, player_id: int):
        fetch_error = None
        try:
            refresh_player_seasons(player_id)
        except FootballProviderError as exc:
            fetch_error = exc.message
        player = Player.objects.filter(external_id=str(player_id)).first()
        if not player:
            return Response(
                {"results": [], "missing": True, "detail": fetch_error or "Player unavailable."}
            )
        stats = PlayerSeasonStatistics.objects.filter(player=player).select_related(
            "team", "competition"
        )
        return Response(
            {
                "results": PlayerSeasonStatisticsSerializer(stats, many=True).data,
                "player": CatalogPlayerSerializer(player, context={"request": request}).data,
                "provider_error": fetch_error,
            }
        )


class PlayerTransfersView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request, player_id: int):
        player = Player.objects.filter(external_id=str(player_id)).first()
        if not player:
            return Response({"results": [], "missing": True})
        rows = PlayerTransfer.objects.filter(player=player)
        return Response({"results": PlayerTransferSerializer(rows, many=True).data})


class TeamCompareView(FootballAPIView):
    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request):
        left = request.query_params.get("left")
        right = request.query_params.get("right")
        season = request.query_params.get("season")
        league = request.query_params.get("league")
        if not left or not right or not season:
            return Response(
                {"detail": "Provide left, right, and season (API-Football team ids)."},
                status=400,
            )
        qs = TeamSeasonStatistics.objects.select_related("team", "competition")
        left_rows = qs.filter(team__external_id=str(left), year=int(season))
        right_rows = qs.filter(team__external_id=str(right), year=int(season))
        if league:
            left_rows = left_rows.filter(competition__external_id=str(league))
            right_rows = right_rows.filter(competition__external_id=str(league))
        left_stat = left_rows.first()
        right_stat = right_rows.first()
        return Response(
            {
                "season": int(season),
                "left": TeamSeasonStatisticsSerializer(left_stat).data if left_stat else None,
                "right": TeamSeasonStatisticsSerializer(right_stat).data if right_stat else None,
                "disclaimer": "Only stored provider statistics are compared. Missing values stay null.",
            }
        )


class CatalogTeamsView(FootballAPIView):
    """Local catalog listing. Does not invent clubs."""

    @extend_schema(responses={200: OpenApiTypes.OBJECT}, tags=["football"])
    def get(self, request):
        qs = Team.objects.all()
        search = request.query_params.get("search")
        country = request.query_params.get("country")
        league = request.query_params.get("league")
        season = request.query_params.get("season")
        if search:
            qs = qs.filter(name__icontains=search)
        if country:
            qs = qs.filter(country__iexact=country)
        if league:
            links = TeamCompetition.objects.filter(competition__external_id=str(league))
            if season:
                links = links.filter(year=int(season))
            qs = qs.filter(id__in=links.values("team_id"))
        qs = qs.order_by("name")
        count = qs.count()
        return Response(
            {
                "results": CatalogTeamSerializer(
                    qs[:100], many=True, context={"request": request}
                ).data,
                "count": count,
            }
        )
