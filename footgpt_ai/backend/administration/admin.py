from django.contrib import admin

from .models import AuditLog


@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ("id", "actor", "action", "resource", "created_at")
    list_filter = ("action",)
    search_fields = ("resource", "actor__email")
    readonly_fields = ("actor", "action", "resource", "metadata", "created_at")
