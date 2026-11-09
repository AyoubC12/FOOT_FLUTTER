from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from football.exceptions import FootballProviderError, FootballRateLimitError
from football.pagination import football_response
from rest_framework import mixins, viewsets
from rest_framework import status

from accounts.permissions import IsOwner
from football.query import (
    FixtureQuerySerializer,
    HeadToHeadQuerySerializer,
    LiveQuerySerializer,
    PlayerCompareQuerySerializer,
    PlayerQuerySerializer,
    PlayerStatisticsQuerySerializer,
    StandingsQuerySerializer,
    TeamQuerySerializer,
    TeamStatisticsQuerySerializer,
)
from football.serializers import SavedPlayerComparisonSerializer
from football.services.player_metrics import (
    comparison_rows,
    decorate_player,
)
from football.services.catalog import (
    link_team_competition,
    persist_player_season,
    persist_standings_row,
    persist_team_statistics,
    seed_competitions,
    upsert_player,
    upsert_team,
)
from football.models import Competition, SavedPlayerComparison, Team
from football.services.api_football import ApiFootballService


def _service() -> ApiFootballService:
    return ApiFootballService()


def _persist_teams(results: list, data: dict) -> None:
    seed_competitions()
    competition = None
    league = data.get("league")
    year = data.get("season")
    if league:
        competition = Competition.objects.filter(external_id=str(league)).first()
    for item in results:
        try:
            team = upsert_team(item)
            if competition and year:
                link_team_competition(team, competition, year)
        except (TypeError, ValueError):
            continue


def _persist_player_payload(body: dict, year: int) -> None:
    if not body.get("id"):
        return
    try:
        player = upsert_player(body)
        for block in body.get("statistics") or []:
            persist_player_season(player, block, year)
    except (TypeError, ValueError):
        return


def _persist_standings(tables: list, data: dict) -> None:
    seed_competitions()
    competition = Competition.objects.filter(external_id=str(data["league"])).first()
    if not competition:
        return
    for table in tables:
        for group in table.get("standings") or []:
            for row in group:
                persist_standings_row(row, competition, data["season"])



def _error_response(exc: FootballProviderError) -> Response:
    headers = {}
    if isinstance(exc, FootballRateLimitError) and exc.retry_after:
        headers["Retry-After"] = str(exc.retry_after)
    return Response({"detail": exc.message, "errors": exc.errors}, status=exc.status_code, headers=headers)


def _validated(serializer_class, request):
    serializer = serializer_class(data=request.query_params)
    serializer.is_valid(raise_exception=True)
    return serializer.validated_data


def _provider_params(data: dict, *exclude: str) -> dict:
    skip = {"page", "page_size", *exclude}
    rename = {"from_date": "from", "to_date": "to"}
    params = {}
    for key, value in data.items():
        if key in skip or value is None:
            continue
        provider_key = rename.get(key, key)
        if hasattr(value, "isoformat"):
            params[provider_key] = value.isoformat()
        else:
            params[provider_key] = value
    return params


class FootballAPIView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = LiveQuerySerializer

    def handle_exception(self, exc):
        if isinstance(exc, FootballProviderError):
            return _error_response(exc)
        return super().handle_exception(exc)


