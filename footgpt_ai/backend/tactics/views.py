from drf_spectacular.utils import extend_schema
from rest_framework import status, viewsets
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsOwner
from tactics.models import TacticalBoard
from tactics.serializers import (
    CompareRequestSerializer,
    SuggestRequestSerializer,
    TacticalBoardSerializer,
)
from tactics.services.suggest import build_suggestion
from tactics.throttles import TacticsSuggestThrottle


class TacticalBoardViewSet(viewsets.ModelViewSet):
    queryset = TacticalBoard.objects.all()
    serializer_class = TacticalBoardSerializer
    permission_classes = [IsAuthenticated, IsOwner]
    http_method_names = ["get", "post", "put", "patch", "delete", "head", "options"]

    def get_queryset(self):
        return TacticalBoard.objects.filter(user=self.request.user)


class TacticsSuggestView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SuggestRequestSerializer
    throttle_classes = [TacticsSuggestThrottle]

    @extend_schema(request=SuggestRequestSerializer, tags=["tactics"])
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        payload = build_suggestion(
            data["formation"],
            data["players"],
            data.get("compare"),
        )
        return Response(payload)


class TacticsCompareView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CompareRequestSerializer
    throttle_classes = [TacticsSuggestThrottle]

    @extend_schema(request=CompareRequestSerializer, tags=["tactics"])
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        left_id = serializer.validated_data["left_id"]
        right_id = serializer.validated_data["right_id"]
        boards = {
            board.id: board
            for board in TacticalBoard.objects.filter(
                user=request.user, id__in=[left_id, right_id]
            )
        }
        if left_id not in boards or right_id not in boards:
            return Response(
                {"detail": "One or both boards were not found."},
                status=status.HTTP_404_NOT_FOUND,
            )
        left = boards[left_id]
        right = boards[right_id]
        payload = build_suggestion(
            left.formation,
            left.players,
            {"formation": right.formation, "players": right.players},
        )
        payload["left"] = TacticalBoardSerializer(left).data
        payload["right"] = TacticalBoardSerializer(right).data
        return Response(payload)
