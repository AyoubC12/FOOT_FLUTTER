from io import BytesIO
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APITestCase
from PIL import Image

from football.models import Competition, Player, Team, TeamSeasonStatistics
from football.services.catalog import persist_standings_row, seed_competitions, upsert_player, upsert_team
from integrations.api_football.images import media_relative_path, to_jpeg_bytes
from integrations.api_football.seasons import is_season_complete, is_season_current, season_label

User = get_user_model()


class CatalogTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="catalog",
            email="catalog@example.com",
            password="StrongPass123",
        )
        self.client.force_authenticate(self.user)
        seed_competitions()

    def test_competitions_are_seeded_without_inventing_clubs(self):
        response = self.client.get("/api/v1/football/competitions/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = {row["name"] for row in response.data["results"]}
        self.assertIn("Premier League", names)
        self.assertIn("Botola Pro", names)
        self.assertEqual(Team.objects.count(), 0)

    def test_seasons_are_labelled_and_current_is_not_complete(self):
        response = self.client.get("/api/v1/football/competitions/39/seasons/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        years = [row["year"] for row in response.data["results"]]
        self.assertIn(2009, years)
        self.assertIn(2026, years)
        current = next(row for row in response.data["results"] if row["is_current"])
        self.assertFalse(current["is_complete"])
        self.assertEqual(season_label(2009), "2009-2010")

    def test_upsert_team_uses_provider_id_only(self):
        team = upsert_team(
            {
                "id": 42,
                "name": "Arsenal",
                "code": "ARS",
                "country": "England",
                "logo": "https://media.api-sports.io/football/teams/42.png",
                "venue": {"name": "Emirates Stadium", "city": "London", "capacity": 60704},
                "founded": 1886,
            }
        )
        self.assertEqual(team.external_id, "42")
        self.assertEqual(team.stadium_capacity, 60704)
        again = upsert_team({"id": 42, "name": "Arsenal FC", "country": "England"})
        self.assertEqual(again.pk, team.pk)
        self.assertEqual(Team.objects.filter(external_id="42").count(), 1)

    def test_missing_stats_stay_null(self):
        team = upsert_team({"id": 50, "name": "Manchester City", "country": "England"})
        competition = Competition.objects.get(external_id="39")
        persist_standings_row(
            {
                "rank": 1,
                "team": {"id": 50, "name": "Manchester City"},
                "points": 91,
                "played": 38,
                "win": 28,
                "draw": 7,
                "lose": 3,
                "goals_for": 96,
                "goals_against": 34,
                "goals_diff": 62,
            },
            competition,
            2023,
        )
        stats = TeamSeasonStatistics.objects.get(team=team, year=2023)
        self.assertEqual(stats.points, 91)
        self.assertIsNone(stats.possession_avg)
        self.assertIsNone(stats.shots_per_game)
        payload = self.client.get("/api/v1/football/teams/50/seasons/")
        self.assertEqual(payload.status_code, status.HTTP_200_OK)
        self.assertIn("possession_avg", payload.data["results"][0]["missing_fields"])

    def test_jpeg_path_is_bound_to_external_id(self):
        self.assertEqual(media_relative_path("players", "276"), "football/players/276.jpg")
        png = Image.new("RGB", (8, 8), color=(10, 20, 30))
        buffer = BytesIO()
        png.save(buffer, format="PNG")
        jpeg = to_jpeg_bytes(buffer.getvalue())
        self.assertTrue(jpeg.startswith(b"\xff\xd8"))

    def test_catalog_requires_jwt(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(
            self.client.get("/api/v1/football/competitions/").status_code,
            status.HTTP_401_UNAUTHORIZED,
        )

    def test_player_photo_is_not_shared_across_ids(self):
        one = upsert_player({"id": 1, "name": "A", "photo": "https://example.com/1.png"})
        two = upsert_player({"id": 2, "name": "B", "photo": "https://example.com/2.png"})
        one.photo_file = SimpleUploadedFile("1.jpg", b"aaaa", content_type="image/jpeg")
        one.save()
        self.assertNotEqual(one.external_id, two.external_id)
        self.assertFalse(two.photo_file)

    @patch("integrations.api_football.teams.client")
    def test_squad_fetch_persists_provider_photos(self, mock_client_factory):
        service = mock_client_factory.return_value
        service.team_detail.return_value = {
            "results": {
                "id": 42,
                "name": "Arsenal",
                "logo": "https://media.api-sports.io/football/teams/42.png",
                "country": "England",
                "venue": {"name": "Emirates Stadium", "city": "London", "capacity": 60704},
            }
        }
        service.squads.return_value = {
            "results": [
                {
                    "players": [
                        {
                            "id": 276,
                            "name": "Bukayo Saka",
                            "photo": "https://media.api-sports.io/football/players/276.png",
                            "position": "Attacker",
                            "number": 7,
                        }
                    ]
                }
            ]
        }
        response = self.client.get("/api/v1/football/teams/42/squad/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["results"][0]["id"], 276)
        self.assertEqual(
            response.data["results"][0]["photo"],
            "https://media.api-sports.io/football/players/276.png",
        )
        self.assertEqual(Player.objects.get(external_id="276").name, "Bukayo Saka")

    def test_season_helpers(self):
        self.assertTrue(is_season_current(2026) or is_season_complete(2025))
        self.assertFalse(is_season_complete(2026) and is_season_current(2026))
