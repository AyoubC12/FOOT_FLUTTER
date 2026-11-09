from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AdministrationApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="member",
            email="member@example.com",
            password="StrongPass123",
        )
        self.staff = User.objects.create_user(
            username="staff",
            email="staff@example.com",
            password="StrongPass123",
            is_staff=True,
        )

    def test_audit_logs_require_staff(self):
        self.client.force_authenticate(self.user)
        response = self.client.get("/api/v1/administration/audit-logs/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_staff_can_list_audit_logs(self):
        self.client.force_authenticate(self.staff)
        response = self.client.get("/api/v1/administration/audit-logs/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
