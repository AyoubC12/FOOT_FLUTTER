from django.core.management.base import BaseCommand, CommandError

from football.models import Competition
from football.services.catalog import (
    seed_competitions,
    sync_league_teams,
    sync_player_season,
    sync_standings,
    sync_team_statistics,
)


class Command(BaseCommand):
    help = (
        "Controlled API-Football sync for one league season. "
        "Does not invent statistics. Requires FOOTBALL_API_KEY."
    )

    def add_arguments(self, parser):
        parser.add_argument("--league", type=int, required=True, help="API-Football league id")
        parser.add_argument("--season", type=int, required=True, help="Season start year, e.g. 2024")
        parser.add_argument("--standings", action="store_true")
        parser.add_argument("--team-stats", action="store_true")
        parser.add_argument("--media", action="store_true", help="Download logos as JPEG")
        parser.add_argument("--limit-teams", type=int, default=0)

    def handle(self, *args, **options):
        seed_competitions()
        league_id = options["league"]
        year = options["season"]
        if not Competition.objects.filter(external_id=str(league_id)).exists():
            raise CommandError(
                f"League {league_id} is not in the catalog. Add a Competition row or extend CATALOG."
            )
        teams = sync_league_teams(league_id, year, download_media=options["media"])
        if options["limit_teams"]:
            teams = teams[: options["limit_teams"]]
        self.stdout.write(f"Teams stored: {len(teams)}")
        if options["standings"]:
            rows = sync_standings(league_id, year)
            self.stdout.write(f"Standings rows stored: {rows}")
        if options["team_stats"]:
            for team in teams:
                sync_team_statistics(team, league_id, year)
            self.stdout.write("Team statistics requested for stored clubs.")
        # player sync is opt-in via a separate season call to avoid burning quota
        _ = sync_player_season
