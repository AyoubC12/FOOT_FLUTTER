from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .catalog_views import (
    CatalogTeamsView,
    CompetitionSeasonsView,
    CompetitionsView,
    PlayerDetailView,
    PlayerSeasonsView,
    PlayerTransfersView,
    TeamCompareView,
    TeamSeasonsView,
    TeamSquadView,
)
from .views import (
    FixtureDetailView,
    FixturesView,
    HeadToHeadView,
    LiveFixturesView,
    PlayerCompareView,
    PlayerStatisticsView,
    PlayersView,
    SavedPlayerComparisonViewSet,
    StandingsView,
    TeamDetailView,
    TeamStatisticsView,
    TeamsView,
)

router = DefaultRouter()
router.register(
    "players/comparisons",
    SavedPlayerComparisonViewSet,
    basename="player-comparison",
)

urlpatterns = [
    path("competitions/<int:league_id>/seasons/", CompetitionSeasonsView.as_view(), name="football-competition-seasons"),
    path("competitions/", CompetitionsView.as_view(), name="football-competitions"),
    path("catalog/teams/", CatalogTeamsView.as_view(), name="football-catalog-teams"),
    path("teams/compare/", TeamCompareView.as_view(), name="football-team-compare"),
    path("teams/<int:team_id>/seasons/", TeamSeasonsView.as_view(), name="football-team-seasons"),
    path("teams/<int:team_id>/squad/", TeamSquadView.as_view(), name="football-team-squad"),
    path("players/<int:player_id>/seasons/", PlayerSeasonsView.as_view(), name="football-player-seasons"),
    path("players/<int:player_id>/transfers/", PlayerTransfersView.as_view(), name="football-player-transfers"),
    path("fixtures/live/", LiveFixturesView.as_view(), name="football-live"),
    path("fixtures/<int:fixture_id>/", FixtureDetailView.as_view(), name="football-fixture-detail"),
    path("fixtures/", FixturesView.as_view(), name="football-fixtures"),
    path(
        "teams/<int:team_id>/statistics/",
        TeamStatisticsView.as_view(),
        name="football-team-statistics",
    ),
    path("teams/<int:team_id>/", TeamDetailView.as_view(), name="football-team-detail"),
    path("teams/", TeamsView.as_view(), name="football-teams"),
    path("players/compare/", PlayerCompareView.as_view(), name="football-player-compare"),
    path(
        "players/<int:player_id>/statistics/",
        PlayerStatisticsView.as_view(),
        name="football-player-statistics",
    ),
    path("players/<int:player_id>/", PlayerDetailView.as_view(), name="football-player-detail"),
    path("players/", PlayersView.as_view(), name="football-players"),
    path("standings/", StandingsView.as_view(), name="football-standings"),
    path("head-to-head/", HeadToHeadView.as_view(), name="football-h2h"),
    path("", include(router.urls)),
]
