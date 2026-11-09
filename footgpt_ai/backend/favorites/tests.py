from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class FavoritesApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="fav",
            email="fav@example.com",
            password="StrongPass123",
        )

    def test_list_requires_jwt(self):
        response = self.client.get("/api/v1/favorites/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_create_and_list_for_owner(self):
        self.client.force_authenticate(self.user)
        created = self.client.post(
            "/api/v1/favorites/",
            {"item_type": "team", "item_external_id": "42"},
            format="json",
        )
        self.assertEqual(created.status_code, status.HTTP_201_CREATED)
        listing = self.client.get("/api/v1/favorites/")
        self.assertEqual(listing.status_code, status.HTTP_200_OK)
        results = listing.data.get("results", listing.data)
        self.assertEqual(len(results), 1)
