from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from assistant.services.chat_service import AssistantConfigError

User = get_user_model()

SAMPLE_PLAYERS = [
    {
        "id": "gk",
        "name": "Donnarumma",
        "position": "GK",
        "x": 0.5,
        "y": 0.9,
        "number": 1,
    },
    {
        "id": "st",
        "name": "Haaland",
        "position": "ST",
        "x": 0.5,
        "y": 0.22,
        "number": 9,
    },
]


class TacticsApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="coach",
            email="coach@example.com",
            password="StrongPass123",
        )
        self.client.force_authenticate(self.user)

    def test_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get(reverse("tactical-board-list"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_save_and_list_board(self):
        response = self.client.post(
            reverse("tactical-board-list"),
            {"name": "Home press", "formation": "4-3-3", "players": SAMPLE_PLAYERS},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        listing = self.client.get(reverse("tactical-board-list"))
        self.assertEqual(listing.data["count"], 1)

    def test_rejects_invalid_formation_and_coords(self):
        response = self.client.post(
            reverse("tactical-board-list"),
            {
                "name": "Bad",
                "formation": "5-5-0",
                "players": SAMPLE_PLAYERS,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        response = self.client.post(
            reverse("tactical-board-list"),
            {
                "name": "Bad coords",
                "formation": "4-4-2",
                "players": [
                    {
                        "id": "a",
                        "name": "A",
                        "position": "ST",
                        "x": 1.4,
                        "y": 0.2,
                    }
                ],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_rejects_more_than_eleven(self):
        players = [
            {
                "id": f"p{i}",
                "name": f"P{i}",
                "position": "CM",
                "x": 0.5,
                "y": 0.5,
            }
            for i in range(12)
        ]
        response = self.client.post(
            reverse("tactical-board-list"),
            {"name": "Too many", "formation": "4-4-2", "players": players},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch(
        "tactics.services.suggest._openai_suggestion",
        side_effect=AssistantConfigError("The assistant is not configured."),
    )
    def test_suggest_falls_back_to_verified_notes(self, _mock_openai):
        response = self.client.post(
            reverse("tactics-suggest"),
            {"formation": "4-3-3", "players": SAMPLE_PLAYERS},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["source"], "verified_notes")
        self.assertTrue(response.data["structural_tips"])

    def test_compare_saved_boards(self):
        left = self.client.post(
            reverse("tactical-board-list"),
            {"name": "A", "formation": "4-3-3", "players": SAMPLE_PLAYERS},
            format="json",
        ).data
        right_players = [
            {**SAMPLE_PLAYERS[0], "id": "gk2"},
            {
                "id": "wb",
                "name": "Hakimi",
                "position": "RWB",
                "x": 0.9,
                "y": 0.52,
                "number": 2,
            },
        ]
        right = self.client.post(
            reverse("tactical-board-list"),
            {"name": "B", "formation": "3-5-2", "players": right_players},
            format="json",
        ).data
        with patch(
            "tactics.services.suggest._openai_suggestion",
            side_effect=AssistantConfigError("off"),
        ):
            response = self.client.post(
                reverse("tactics-compare"),
                {"left_id": left["id"], "right_id": right["id"]},
                format="json",
            )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("left", response.data)
        self.assertIn("right", response.data)
