from django.contrib import admin

from .models import (
    Competition,
    Match,
    Player,
    PlayerSeasonStatistics,
    SavedPlayerComparison,
    Team,
    TeamSeasonStatistics,
)


@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ("name", "short_name", "country", "external_id")
    search_fields = ("name", "external_id")


@admin.register(Player)
class PlayerAdmin(admin.ModelAdmin):
    list_display = ("name", "position", "nationality", "team")
    search_fields = ("name", "external_id")
    list_filter = ("position",)


@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = (
        "home_team",
        "away_team",
        "status",
        "kickoff_at",
        "league_name",
    )
    list_filter = ("status", "league_name")


@admin.register(Competition)
class CompetitionAdmin(admin.ModelAdmin):
    list_display = ("name", "country", "external_id", "is_enabled")
    search_fields = ("name", "external_id")


@admin.register(TeamSeasonStatistics)
class TeamSeasonStatisticsAdmin(admin.ModelAdmin):
    list_display = ("team", "year", "competition", "rank", "points")
    list_filter = ("year",)


@admin.register(PlayerSeasonStatistics)
class PlayerSeasonStatisticsAdmin(admin.ModelAdmin):
    list_display = ("player", "year", "goals", "assists")
    list_filter = ("year",)


@admin.register(SavedPlayerComparison)
class SavedPlayerComparisonAdmin(admin.ModelAdmin):
    list_display = ("left_name", "right_name", "season", "user", "created_at")
    search_fields = ("left_name", "right_name", "user__email")
