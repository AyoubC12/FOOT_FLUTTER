from django.core.management.base import BaseCommand, CommandError

from football.exceptions import FootballProviderError
from predictions.engine.history import pull_league_season


class Command(BaseCommand):
    help = (
        "Store finished API-Football fixtures for a league season. "
        "Matches without scores are skipped; nothing is invented."
    )

    def add_arguments(self, parser):
        parser.add_argument("--league", type=int, required=True)
        parser.add_argument("--season", type=int, required=True)

    def handle(self, *args, **options):
        league = options["league"]
        season = options["season"]
        try:
            stored = pull_league_season(league, season)
        except FootballProviderError as exc:
            raise CommandError(exc.message) from exc
        self.stdout.write(self.style.SUCCESS(f"Stored {stored} finished matches."))
