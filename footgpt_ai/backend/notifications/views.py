from rest_framework import mixins, viewsets
from rest_framework.permissions import IsAuthenticated

from accounts.permissions import IsOwner

from .models import DeviceToken
from .serializers import DeviceTokenSerializer


class DeviceTokenViewSet(
    mixins.CreateModelMixin,
    mixins.ListModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    serializer_class = DeviceTokenSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return DeviceToken.objects.filter(user=self.request.user, is_active=True)

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active", "updated_at"])
