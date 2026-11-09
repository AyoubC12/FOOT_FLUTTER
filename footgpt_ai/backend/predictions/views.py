from drf_spectacular.utils import extend_schema
from rest_framework import status, viewsets
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsOwner

from .engine.predict import PredictionEngine
from .models import HistoricalMatch, Prediction
from .serializers import EstimateRequestSerializer, PredictionSerializer


class PredictionViewSet(viewsets.ModelViewSet):
    queryset = Prediction.objects.all()
    serializer_class = PredictionSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    http_method_names = ["get", "post", "head", "options"]

    def get_queryset(self):
        return Prediction.objects.filter(user=self.request.user)


class EstimatePredictionView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = EstimateRequestSerializer

    @extend_schema(request=EstimateRequestSerializer, responses={201: PredictionSerializer})
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        engine = PredictionEngine()
        result = engine.estimate(
            home_id=data["home_team_id"],
            away_id=data["away_team_id"],
            kickoff_at=data.get("kickoff_at"),
            league_id=data.get("league_id"),
            season=data.get("season"),
        )
        home_name = data.get("home_team") or _team_name(data["home_team_id"], True)
        away_name = data.get("away_team") or _team_name(data["away_team_id"], False)
        prediction = Prediction.objects.create(
            user=request.user,
            home_team=home_name,
            away_team=away_name,
            home_team_id=data["home_team_id"],
            away_team_id=data["away_team_id"],
            fixture_id=data.get("fixture_id"),
            league_id=data.get("league_id"),
            season=data.get("season"),
            predicted_result=result.predicted_result,
            probabilities=result.percentages,
            explanation=result.explanation,
            data_quality=result.data_quality,
            model_name=result.model_name,
            feature_snapshot=result.features,
        )
        payload = PredictionSerializer(prediction, context={"request": request}).data
        payload["metrics"] = result.metrics
        payload["disclaimer"] = (
            "This is a probabilistic estimate, not a guaranteed outcome."
        )
        return Response(payload, status=status.HTTP_201_CREATED)


def _team_name(team_id: int, home: bool) -> str:
    match = (
        HistoricalMatch.objects.filter(home_team_id=team_id).order_by("-kickoff_at").first()
        if home
        else HistoricalMatch.objects.filter(away_team_id=team_id).order_by("-kickoff_at").first()
    )
    if match:
        return match.home_team_name if home else match.away_team_name
    either = HistoricalMatch.objects.filter(
        home_team_id=team_id
    ).order_by("-kickoff_at").first() or HistoricalMatch.objects.filter(
        away_team_id=team_id
    ).order_by("-kickoff_at").first()
    if either:
        return (
            either.home_team_name
            if either.home_team_id == team_id
            else either.away_team_name
        )
    return f"Team {team_id}"
