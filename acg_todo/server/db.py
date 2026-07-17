"""SQLite library store for local 8080 server."""

from __future__ import annotations

import json
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 2
SYSTEM_COMPLETED_ID = "folder_system_completed"
SYSTEM_COMPLETED_NAME = "已完成"


def _utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _dumps(obj: Any) -> str:
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"))


def _loads(raw: str) -> Any:
    return json.loads(raw)


class LibraryDB:
    def __init__(self, path: Path) -> None:
        self.path = path.resolve()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self.init_schema()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.path, timeout=30, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        return conn

    def init_schema(self) -> None:
        with self._lock:
            with self._connect() as conn:
                conn.executescript(
                    """
                    CREATE TABLE IF NOT EXISTS meta (
                      key   TEXT PRIMARY KEY,
                      value TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS folders (
                      id         TEXT PRIMARY KEY,
                      payload    TEXT NOT NULL,
                      sort_order INTEGER NOT NULL DEFAULT 0
                    );
                    CREATE TABLE IF NOT EXISTS items (
                      id         TEXT PRIMARY KEY,
                      payload    TEXT NOT NULL,
                      sort_order INTEGER NOT NULL DEFAULT 0,
                      updated_at TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS settings (
                      key   TEXT PRIMARY KEY,
                      value TEXT NOT NULL
                    );
                    CREATE TABLE IF NOT EXISTS notifications (
                      id         TEXT PRIMARY KEY,
                      payload    TEXT NOT NULL,
                      created_at TEXT NOT NULL
                    );
                    """
                )
                conn.execute(
                    "INSERT OR IGNORE INTO meta(key, value) VALUES(?, ?)",
                    ("schema_version", str(SCHEMA_VERSION)),
                )
                conn.execute(
                    "UPDATE meta SET value = ? WHERE key = ?",
                    (str(SCHEMA_VERSION), "schema_version"),
                )
                self._ensure_system_folder(conn)
                conn.commit()

    def _ensure_system_folder(self, conn: sqlite3.Connection) -> None:
        row = conn.execute(
            "SELECT id FROM folders WHERE id = ?",
            (SYSTEM_COMPLETED_ID,),
        ).fetchone()
        if row:
            return
        payload = {
            "id": SYSTEM_COMPLETED_ID,
            "name": SYSTEM_COMPLETED_NAME,
            "sortOrder": 9999,
            "colorValue": 0xFF4ADE80,
            "createdAt": _utc_now(),
        }
        conn.execute(
            "INSERT INTO folders(id, payload, sort_order) VALUES(?, ?, ?)",
            (SYSTEM_COMPLETED_ID, _dumps(payload), 9999),
        )

    def health(self) -> dict[str, Any]:
        with self._lock:
            with self._connect() as conn:
                item_count = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
                folder_count = conn.execute("SELECT COUNT(*) AS c FROM folders").fetchone()["c"]
                ver = conn.execute(
                    "SELECT value FROM meta WHERE key = ?",
                    ("schema_version",),
                ).fetchone()
                return {
                    "ok": True,
                    "schemaVersion": int(ver["value"]) if ver else SCHEMA_VERSION,
                    "dbPath": str(self.path),
                    "itemCount": int(item_count),
                    "folderCount": int(folder_count),
                }

    # ── library snapshot ──

    def get_library(self) -> dict[str, Any]:
        with self._lock:
            with self._connect() as conn:
                folders = self._list_folders(conn)
                items = self._list_items(conn)
                settings = self._get_settings(conn)
                return {
                    "format": "acg_todo_backup",
                    "version": 1,
                    "exportedAt": _utc_now(),
                    "appVersion": "server",
                    "folders": folders,
                    "items": items,
                    "settings": settings,
                }

    def put_library(self, body: dict[str, Any]) -> dict[str, Any]:
        folders = body.get("folders")
        items = body.get("items")
        if not isinstance(folders, list) or not isinstance(items, list):
            raise ValueError("library body requires folders and items arrays")

        with self._lock:
            with self._connect() as conn:
                conn.execute("DELETE FROM items")
                conn.execute("DELETE FROM folders")
                for f in folders:
                    if not isinstance(f, dict):
                        continue
                    fid = str(f.get("id") or "")
                    if not fid:
                        continue
                    sort_order = int(f.get("sortOrder") or 0)
                    conn.execute(
                        "INSERT INTO folders(id, payload, sort_order) VALUES(?, ?, ?)",
                        (fid, _dumps(f), sort_order),
                    )
                for it in items:
                    if not isinstance(it, dict):
                        continue
                    iid = str(it.get("id") or "")
                    if not iid:
                        continue
                    sort_order = int(it.get("sortOrder") or 0)
                    conn.execute(
                        "INSERT INTO items(id, payload, sort_order, updated_at) "
                        "VALUES(?, ?, ?, ?)",
                        (iid, _dumps(it), sort_order, _utc_now()),
                    )
                settings = body.get("settings")
                if isinstance(settings, dict):
                    conn.execute(
                        "INSERT OR REPLACE INTO settings(key, value) VALUES(?, ?)",
                        ("bundle", _dumps(settings)),
                    )
                self._ensure_system_folder(conn)
                conn.commit()
                item_count = conn.execute("SELECT COUNT(*) AS c FROM items").fetchone()["c"]
                folder_count = conn.execute("SELECT COUNT(*) AS c FROM folders").fetchone()["c"]
                return {
                    "ok": True,
                    "itemCount": int(item_count),
                    "folderCount": int(folder_count),
                }

    # ── items ──

    def list_items(self) -> list[dict[str, Any]]:
        with self._lock:
            with self._connect() as conn:
                return self._list_items(conn)

    def get_item(self, item_id: str) -> dict[str, Any] | None:
        with self._lock:
            with self._connect() as conn:
                row = conn.execute(
                    "SELECT payload FROM items WHERE id = ?",
                    (item_id,),
                ).fetchone()
                if not row:
                    return None
                return _loads(row["payload"])

    def put_item(self, item_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(payload, dict):
            raise ValueError("item body must be a JSON object")
        payload = dict(payload)
        payload["id"] = item_id
        sort_order = int(payload.get("sortOrder") or 0)
        with self._lock:
            with self._connect() as conn:
                self._upsert_item(conn, item_id, payload, sort_order)
                conn.commit()
                return payload

    def put_items_batch(self, items: list[Any]) -> dict[str, Any]:
        if not isinstance(items, list):
            raise ValueError("items must be an array")
        count = 0
        with self._lock:
            with self._connect() as conn:
                for it in items:
                    if not isinstance(it, dict):
                        continue
                    payload = dict(it)
                    iid = str(payload.get("id") or "")
                    if not iid:
                        continue
                    payload["id"] = iid
                    sort_order = int(payload.get("sortOrder") or 0)
                    self._upsert_item(conn, iid, payload, sort_order)
                    count += 1
                conn.commit()
        return {"ok": True, "count": count}

    def _upsert_item(
        self,
        conn: sqlite3.Connection,
        item_id: str,
        payload: dict[str, Any],
        sort_order: int,
    ) -> None:
        conn.execute(
            "INSERT INTO items(id, payload, sort_order, updated_at) VALUES(?, ?, ?, ?) "
            "ON CONFLICT(id) DO UPDATE SET "
            "payload=excluded.payload, "
            "sort_order=excluded.sort_order, "
            "updated_at=excluded.updated_at",
            (item_id, _dumps(payload), sort_order, _utc_now()),
        )

    def delete_item(self, item_id: str) -> bool:
        with self._lock:
            with self._connect() as conn:
                cur = conn.execute("DELETE FROM items WHERE id = ?", (item_id,))
                conn.commit()
                return cur.rowcount > 0

    # ── folders ──

    def list_folders(self) -> list[dict[str, Any]]:
        with self._lock:
            with self._connect() as conn:
                return self._list_folders(conn)

    def get_folder(self, folder_id: str) -> dict[str, Any] | None:
        with self._lock:
            with self._connect() as conn:
                row = conn.execute(
                    "SELECT payload FROM folders WHERE id = ?",
                    (folder_id,),
                ).fetchone()
                if not row:
                    return None
                return _loads(row["payload"])

    def put_folder(self, folder_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(payload, dict):
            raise ValueError("folder body must be a JSON object")
        payload = dict(payload)
        payload["id"] = folder_id
        if folder_id == SYSTEM_COMPLETED_ID:
            payload["name"] = SYSTEM_COMPLETED_NAME
            payload["sortOrder"] = 9999
        sort_order = int(payload.get("sortOrder") or 0)
        with self._lock:
            with self._connect() as conn:
                conn.execute(
                    "INSERT INTO folders(id, payload, sort_order) VALUES(?, ?, ?) "
                    "ON CONFLICT(id) DO UPDATE SET "
                    "payload=excluded.payload, sort_order=excluded.sort_order",
                    (folder_id, _dumps(payload), sort_order),
                )
                conn.commit()
                return payload

    def put_folders_batch(self, folders: list[Any]) -> dict[str, Any]:
        if not isinstance(folders, list):
            raise ValueError("folders must be an array")
        count = 0
        with self._lock:
            with self._connect() as conn:
                for f in folders:
                    if not isinstance(f, dict):
                        continue
                    payload = dict(f)
                    fid = str(payload.get("id") or "")
                    if not fid:
                        continue
                    payload["id"] = fid
                    if fid == SYSTEM_COMPLETED_ID:
                        payload["name"] = SYSTEM_COMPLETED_NAME
                        payload["sortOrder"] = 9999
                    sort_order = int(payload.get("sortOrder") or 0)
                    conn.execute(
                        "INSERT INTO folders(id, payload, sort_order) VALUES(?, ?, ?) "
                        "ON CONFLICT(id) DO UPDATE SET "
                        "payload=excluded.payload, sort_order=excluded.sort_order",
                        (fid, _dumps(payload), sort_order),
                    )
                    count += 1
                conn.commit()
        return {"ok": True, "count": count}

    def delete_folder(self, folder_id: str) -> None:
        if folder_id == SYSTEM_COMPLETED_ID:
            raise ValueError("cannot delete system folder")
        with self._lock:
            with self._connect() as conn:
                # Clear folderId on items that referenced this folder
                rows = conn.execute("SELECT id, payload FROM items").fetchall()
                for row in rows:
                    payload = _loads(row["payload"])
                    changed = False
                    if payload.get("folderId") == folder_id:
                        payload["folderId"] = None
                        changed = True
                    if payload.get("previousFolderId") == folder_id:
                        payload["previousFolderId"] = None
                        changed = True
                    if changed:
                        conn.execute(
                            "UPDATE items SET payload = ?, updated_at = ? WHERE id = ?",
                            (_dumps(payload), _utc_now(), row["id"]),
                        )
                conn.execute("DELETE FROM folders WHERE id = ?", (folder_id,))
                conn.commit()

    # ── settings ──

    def get_settings(self) -> dict[str, Any]:
        with self._lock:
            with self._connect() as conn:
                return self._get_settings(conn)

    def put_settings(self, settings: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(settings, dict):
            raise ValueError("settings body must be a JSON object")
        with self._lock:
            with self._connect() as conn:
                conn.execute(
                    "INSERT OR REPLACE INTO settings(key, value) VALUES(?, ?)",
                    ("bundle", _dumps(settings)),
                )
                conn.commit()
                return settings

    # ── notifications ──

    def list_notifications(self) -> list[dict[str, Any]]:
        with self._lock:
            with self._connect() as conn:
                return self._list_notifications(conn)

    def put_notifications(self, notifications: list[Any]) -> dict[str, Any]:
        if not isinstance(notifications, list):
            raise ValueError("notifications must be an array")
        with self._lock:
            with self._connect() as conn:
                conn.execute("DELETE FROM notifications")
                for raw in notifications:
                    if not isinstance(raw, dict):
                        continue
                    nid = raw.get("id")
                    if not isinstance(nid, str) or not nid:
                        continue
                    created = raw.get("createdAt") or raw.get("scheduledAt") or _utc_now()
                    if not isinstance(created, str):
                        created = _utc_now()
                    conn.execute(
                        "INSERT OR REPLACE INTO notifications(id, payload, created_at) "
                        "VALUES(?, ?, ?)",
                        (nid, _dumps(raw), created),
                    )
                conn.commit()
                items = self._list_notifications(conn)
                return {"notifications": items, "count": len(items)}

    def clear_notifications(self) -> dict[str, Any]:
        with self._lock:
            with self._connect() as conn:
                conn.execute("DELETE FROM notifications")
                conn.commit()
                return {"ok": True, "count": 0}

    # ── internals ──

    def _list_notifications(self, conn: sqlite3.Connection) -> list[dict[str, Any]]:
        rows = conn.execute(
            "SELECT payload FROM notifications ORDER BY created_at DESC, id DESC"
        ).fetchall()
        return [_loads(r["payload"]) for r in rows]

    def _list_items(self, conn: sqlite3.Connection) -> list[dict[str, Any]]:
        rows = conn.execute(
            "SELECT payload FROM items ORDER BY sort_order ASC, id ASC"
        ).fetchall()
        return [_loads(r["payload"]) for r in rows]

    def _list_folders(self, conn: sqlite3.Connection) -> list[dict[str, Any]]:
        rows = conn.execute(
            "SELECT payload FROM folders ORDER BY sort_order ASC, id ASC"
        ).fetchall()
        return [_loads(r["payload"]) for r in rows]

    def _get_settings(self, conn: sqlite3.Connection) -> dict[str, Any]:
        row = conn.execute(
            "SELECT value FROM settings WHERE key = ?",
            ("bundle",),
        ).fetchone()
        if not row:
            return {}
        data = _loads(row["value"])
        return data if isinstance(data, dict) else {}
