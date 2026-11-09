import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ("football", "0001_initial"),
    ]

    operations = [
        migrations.CreateModel(
            name="SavedPlayerComparison",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("season", models.PositiveSmallIntegerField()),
                ("left_player_id", models.PositiveIntegerField()),
                ("right_player_id", models.PositiveIntegerField()),
                ("left_name", models.CharField(max_length=128)),
                ("right_name", models.CharField(max_length=128)),
                ("left_photo", models.URLField(blank=True)),
                ("right_photo", models.URLField(blank=True)),
                ("snapshot", models.JSONField(blank=True, default=dict)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="player_comparisons",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]
