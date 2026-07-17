"""JSON API routing for LibraryDB."""

from __future__ import annotations

import json
import re
from typing import Any
from urllib.parse import unquote, urlparse

from server.db import LibraryDB

_MAX_BODY = 10 * 1024 * 1024  # 10 MiB


class ApiError(Exception):
    def __init__(self, status: int, message: str) -> None:
        super().__init__(message)
        self.status = status
        self.message = message


def _json_bytes(obj: Any, status: int = 200) -> tuple[int, bytes, str]:
    body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
    return status, body, "application/json; charset=utf-8"


def _read_json_body(handler: Any) -> Any:
    length = int(handler.headers.get("Content-Length") or "0")
    if length < 0 or length > _MAX_BODY:
        raise ApiError(413, "request body too large")
    raw = handler.rfile.read(length) if length else b""
    if not raw:
        return None
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ApiError(400, f"invalid JSON: {exc}") from exc


def handle_api(
    handler: Any,
    method: str,
    path: str,
    db: LibraryDB,
) -> tuple[int, bytes, str] | None:
    """
    Handle /api/* requests.
    Returns (status, body, content_type) or None if not an API path.
    """
    parsed = urlparse(path)
    p = parsed.path
    if not p.startswith("/api"):
        return None

    try:
        return _dispatch(handler, method.upper(), p, db)
    except ApiError as exc:
        return _json_bytes({"error": exc.message}, exc.status)
    except ValueError as exc:
        return _json_bytes({"error": str(exc)}, 400)
    except Exception as exc:  # noqa: BLE001
        return _json_bytes({"error": f"server error: {exc}"}, 500)


def _dispatch(
    handler: Any,
    method: str,
    path: str,
    db: LibraryDB,
) -> tuple[int, bytes, str]:
    if path == "/api/health" and method == "GET":
        return _json_bytes(db.health())

    if path == "/api/v1/library":
        if method == "GET":
            return _json_bytes(db.get_library())
        if method == "PUT":
            body = _read_json_body(handler)
            if not isinstance(body, dict):
                raise ApiError(400, "library body must be a JSON object")
            return _json_bytes(db.put_library(body))

    if path == "/api/v1/items":
        if method == "GET":
            return _json_bytes({"items": db.list_items()})

    # Exact path before /items/{id} so "items:batch" is not treated as an id.
    if path == "/api/v1/items:batch" and method == "PUT":
        body = _read_json_body(handler)
        if not isinstance(body, dict):
            raise ApiError(400, "batch body must be a JSON object")
        items = body.get("items")
        if not isinstance(items, list):
            raise ApiError(400, "batch body requires items array")
        return _json_bytes(db.put_items_batch(items))

    m = re.fullmatch(r"/api/v1/items/([^/]+)", path)
    if m:
        item_id = unquote(m.group(1))
        if method == "GET":
            item = db.get_item(item_id)
            if item is None:
                raise ApiError(404, "item not found")
            return _json_bytes(item)
        if method == "PUT":
            body = _read_json_body(handler)
            if not isinstance(body, dict):
                raise ApiError(400, "item body must be a JSON object")
            return _json_bytes(db.put_item(item_id, body))
        if method == "DELETE":
            db.delete_item(item_id)
            return _json_bytes({"ok": True})

    if path == "/api/v1/folders":
        if method == "GET":
            return _json_bytes({"folders": db.list_folders()})

    if path == "/api/v1/folders:batch" and method == "PUT":
        body = _read_json_body(handler)
        if not isinstance(body, dict):
            raise ApiError(400, "batch body must be a JSON object")
        folders = body.get("folders")
        if not isinstance(folders, list):
            raise ApiError(400, "batch body requires folders array")
        return _json_bytes(db.put_folders_batch(folders))

    m = re.fullmatch(r"/api/v1/folders/([^/]+)", path)
    if m:
        folder_id = unquote(m.group(1))
        if method == "GET":
            folder = db.get_folder(folder_id)
            if folder is None:
                raise ApiError(404, "folder not found")
            return _json_bytes(folder)
        if method == "PUT":
            body = _read_json_body(handler)
            if not isinstance(body, dict):
                raise ApiError(400, "folder body must be a JSON object")
            return _json_bytes(db.put_folder(folder_id, body))
        if method == "DELETE":
            db.delete_folder(folder_id)
            return _json_bytes({"ok": True})

    if path == "/api/v1/settings":
        if method == "GET":
            return _json_bytes(db.get_settings())
        if method == "PUT":
            body = _read_json_body(handler)
            if not isinstance(body, dict):
                raise ApiError(400, "settings body must be a JSON object")
            return _json_bytes(db.put_settings(body))

    if path == "/api/v1/notifications":
        if method == "GET":
            return _json_bytes({"notifications": db.list_notifications()})
        if method == "PUT":
            body = _read_json_body(handler)
            if not isinstance(body, dict):
                raise ApiError(400, "notifications body must be a JSON object")
            items = body.get("notifications")
            if not isinstance(items, list):
                raise ApiError(400, "body requires notifications array")
            return _json_bytes(db.put_notifications(items))
        if method == "DELETE":
            return _json_bytes(db.clear_notifications())

    if method == "OPTIONS" and path.startswith("/api"):
        return 204, b"", "text/plain"

    raise ApiError(404, f"unknown API route: {method} {path}")
