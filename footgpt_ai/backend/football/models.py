from django.conf import settings
from django.db import models


class Team(models.Model):
    external_id = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    short_name = models.CharField(max_length=16, blank=True)
    country = models.CharField(max_length=64, blank=True)
    city = models.CharField(max_length=128, blank=True)
    stadium_name = models.CharField(max_length=128, blank=True)
    stadium_capacity = models.PositiveIntegerField(null=True, blank=True)
    coach_name = models.CharField(max_length=128, blank=True)
    founded = models.PositiveSmallIntegerField(null=True, blank=True)
    website = models.URLField(blank=True)
    logo_url = models.URLField(max_length=500, blank=True)
    logo_file = models.ImageField(upload_to="football/teams/", blank=True)
    national = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["country"], name="idx_team_country"),
            models.Index(fields=["name"], name="idx_team_name"),
        ]

    def __str__(self) -> str:
        return self.name


class Player(models.Model):
    external_id = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    first_name = models.CharField(max_length=64, blank=True)
    last_name = models.CharField(max_length=64, blank=True)
    position = models.CharField(max_length=32, blank=True)
    nationality = models.CharField(max_length=64, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    height_cm = models.PositiveSmallIntegerField(null=True, blank=True)
    weight_kg = models.PositiveSmallIntegerField(null=True, blank=True)
    shirt_number = models.PositiveSmallIntegerField(null=True, blank=True)
    preferred_foot = models.CharField(max_length=16, blank=True)
    photo_url = models.URLField(max_length=500, blank=True)
    photo_file = models.ImageField(upload_to="football/players/", blank=True)
    team = models.ForeignKey(
        Team,
        on_delete=models.SET_NULL,
        related_name="players",
        null=True,
        blank=True,
    )
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]
        indexes = [
            models.Index(fields=["nationality"], name="idx_player_nationality"),
            models.Index(fields=["position"], name="idx_player_position"),
        ]

    def __str__(self) -> str:
        return self.name


class Match(models.Model):
    class Status(models.TextChoices):
        SCHEDULED = "scheduled", "Scheduled"
        LIVE = "live", "Live"
        FINISHED = "finished", "Finished"

    external_id = models.CharField(max_length=64, unique=True)
    league_name = models.CharField(max_length=128, blank=True)
    home_team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="home_matches",
    )
    away_team = models.ForeignKey(
        Team,
        on_delete=models.CASCADE,
        related_name="away_matches",
    )
    kickoff_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=16,
        choices=Status.choices,
        default=Status.SCHEDULED,
    )
    home_score = models.PositiveSmallIntegerField(null=True, blank=True)
    away_score = models.PositiveSmallIntegerField(null=True, blank=True)
    venue = models.CharField(max_length=128, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-kickoff_at", "-created_at"]
        indexes = [
            models.Index(fields=["status", "kickoff_at"], name="idx_match_status_kickoff"),
            models.Index(fields=["league_name"], name="idx_match_league"),
        ]

    def __str__(self) -> str:
        return f"{self.home_team} vs {self.away_team}"


class SavedPlayerComparison(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="player_comparisons",
    )
    season = models.PositiveSmallIntegerField()
    left_player_id = models.PositiveIntegerField()
    right_player_id = models.PositiveIntegerField()
    left_name = models.CharField(max_length=128)
    right_name = models.CharField(max_length=128)
    left_photo = models.URLField(blank=True)
    right_photo = models.URLField(blank=True)
    snapshot = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"{self.left_name} vs {self.right_name} ({self.season})"


class Competition(models.Model):
    external_id = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    country = models.CharField(max_length=64, blank=True)
    type = models.CharField(max_length=32, blank=True)
    logo_url = models.URLField(max_length=500, blank=True)
    is_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Season(models.Model):
    """Football season keyed by start year (2009 = 2009-2010)."""

    year = models.PositiveSmallIntegerField(unique=True)
    label = models.CharField(max_length=16)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-year"]

    def __str__(self) -> str:
        return self.label


class CompetitionSeason(models.Model):
    """Provider coverage for one competition season. Missing flags stay false/unknown."""

    competition = models.ForeignKey(
        Competition,
        on_delete=models.CASCADE,
        related_name="season_coverage",
    )
    year = models.PositiveSmallIntegerField()
    is_current = models.BooleanField(default=False)
    coverage_fixtures = models.BooleanField(null=True, blank=True)
    coverage_standings = models.BooleanField(null=True, blank=True)
    coverage_players = models.BooleanField(null=True, blank=True)
    coverage_statistics = models.BooleanField(null=True, blank=True)
    synced_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-year"]
        constraints = [
            models.UniqueConstraint(
                fields=["competition", "year"],
                name="unique_competition_season",
            )
        ]


class TeamCompetition(models.Model):
    team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name="competitions")
    competition = models.ForeignKey(
        Competition,
        on_delete=models.CASCADE,
        related_name="team_links",
    )
    year = models.PositiveSmallIntegerField()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["team", "competition", "year"],
                name="unique_team_competition_season",
            )
        ]
        indexes = [
            models.Index(fields=["year", "competition"], name="idx_teamcomp_year_comp"),
        ]


