from rest_framework import serializers

from tactics.services.analysis import ALLOWED_FORMATIONS

from .models import TacticalBoard

MAX_PLAYERS = 11
MAX_NAME = 80


class PitchPlayerSerializer(serializers.Serializer):
    id = serializers.CharField(max_length=64)
    name = serializers.CharField(max_length=MAX_NAME)
    position = serializers.CharField(max_length=24)
    x = serializers.FloatField(min_value=0, max_value=1)
    y = serializers.FloatField(min_value=0, max_value=1)
    number = serializers.IntegerField(required=False, min_value=0, max_value=99)

    def validate_name(self, value: str) -> str:
        name = value.strip()
        if not name:
            raise serializers.ValidationError("Player name cannot be empty.")
        return name

    def validate_position(self, value: str) -> str:
        position = value.strip()
        if not position:
            raise serializers.ValidationError("Position cannot be empty.")
        return position


class TacticalBoardSerializer(serializers.ModelSerializer):
    players = PitchPlayerSerializer(many=True)

    class Meta:
        model = TacticalBoard
        fields = (
            "id",
            "name",
            "formation",
            "players",
            "notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_name(self, value: str) -> str:
        name = value.strip()
        if not name:
            raise serializers.ValidationError("Board name cannot be empty.")
        return name

    def validate_formation(self, value: str) -> str:
        formation = value.strip()
        if formation not in ALLOWED_FORMATIONS:
            raise serializers.ValidationError(
                "Formation must be 4-3-3, 4-4-2, 3-5-2 or 4-2-3-1."
            )
        return formation

    def validate_players(self, value: list) -> list:
        if not value:
            raise serializers.ValidationError("Add at least one player.")
        if len(value) > MAX_PLAYERS:
            raise serializers.ValidationError("A board can hold at most 11 players.")
        ids = [item["id"] for item in value]
        if len(ids) != len(set(ids)):
            raise serializers.ValidationError("Player ids must be unique.")
        return [dict(item) for item in value]

    def create(self, validated_data):
        return TacticalBoard.objects.create(
            user=self.context["request"].user,
            **validated_data,
        )


class BoardSnapshotSerializer(serializers.Serializer):
    formation = serializers.ChoiceField(choices=ALLOWED_FORMATIONS)
    players = PitchPlayerSerializer(many=True)

    def validate_players(self, value: list) -> list:
        if len(value) > MAX_PLAYERS:
            raise serializers.ValidationError("A board can hold at most 11 players.")
        return [dict(item) for item in value]


class SuggestRequestSerializer(BoardSnapshotSerializer):
    compare = BoardSnapshotSerializer(required=False)


class CompareRequestSerializer(serializers.Serializer):
    left_id = serializers.IntegerField(min_value=1)
    right_id = serializers.IntegerField(min_value=1)
