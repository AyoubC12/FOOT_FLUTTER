from __future__ import annotations

import io
from pathlib import Path

import requests
from django.conf import settings
from django.core.files.base import ContentFile
from PIL import Image


def media_relative_path(kind: str, external_id: str) -> str:
    safe_id = str(external_id).strip()
    return f"football/{kind}/{safe_id}.jpg"


def to_jpeg_bytes(payload: bytes) -> bytes:
    image = Image.open(io.BytesIO(payload))
    if image.mode in {"RGBA", "LA", "P"}:
        converted = Image.new("RGB", image.size, (255, 255, 255))
        rgba = image.convert("RGBA")
        converted.paste(rgba, mask=rgba.split()[-1])
        image = converted
    elif image.mode != "RGB":
        image = image.convert("RGB")
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=90, optimize=True)
    return buffer.getvalue()


def download_jpeg(url: str, kind: str, external_id: str) -> str | None:
    """Store provider bytes as JPEG named by external_id. Never reuse another id."""
    if not url or not external_id:
        return None
    try:
        response = requests.get(url, timeout=15)
    except requests.RequestException:
        return None
    if response.status_code != 200 or not response.content:
        return None
    try:
        jpeg = to_jpeg_bytes(response.content)
    except Exception:
        return None
    relative = media_relative_path(kind, external_id)
    dest = Path(settings.MEDIA_ROOT) / relative
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(jpeg)
    return relative


def content_file(jpeg: bytes, kind: str, external_id: str) -> ContentFile:
    return ContentFile(jpeg, name=Path(media_relative_path(kind, external_id)).name)