class FixturesView(FootballAPIView):
    serializer_class = FixtureQuerySerializer

    @extend_schema(
        parameters=[FixtureQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_fixtures_list",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(FixtureQuerySerializer, request)
        payload = _service().fixtures(_provider_params(data))
        return football_response(
            payload, page=data["page"], page_size=data["page_size"]
        )


class LiveFixturesView(FootballAPIView):
    serializer_class = LiveQuerySerializer

    @extend_schema(
        parameters=[LiveQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_fixtures_live",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(LiveQuerySerializer, request)
        payload = _service().live_fixtures(data.get("live") or "all")
        return football_response(
            payload, page=data["page"], page_size=data["page_size"]
        )


class FixtureDetailView(FootballAPIView):
    serializer_class = LiveQuerySerializer

    @extend_schema(
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_fixtures_retrieve",
        tags=["football"],
    )
    def get(self, request, fixture_id: int):
        payload = _service().fixture_detail(fixture_id)
        return football_response(payload, paginate=False)


class TeamsView(FootballAPIView):
    serializer_class = TeamQuerySerializer

    @extend_schema(
        parameters=[TeamQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_teams_list",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(TeamQuerySerializer, request)
        payload = _service().teams(_provider_params(data))
        _persist_teams(payload.get("results") or [], data)
        return football_response(
            payload, page=data["page"], page_size=data["page_size"]
        )


class TeamDetailView(FootballAPIView):
    serializer_class = TeamQuerySerializer

    @extend_schema(
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_teams_retrieve",
        tags=["football"],
    )
    def get(self, request, team_id: int):
        payload = _service().team_detail(team_id)
        body = payload.get("results") or {}
        if body.get("id"):
            team = upsert_team(body)
            try:
                coaches = _service().coaches({"team": team_id}).get("results") or []
            except FootballProviderError:
                coaches = []
            if coaches:
                name = coaches[0].get("name") or ""
                if name:
                    team.coach_name = name
                    team.save(update_fields=["coach_name"])
                    body["coach_name"] = name
        return football_response(payload, paginate=False)


class TeamStatisticsView(FootballAPIView):
    serializer_class = TeamStatisticsQuerySerializer

    @extend_schema(
        parameters=[TeamStatisticsQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_team_statistics",
        tags=["football"],
    )
    def get(self, request, team_id: int):
        data = _validated(TeamStatisticsQuerySerializer, request)
        payload = _service().team_statistics(
            {"team": team_id, "league": data["league"], "season": data["season"]}
        )
        seed_competitions()
        team = Team.objects.filter(external_id=str(team_id)).first()
        competition = Competition.objects.filter(external_id=str(data["league"])).first()
        if team and competition:
            persist_team_statistics(team, competition, data["season"], payload.get("results") or {})
        return football_response(payload, paginate=False)


class PlayersView(FootballAPIView):
    serializer_class = PlayerQuerySerializer

    @extend_schema(
        parameters=[PlayerQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_players_list",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(PlayerQuerySerializer, request)
        params = _provider_params(data)
        params["page"] = data["page"]
        payload = _service().players(params)
        body = football_response(payload, paginate=False).data
        body["page"] = data["page"]
        body["page_size"] = data["page_size"]
        body["count"] = payload.get("results_count", len(payload.get("results") or []))
        return Response(body)


class PlayerStatisticsView(FootballAPIView):
    serializer_class = PlayerStatisticsQuerySerializer

    @extend_schema(
        parameters=[PlayerStatisticsQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_player_statistics",
        tags=["football"],
    )
    def get(self, request, player_id: int):
        data = _validated(PlayerStatisticsQuerySerializer, request)
        payload = _service().player_statistics(
            {"id": player_id, "season": data["season"]}
        )
        payload["results"] = decorate_player(payload.get("results") or {})
        _persist_player_payload(payload.get("results") or {}, data["season"])
        return football_response(payload, paginate=False)


class PlayerCompareView(FootballAPIView):
    serializer_class = PlayerCompareQuerySerializer

    @extend_schema(
        parameters=[PlayerCompareQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_player_compare",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(PlayerCompareQuerySerializer, request)
        service = _service()
        left = decorate_player(
            service.player_statistics(
                {"id": data["left"], "season": data["season"]}
            ).get("results")
            or {}
        )
        right = decorate_player(
            service.player_statistics(
                {"id": data["right"], "season": data["season"]}
            ).get("results")
            or {}
        )
        return Response(
            {
                "season": data["season"],
                "left": left,
                "right": right,
                "rows": comparison_rows(left.get("metrics") or {}, right.get("metrics") or {}),
                "disclaimer": (
                    "Provider statistics only. Missing values are shown as unavailable "
                    "and are never estimated."
                ),
            }
        )


class SavedPlayerComparisonViewSet(
    mixins.ListModelMixin,
    mixins.CreateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = SavedPlayerComparisonSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return SavedPlayerComparison.objects.filter(user=self.request.user)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            return self._save_comparison(request, data)
        except FootballProviderError as exc:
            return _error_response(exc)

    def _save_comparison(self, request, data):
        service = _service()
        left = decorate_player(
            service.player_statistics(
                {"id": data["left_player_id"], "season": data["season"]}
            ).get("results")
            or {}
        )
        right = decorate_player(
            service.player_statistics(
                {"id": data["right_player_id"], "season": data["season"]}
            ).get("results")
            or {}
        )
        board = SavedPlayerComparison.objects.create(
            user=request.user,
            season=data["season"],
            left_player_id=data["left_player_id"],
            right_player_id=data["right_player_id"],
            left_name=left.get("name") or f"Player {data['left_player_id']}",
            right_name=right.get("name") or f"Player {data['right_player_id']}",
            left_photo=left.get("photo") or "",
            right_photo=right.get("photo") or "",
            snapshot={
                "rows": comparison_rows(
                    left.get("metrics") or {}, right.get("metrics") or {}
                ),
                "disclaimer": (
                    "Snapshot of available provider statistics at save time. "
                    "Missing values were not estimated."
                ),
            },
        )
        return Response(
            SavedPlayerComparisonSerializer(board).data,
            status=status.HTTP_201_CREATED,
        )


class StandingsView(FootballAPIView):
    serializer_class = StandingsQuerySerializer

    @extend_schema(
        parameters=[StandingsQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_standings",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(StandingsQuerySerializer, request)
        payload = _service().standings(_provider_params(data))
        _persist_standings(payload.get("results") or [], data)
        return football_response(payload, paginate=False)


class HeadToHeadView(FootballAPIView):
    serializer_class = HeadToHeadQuerySerializer

    @extend_schema(
        parameters=[HeadToHeadQuerySerializer],
        responses={200: OpenApiTypes.OBJECT},
        operation_id="football_head_to_head",
        tags=["football"],
    )
    def get(self, request):
        data = _validated(HeadToHeadQuerySerializer, request)
        params = {
            "h2h": f"{data['home']}-{data['away']}",
            **_provider_params(data, "home", "away"),
        }
        payload = _service().head_to_head(params)
        return football_response(
            payload, page=data["page"], page_size=data["page_size"]
        )
