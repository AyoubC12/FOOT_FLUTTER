from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from football.services.normalizers import normalize_fixture, statistics_map

User = get_user_model()

FIXTURE_PAYLOAD = {
    "get": "fixtures",
    "errors": {},
    "results": 1,
    "paging": {"current": 1, "total": 1},
    "response": [
        {
            "fixture": {
                "id": 1035606,
                "timezone": "UTC",
                "date": "2024-05-19T15:00:00+00:00",
                "timestamp": 1716130800,
                "referee": None,
                "periods": {"first": None, "second": None},
                "venue": {"id": 494, "name": "Emirates Stadium", "city": "London"},
                "status": {"long": "Not Started", "short": "NS", "elapsed": None, "extra": None},
            },
            "league": {
                "id": 39,
                "name": "Premier League",
                "country": "England",
                "logo": "https://media.api-sports.io/football/leagues/39.png",
                "flag": "https://media.api-sports.io/flags/gb.svg",
                "season": 2023,
                "round": "Regular Season - 38",
            },
            "teams": {
                "home": {
                    "id": 42,
                    "name": "Arsenal",
                    "logo": "https://media.api-sports.io/football/teams/42.png",
                },
                "away": {
                    "id": 33,
                    "name": "Manchester United",
                    "logo": "https://media.api-sports.io/football/teams/33.png",
                },
            },
            "goals": {"home": None, "away": None},
            "score": {
                "halftime": {"home": None, "away": None},
                "fulltime": {"home": None, "away": None},
                "extratime": {"home": None, "away": None},
                "penalty": {"home": None, "away": None},
            },
        }
    ],
}


@override_settings(
    FOOTBALL_API_KEY="unit-test-key-not-real",
    FOOTBALL_API_BASE_URL="https://v3.football.api-sports.io",
    FOOTBALL_API_HOST="",
)
class FootballApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="fan",
            email="fan@example.com",
            password="StrongPass123",
        )
        self.client.force_authenticate(self.user)
        cache.clear()

    @override_settings(FOOTBALL_API_KEY="")
    def test_missing_provider_key_is_503(self):
        response = self.client.get(reverse("football-live"))
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)
        self.assertNotIn("unit-test-key-not-real", str(response.data))

    def test_fixtures_require_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(reverse("football-fixtures"), {"date": "2024-05-19"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    @patch("football.services.api_football.requests.get")
    def test_live_fixtures_use_provider_and_hide_key(self, mock_get):
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = FIXTURE_PAYLOAD
        mock_get.return_value.headers = {}

        response = self.client.get(reverse("football-live"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["results"][0]["goals"]["home"], None)
        self.assertNotIn("unit-test-key-not-real", str(response.data))
        headers = mock_get.call_args.kwargs["headers"]
        self.assertEqual(headers["x-apisports-key"], "unit-test-key-not-real")
        self.assertEqual(mock_get.call_args.kwargs["params"]["live"], "all")

    @patch("football.services.api_football.requests.get")
    def test_rate_limit_returns_429(self, mock_get):
        mock_get.return_value.status_code = 429
        mock_get.return_value.headers = {"Retry-After": "8"}
        response = self.client.get(reverse("football-live"))
        self.assertEqual(response.status_code, status.HTTP_429_TOO_MANY_REQUESTS)
        self.assertEqual(response["Retry-After"], "8")

    def test_missing_statistics_are_null(self):
        mapped = statistics_map([{"type": "Total Shots", "value": None}])
        self.assertIsNone(mapped["total_shots"])
        self.assertIsNone(mapped["expected_goals"])
        fixture = normalize_fixture(FIXTURE_PAYLOAD["response"][0])
        self.assertIsNone(fixture["goals"]["home"])
        self.assertIsNone(fixture["goals"]["away"])

    @patch("football.services.api_football.requests.get")
    def test_player_statistics_keep_missing_assists_null(self, mock_get):
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = _player_payload(
            player_id=1100,
            name="Test Forward",
            goals=8,
            assists=None,
            tackles=None,
        )
        mock_get.return_value.headers = {}
        response = self.client.get(
            reverse("football-player-statistics", args=[1100]),
            {"season": 2025},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        metrics = response.data["results"]["metrics"]
        self.assertEqual(metrics["goals"], 8)
        self.assertIsNone(metrics["assists"])
        self.assertIsNone(metrics["tackles"])

    @patch("football.services.api_football.requests.get")
    def test_compare_does_not_fill_missing_stats(self, mock_get):
        def _side_effect(*_args, **kwargs):
            player_id = kwargs["params"]["id"]
            payload = type("Resp", (), {})()
            payload.status_code = 200
            payload.headers = {}
            if player_id == 1:
                payload.json = lambda: _player_payload(1, "Left", goals=10, assists=2)
            else:
                payload.json = lambda: _player_payload(
                    2, "Right", goals=4, assists=None, tackles=None
                )
            return payload

        mock_get.side_effect = _side_effect
        response = self.client.get(
            reverse("football-player-compare"),
            {"left": 1, "right": 2, "season": 2025},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        assists = next(row for row in response.data["rows"] if row["key"] == "assists")
        self.assertEqual(assists["left"], 2)
        self.assertIsNone(assists["right"])
        self.assertIsNone(assists["winner"])

    @patch("football.services.api_football.requests.get")
    def test_save_comparison(self, mock_get):
        mock_get.return_value.status_code = 200
        mock_get.return_value.headers = {}
        mock_get.return_value.json.return_value = _player_payload(3, "Saved")
        response = self.client.post(
            reverse("player-comparison-list"),
            {"season": 2025, "left_player_id": 3, "right_player_id": 4},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        listing = self.client.get(reverse("player-comparison-list"))
        self.assertEqual(listing.data["count"], 1)


def _player_payload(player_id, name, goals=5, assists=1, tackles=3):
    return {
        "get": "players",
        "errors": {},
        "results": 1,
        "paging": {"current": 1, "total": 1},
        "response": [
            {
                "player": {
                    "id": player_id,
                    "name": name,
                    "firstname": name,
                    "lastname": "",
                    "age": 24,
                    "nationality": "England",
                    "height": "180 cm",
                    "weight": "75 kg",
                    "photo": "https://media.api-sports.io/football/players/1.png",
                    "injured": False,
                    "birth": {"date": "2001-01-01", "place": None, "country": "England"},
                },
                "statistics": [
                    {
                        "team": {"id": 42, "name": "Arsenal", "logo": None},
                        "league": {
                            "id": 39,
                            "name": "Premier League",
                            "country": "England",
                            "season": 2025,
                        },
                        "games": {
                            "appearences": 20,
                            "lineups": 18,
                            "minutes": 1600,
                            "number": 7,
                            "position": "Attacker",
                            "rating": "7.40",
                            "captain": False,
                        },
                        "substitutes": {"in": 2, "out": 4, "bench": 3},
                        "shots": {"total": 40, "on": 18},
                        "goals": {
                            "total": goals,
                            "conceded": None,
                            "assists": assists,
                            "saves": None,
                        },
                        "passes": {"total": 600, "key": 30, "accuracy": 84},
                        "tackles": {"total": tackles, "blocks": None, "interceptions": 8},
                        "duels": {"total": 100, "won": 55},
                        "dribbles": {"attempts": 40, "success": 22, "past": None},
                        "fouls": {"drawn": 12, "committed": 9},
                        "cards": {"yellow": 2, "yellowred": 0, "red": 0},
                        "penalty": {"won": None, "commited": None, "scored": 1, "missed": 0, "saved": None},
                    }
                ],
            }
        ],
    }
