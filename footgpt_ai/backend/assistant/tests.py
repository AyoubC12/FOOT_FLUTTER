from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from assistant.models import ChatMessage
from assistant.services.chat_service import AssistantConfigError
from assistant.services.football_tools import get_formation_guide

User = get_user_model()


class AssistantApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="fan",
            email="fan@example.com",
            password="StrongPass123",
        )
        self.client.force_authenticate(self.user)

    def test_chat_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.post(reverse("assistant-chat"), {"message": "hi"})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_empty_message_is_rejected(self):
        response = self.client.post(reverse("assistant-chat"), {"message": "   "})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("assistant.views.AssistantChatService.reply", return_value="4-3-3 is a general shape.")
    def test_chat_stores_history(self, _mock_reply):
        response = self.client.post(
            reverse("assistant-chat"),
            {"message": "Explain a 4-3-3"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ChatMessage.objects.filter(user=self.user).count(), 2)
        self.assertIn("assistant", response.data)
        history = self.client.get(reverse("chat-message-list"))
        self.assertEqual(history.data["count"], 2)

    @patch(
        "assistant.views.AssistantChatService.reply",
        side_effect=AssistantConfigError("The assistant is not configured."),
    )
    def test_missing_openai_key_returns_503(self, _mock_reply):
        response = self.client.post(
            reverse("assistant-chat"),
            {"message": "Who wins?"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)

    def test_suggestions(self):
        response = self.client.get(reverse("assistant-suggestions"))
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(response.data["results"]), 3)

    def test_formation_notes_are_verified_only(self):
        known = get_formation_guide("4-3-3")
        self.assertTrue(known["available"])
        missing = get_formation_guide("9-9-9")
        self.assertFalse(missing["available"])
