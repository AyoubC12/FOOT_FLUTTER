from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import ChatMessageViewSet, ChatView, ConversationViewSet, SuggestionsView

router = DefaultRouter()
router.register("messages", ChatMessageViewSet, basename="chat-message")
router.register("conversations", ConversationViewSet, basename="conversation")

urlpatterns = [
    path("chat/", ChatView.as_view(), name="assistant-chat"),
    path("suggestions/", SuggestionsView.as_view(), name="assistant-suggestions"),
    path("", include(router.urls)),
]
