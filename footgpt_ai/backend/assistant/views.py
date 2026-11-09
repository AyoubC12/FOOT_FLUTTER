from drf_spectacular.utils import extend_schema
from rest_framework import mixins, status, viewsets
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.permissions import IsOwner
from assistant.models import ChatMessage, Conversation
from assistant.serializers import (
    ChatMessageSerializer,
    ChatRequestSerializer,
    ConversationSerializer,
)
from assistant.services.chat_service import (
    AssistantChatService,
    AssistantConfigError,
    AssistantProviderError,
)
from assistant.services.prompts import SUGGESTED_QUESTIONS
from assistant.throttles import ChatDailyThrottle, ChatRateThrottle


class ChatMessageViewSet(
    mixins.ListModelMixin,
    viewsets.GenericViewSet,
):
    queryset = ChatMessage.objects.all()
    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        qs = ChatMessage.objects.filter(user=self.request.user).order_by("-created_at")
        conversation_id = self.request.query_params.get("conversation")
        if conversation_id:
            qs = qs.filter(conversation_id=conversation_id)
        return qs


class ConversationViewSet(mixins.ListModelMixin, viewsets.GenericViewSet):
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Conversation.objects.filter(user=self.request.user)


class SuggestionsView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ChatRequestSerializer

    @extend_schema(responses={200: None}, tags=["assistant"])
    def get(self, request):
        return Response({"results": SUGGESTED_QUESTIONS})


class ChatView(GenericAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ChatRequestSerializer
    throttle_classes = [ChatRateThrottle, ChatDailyThrottle]

    @extend_schema(request=ChatRequestSerializer, tags=["assistant"])
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        message = serializer.validated_data["message"]
        conversation_id = serializer.validated_data.get("conversation_id")

        if conversation_id:
            conversation = Conversation.objects.filter(
                id=conversation_id, user=request.user
            ).first()
            if conversation is None:
                return Response(
                    {"detail": "Conversation not found."},
                    status=status.HTTP_404_NOT_FOUND,
                )
        else:
            conversation = (
                Conversation.objects.filter(user=request.user)
                .order_by("-updated_at")
                .first()
            )
            if conversation is None:
                conversation = Conversation.objects.create(
                    user=request.user,
                    title=message[:80],
                )

        ChatMessage.objects.create(
            user=request.user,
            conversation=conversation,
            role=ChatMessage.Role.USER,
            message=message,
        )
        try:
            reply = AssistantChatService().reply(
                user=request.user,
                conversation=conversation,
                user_text=message,
            )
        except AssistantConfigError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except AssistantProviderError as exc:
            return Response({"detail": exc.message}, status=exc.status_code)

        assistant_row = ChatMessage.objects.create(
            user=request.user,
            conversation=conversation,
            role=ChatMessage.Role.ASSISTANT,
            message=reply,
        )
        conversation.title = conversation.title or message[:80]
        conversation.save(update_fields=["title", "updated_at"])
        return Response(
            {
                "conversation_id": conversation.id,
                "user_message": message,
                "assistant": ChatMessageSerializer(assistant_row).data,
                "suggestions": SUGGESTED_QUESTIONS,
            },
            status=status.HTTP_201_CREATED,
        )
