from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import DeviceTokenViewSet

router = DefaultRouter()
router.register("devices", DeviceTokenViewSet, basename="notification-device")

urlpatterns = [
    path("", include(router.urls)),
]
