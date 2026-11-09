from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import FavoriteViewSet

router = DefaultRouter()
router.register("", FavoriteViewSet, basename="favorites-v1")

urlpatterns = [
    path("", include(router.urls)),
]
