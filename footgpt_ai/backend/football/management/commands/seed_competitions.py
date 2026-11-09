from django.core.management.base import BaseCommand

from football.services.catalog import seed_competitions


class Command(BaseCommand):
    help = "Insert the default API-Football competition catalog and 2009–2027 seasons."

    def handle(self, *args, **options):
        created = seed_competitions()
        self.stdout.write(self.style.SUCCESS(f"Competitions created: {created}"))
