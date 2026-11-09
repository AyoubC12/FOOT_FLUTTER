from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import EstimatePredictionView, PredictionViewSet

router = DefaultRouter()
router.register("", PredictionViewSet, basename="prediction")

urlpatterns = [
    path("estimate/", EstimatePredictionView.as_view(), name="prediction-estimate"),
    path("", include(router.urls)),
]
