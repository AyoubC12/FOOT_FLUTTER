from django.contrib import admin

from .models import TacticalBoard


@admin.register(TacticalBoard)
class TacticalBoardAdmin(admin.ModelAdmin):
    list_display = ("name", "formation", "user", "updated_at")
    list_filter = ("formation",)
    search_fields = ("name", "user__email")
