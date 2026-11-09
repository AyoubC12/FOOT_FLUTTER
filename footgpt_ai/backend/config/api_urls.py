"""Canonical REST routes under /api/v1/ (also mounted at /api/ for compatibility)."""

from django.urls import include, path

urlpatterns = [
    path("auth/", include("accounts.urls")),
    path("football/", include("football.urls")),
    path("predictions/", include("predictions.urls")),
    path("assistant/", include("assistant.urls")),
    path("tactics/", include("tactics.urls")),
    path("favorites/", include("favorites.urls")),
    path("notifications/", include("notifications.urls")),
    path("administration/", include("administration.urls")),
]
