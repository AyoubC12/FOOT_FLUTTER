from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    email = models.EmailField(unique=True)
    profile_picture = models.ImageField(
        upload_to="profiles/",
        blank=True,
        null=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.email


class Favorite(models.Model):
    class ItemType(models.TextChoices):
        MATCH = "match", "Match"
        PLAYER = "player", "Player"
        TEAM = "team", "Team"
        LEAGUE = "league", "League"

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="favorites",
    )
    item_type = models.CharField(max_length=16, choices=ItemType.choices)
    item_external_id = models.CharField(max_length=64)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "item_type", "item_external_id"],
                name="unique_user_favorite_item",
            )
        ]

    def __str__(self) -> str:
        return f"{self.user_id}:{self.item_type}:{self.item_external_id}"