class TeamSeasonStatistics(models.Model):
    team = models.ForeignKey(Team, on_delete=models.CASCADE, related_name="season_stats")
    competition = models.ForeignKey(
        Competition,
        on_delete=models.CASCADE,
        related_name="team_season_stats",
    )
    year = models.PositiveSmallIntegerField()
    played = models.PositiveSmallIntegerField(null=True, blank=True)
    wins = models.PositiveSmallIntegerField(null=True, blank=True)
    draws = models.PositiveSmallIntegerField(null=True, blank=True)
    losses = models.PositiveSmallIntegerField(null=True, blank=True)
    goals_for = models.PositiveSmallIntegerField(null=True, blank=True)
    goals_against = models.PositiveSmallIntegerField(null=True, blank=True)
    goal_diff = models.SmallIntegerField(null=True, blank=True)
    points = models.SmallIntegerField(null=True, blank=True)
    rank = models.PositiveSmallIntegerField(null=True, blank=True)
    clean_sheets = models.PositiveSmallIntegerField(null=True, blank=True)
    possession_avg = models.FloatField(null=True, blank=True)
    shots_per_game = models.FloatField(null=True, blank=True)
    shots_on_target = models.FloatField(null=True, blank=True)
    yellow_cards = models.PositiveSmallIntegerField(null=True, blank=True)
    red_cards = models.PositiveSmallIntegerField(null=True, blank=True)
    home_played = models.PositiveSmallIntegerField(null=True, blank=True)
    home_wins = models.PositiveSmallIntegerField(null=True, blank=True)
    home_draws = models.PositiveSmallIntegerField(null=True, blank=True)
    home_losses = models.PositiveSmallIntegerField(null=True, blank=True)
    away_played = models.PositiveSmallIntegerField(null=True, blank=True)
    away_wins = models.PositiveSmallIntegerField(null=True, blank=True)
    away_draws = models.PositiveSmallIntegerField(null=True, blank=True)
    away_losses = models.PositiveSmallIntegerField(null=True, blank=True)
    form = models.CharField(max_length=32, blank=True)
    source = models.CharField(max_length=32, default="api-football")
    raw = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["team", "competition", "year"],
                name="unique_team_season_stats",
            )
        ]
        indexes = [models.Index(fields=["year", "rank"], name="idx_teamstats_year_rank")]


class PlayerSeasonStatistics(models.Model):
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name="season_stats")
    team = models.ForeignKey(
        Team,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="player_season_stats",
    )
    competition = models.ForeignKey(
        Competition,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="player_season_stats",
    )
    year = models.PositiveSmallIntegerField()
    appearances = models.PositiveSmallIntegerField(null=True, blank=True)
    lineups = models.PositiveSmallIntegerField(null=True, blank=True)
    minutes = models.PositiveIntegerField(null=True, blank=True)
    goals = models.PositiveSmallIntegerField(null=True, blank=True)
    assists = models.PositiveSmallIntegerField(null=True, blank=True)
    yellow_cards = models.PositiveSmallIntegerField(null=True, blank=True)
    red_cards = models.PositiveSmallIntegerField(null=True, blank=True)
    shots = models.PositiveSmallIntegerField(null=True, blank=True)
    shots_on = models.PositiveSmallIntegerField(null=True, blank=True)
    passes = models.PositiveIntegerField(null=True, blank=True)
    passes_accurate = models.PositiveIntegerField(null=True, blank=True)
    pass_accuracy = models.FloatField(null=True, blank=True)
    dribbles = models.PositiveSmallIntegerField(null=True, blank=True)
    duels_won = models.PositiveSmallIntegerField(null=True, blank=True)
    clean_sheets = models.PositiveSmallIntegerField(null=True, blank=True)
    saves = models.PositiveSmallIntegerField(null=True, blank=True)
    goals_conceded = models.PositiveSmallIntegerField(null=True, blank=True)
    rating = models.FloatField(null=True, blank=True)
    raw = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["player", "competition", "year"],
                name="unique_player_season_stats",
            )
        ]
        indexes = [models.Index(fields=["player", "year"], name="idx_playerstats_player_year")]


class PlayerTransfer(models.Model):
    player = models.ForeignKey(Player, on_delete=models.CASCADE, related_name="transfers")
    date = models.DateField(null=True, blank=True)
    transfer_type = models.CharField(max_length=32, blank=True)
    team_in_external_id = models.CharField(max_length=64, blank=True)
    team_in_name = models.CharField(max_length=128, blank=True)
    team_out_external_id = models.CharField(max_length=64, blank=True)
    team_out_name = models.CharField(max_length=128, blank=True)

    class Meta:
        ordering = ["-date"]
        constraints = [
            models.UniqueConstraint(
                fields=["player", "date", "team_in_external_id", "team_out_external_id"],
                name="unique_player_transfer",
            )
        ]


class MatchStatistics(models.Model):
    match = models.OneToOneField(Match, on_delete=models.CASCADE, related_name="statistics")
    home_possession = models.FloatField(null=True, blank=True)
    away_possession = models.FloatField(null=True, blank=True)
    home_shots = models.PositiveSmallIntegerField(null=True, blank=True)
    away_shots = models.PositiveSmallIntegerField(null=True, blank=True)
    home_shots_on = models.PositiveSmallIntegerField(null=True, blank=True)
    away_shots_on = models.PositiveSmallIntegerField(null=True, blank=True)
    raw = models.JSONField(default=dict, blank=True)

    def __str__(self) -> str:
        return f"stats:{self.match_id}"
