from django.conf import settings
from django.db import models


class DeviceToken(models.Model):
    class Platform(models.TextChoices):
        IOS = "ios", "iOS"
        ANDROID = "android", "Android"
        WEB = "web", "Web"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.CharField(max_length=512)
    platform = models.CharField(max_length=16, choices=Platform.choices)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        constraints = [
            models.UniqueConstraint(fields=["token"], name="unique_device_token"),
        ]
        indexes = [
            models.Index(fields=["user", "is_active"], name="idx_device_user_active"),
        ]

    def __str__(self) -> str:
        return f"{self.user_id}:{self.platform}"


class NotificationLog(models.Model):
    """Outbound push attempts. Payload must never store provider secrets."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_logs",
    )
    title = models.CharField(max_length=120)
    body = models.CharField(max_length=500)
    success = models.BooleanField(default=False)
    error_code = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "created_at"], name="idx_notif_user_created"),
        ]
