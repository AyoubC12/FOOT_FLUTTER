from rest_framework import serializers

from .models import ChatMessage, Conversation

MAX_MESSAGE_LENGTH = 2000


class ChatMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatMessage
        fields = ("id", "conversation", "role", "message", "created_at")
        read_only_fields = ("id", "conversation", "role", "created_at")

    def validate_message(self, value: str) -> str:
        text = value.strip()
        if not text:
            raise serializers.ValidationError("Message cannot be empty.")
        if len(text) > MAX_MESSAGE_LENGTH:
            raise serializers.ValidationError("Message is too long.")
        return text

    def create(self, validated_data):
        return ChatMessage.objects.create(
            user=self.context["request"].user,
            role=ChatMessage.Role.USER,
            **validated_data,
        )


class ChatRequestSerializer(serializers.Serializer):
    message = serializers.CharField(max_length=MAX_MESSAGE_LENGTH)
    conversation_id = serializers.IntegerField(required=False, min_value=1)

    def validate_message(self, value: str) -> str:
        text = value.strip()
        if not text:
            raise serializers.ValidationError("Message cannot be empty.")
        return text


class ConversationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conversation
        fields = ("id", "title", "created_at", "updated_at")
        read_only_fields = fields
