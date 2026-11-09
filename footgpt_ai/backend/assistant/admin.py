from django.contrib import admin

from .models import ChatMessage, Conversation


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ("user", "title", "updated_at")
    search_fields = ("title", "user__email")


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ("user", "role", "conversation", "created_at")
    list_filter = ("role",)
    search_fields = ("message", "user__email")
