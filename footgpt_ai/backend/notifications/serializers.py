from rest_framework import serializers

from .models import DeviceToken


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ("id", "token", "platform", "is_active", "created_at", "updated_at")
        read_only_fields = ("id", "is_active", "created_at", "updated_at")

    def create(self, validated_data):
        user = self.context["request"].user
        token = validated_data["token"]
        platform = validated_data["platform"]
        device, _created = DeviceToken.objects.update_or_create(
            token=token,
            defaults={"user": user, "platform": platform, "is_active": True},
        )
        return device
