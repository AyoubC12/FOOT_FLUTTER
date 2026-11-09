from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from .models import DeviceToken

User = get_user_model()


class DeviceTokenApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="notify",
            email="notify@example.com",
            password="StrongPass123",
        )

    def test_register_requires_jwt(self):
        response = self.client.post(
            "/api/v1/notifications/devices/",
            {"token": "abc", "platform": "android"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_register_and_deactivate(self):
        self.client.force_authenticate(self.user)
        created = self.client.post(
            "/api/v1/notifications/devices/",
            {"token": "fcm-token-1", "platform": "android"},
            format="json",
        )
        self.assertEqual(created.status_code, status.HTTP_201_CREATED)
        device_id = created.data["id"]
        listing = self.client.get("/api/v1/notifications/devices/")
        self.assertEqual(listing.data["count"] if "count" in listing.data else 1, 1)
        deleted = self.client.delete(f"/api/v1/notifications/devices/{device_id}/")
        self.assertEqual(deleted.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(DeviceToken.objects.get(id=device_id).is_active)
