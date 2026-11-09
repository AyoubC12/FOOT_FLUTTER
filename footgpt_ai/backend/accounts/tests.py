from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase


class AuthApiTests(APITestCase):
    def test_register_login_profile_and_logout(self):
        register = self.client.post(
            reverse("register"),
            {
                "username": "ayoub",
                "email": "ayoub@example.com",
                "password": "StrongPass123",
                "password_confirm": "StrongPass123",
            },
            format="json",
        )
        self.assertEqual(register.status_code, status.HTTP_201_CREATED)
        access = register.data["access"]
        refresh = register.data["refresh"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
        profile = self.client.get(reverse("profile"))
        self.assertEqual(profile.status_code, status.HTTP_200_OK)
        self.assertEqual(profile.data["email"], "ayoub@example.com")

        logout = self.client.post(reverse("logout"), {"refresh": refresh}, format="json")
        self.assertEqual(logout.status_code, status.HTTP_204_NO_CONTENT)

    def test_profile_requires_auth(self):
        response = self.client.get(reverse("profile"))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_protected_modules_require_jwt(self):
        self.assertEqual(
            self.client.get(reverse("football-live")).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )
        self.assertEqual(
            self.client.get(reverse("prediction-list")).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )
        self.assertEqual(
            self.client.get(reverse("tactical-board-list")).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )
        self.assertEqual(
            self.client.get(
                reverse("football-player-compare"),
                {"left": 1, "right": 2, "season": 2025},
            ).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )
        self.assertEqual(
            self.client.post(
                reverse("assistant-chat"), {"message": "hi"}, format="json"
            ).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )
        self.assertEqual(
            self.client.post(
                reverse("prediction-estimate"),
                {"home_team_id": 1, "away_team_id": 2},
                format="json",
            ).status_code,
            status.HTTP_401_UNAUTHORIZED,
        )

    def test_v1_and_legacy_profile_paths_require_jwt(self):
        for path in ("/api/auth/profile/", "/api/v1/auth/profile/"):
            response = self.client.get(path)
            self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_login_rejects_invalid_credentials(self):
        response = self.client.post(
            reverse("login"),
            {"email": "missing@example.com", "password": "nope"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
