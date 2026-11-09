from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import TacticalBoardViewSet, TacticsCompareView, TacticsSuggestView

router = DefaultRouter()
router.register("boards", TacticalBoardViewSet, basename="tactical-board")

urlpatterns = [
    path("suggest/", TacticsSuggestView.as_view(), name="tactics-suggest"),
    path("compare/", TacticsCompareView.as_view(), name="tactics-compare"),
    path("", include(router.urls)),
]
