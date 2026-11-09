from __future__ import annotations

import json
import logging

from django.conf import settings

from assistant.models import ChatMessage, Conversation
from assistant.services.football_tools import TOOL_DEFINITIONS, dispatch_tool
from assistant.services.prompts import SYSTEM_PROMPT

logger = logging.getLogger(__name__)

MAX_HISTORY = 12
MAX_COMPLETION_TOKENS = 500
MAX_TOOL_ROUNDS = 3


class AssistantConfigError(Exception):
    pass


class AssistantProviderError(Exception):
    def __init__(self, message: str, status_code: int = 502):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class AssistantChatService:
    def reply(self, *, user, conversation: Conversation, user_text: str) -> str:
        api_key = getattr(settings, "OPENAI_API_KEY", "") or ""
        if not api_key:
            raise AssistantConfigError("The assistant is not configured.")

        recent = list(
            ChatMessage.objects.filter(conversation=conversation).order_by("-created_at")[
                : MAX_HISTORY + 1
            ]
        )
        recent.reverse()
        if recent and recent[-1].role == ChatMessage.Role.USER:
            recent = recent[:-1]
        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
        for item in recent:
            if item.role in {ChatMessage.Role.USER, ChatMessage.Role.ASSISTANT}:
                messages.append({"role": item.role, "content": item.message})
        messages.append({"role": "user", "content": user_text})

        try:
            from openai import OpenAI
        except ImportError as exc:  # pragma: no cover
            raise AssistantProviderError("OpenAI client is not installed.") from exc

        client = OpenAI(api_key=api_key)
        model = getattr(settings, "OPENAI_MODEL", "gpt-4o-mini")

        try:
            for _ in range(MAX_TOOL_ROUNDS + 1):
                response = client.chat.completions.create(
                    model=model,
                    messages=messages,
                    tools=TOOL_DEFINITIONS,
                    tool_choice="auto",
                    max_tokens=MAX_COMPLETION_TOKENS,
                    temperature=0.3,
                )
                choice = response.choices[0]
                message = choice.message
                if choice.finish_reason == "tool_calls" or message.tool_calls:
                    messages.append(
                        {
                            "role": "assistant",
                            "content": message.content or "",
                            "tool_calls": [
                                {
                                    "id": call.id,
                                    "type": "function",
                                    "function": {
                                        "name": call.function.name,
                                        "arguments": call.function.arguments,
                                    },
                                }
                                for call in message.tool_calls
                            ],
                        }
                    )
                    for call in message.tool_calls:
                        try:
                            arguments = json.loads(call.function.arguments or "{}")
                        except json.JSONDecodeError:
                            arguments = {}
                        result = dispatch_tool(call.function.name, arguments, user)
                        messages.append(
                            {
                                "role": "tool",
                                "tool_call_id": call.id,
                                "content": json.dumps(result),
                            }
                        )
                    continue
                text = (message.content or "").strip()
                if not text:
                    raise AssistantProviderError("The assistant returned an empty reply.")
                return text
        except AssistantProviderError:
            raise
        except Exception as exc:  # noqa: BLE001
            logger.warning("OpenAI chat failed: %s", exc.__class__.__name__)
            raise AssistantProviderError(
                "The assistant is temporarily unavailable. Try again shortly."
            ) from exc

        raise AssistantProviderError("The assistant could not complete that request.")
