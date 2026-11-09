from __future__ import annotations

import json
import logging

from django.conf import settings

from assistant.services.chat_service import AssistantConfigError, AssistantProviderError
from tactics.services.analysis import structural_suggestions, summarize_board

logger = logging.getLogger(__name__)

MAX_COMPLETION_TOKENS = 420

SYSTEM_PROMPT = """You are FootGPT's tactics coach.

Rules:
- Comment only on the board JSON and the verified formation notes provided.
- Never invent live scores, xG, player ratings, or a club's current lineup.
- If a formation note is missing, say so.
- Suggestions are general coaching ideas for this diagram, not match facts.
- Keep the reply under 180 words.
"""


def build_suggestion(formation: str, players: list[dict], compare: dict | None) -> dict:
    left = summarize_board(formation, players)
    right = None
    if compare:
        right = summarize_board(compare["formation"], compare["players"])
    tips = structural_suggestions(left, right)
    payload = {
        "summary": left,
        "compare_summary": right,
        "structural_tips": tips,
        "disclaimer": (
            "General coaching notes for this diagram only. "
            "Not live tracking and not a claim about a real match."
        ),
    }
    try:
        payload["suggestion"] = _openai_suggestion(left, right, tips)
        payload["source"] = "openai"
    except (AssistantConfigError, AssistantProviderError):
        payload["suggestion"] = " ".join(tips[:4])
        payload["source"] = "verified_notes"
    return payload


def _openai_suggestion(left: dict, right: dict | None, tips: list[str]) -> str:
    api_key = getattr(settings, "OPENAI_API_KEY", "") or ""
    if not api_key:
        raise AssistantConfigError("The assistant is not configured.")
    try:
        from openai import OpenAI
    except ImportError as exc:  # pragma: no cover
        raise AssistantProviderError("OpenAI client is not installed.") from exc

    user_payload = {
        "board": left,
        "compare": right,
        "structural_tips": tips,
    }
    client = OpenAI(api_key=api_key)
    model = getattr(settings, "OPENAI_MODEL", "gpt-4o-mini")
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": json.dumps(user_payload),
                },
            ],
            max_tokens=MAX_COMPLETION_TOKENS,
            temperature=0.3,
        )
        text = (response.choices[0].message.content or "").strip()
        if not text:
            raise AssistantProviderError("The assistant returned an empty reply.")
        return text
    except AssistantProviderError:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.warning("Tactics OpenAI call failed: %s", exc.__class__.__name__)
        raise AssistantProviderError(
            "The assistant is temporarily unavailable. Try again shortly."
        ) from exc
