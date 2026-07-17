#!/usr/bin/env python3
"""Local static + CORS image proxy + SQLite library API for Flutter Web.

Serves build/web on 8080, proxies Bangumi CDN images, and exposes:
  GET  /api/health
  GET/PUT /api/v1/library
  GET/PUT/DELETE /api/v1/items[/{id}]
  PUT /api/v1/items:batch
  GET/PUT/DELETE /api/v1/folders[/{id}]
  PUT /api/v1/folders:batch
  GET/PUT /api/v1/settings
  GET/PUT/DELETE /api/v1/notifications

Usage:
  cd C:\\todo\\acg_todo
  flutter build web --release
  python proxy_server.py
  # open http://127.0.0.1:8080
  # health: http://127.0.0.1:8080/api/health
"""

from __future__ import annotations

import argparse
import mimetypes
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from server.api import handle_api
from server.db import LibraryDB

ALLOWED_HOST_SUFFIXES = (".bgm.tv",)
ALLOWED_HOSTS = frozenset({"bgm.tv", "lain.bgm.tv"})
DEFAULT_PORT = 8080
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)

# Set in main() before serving.
DB: LibraryDB | None = None
PROJECT_ROOT = Path(__file__).resolve().parent


def is_allowed_target(url: str) -> bool:
    try:
        parsed = urllib.parse.urlparse(url)
    except Exception:
        return False
    if parsed.scheme not in ("http", "https"):
        return False
    host = (parsed.hostname or "").lower()
    if not host:
        return False
    if host in ALLOWED_HOSTS:
        return True
    return any(host.endswith(suffix) for suffix in ALLOWED_HOST_SUFFIXES)


def _cors_api_headers(handler: SimpleHTTPRequestHandler) -> None:
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.send_header("Access-Control-Allow-Methods", "GET, PUT, DELETE, OPTIONS")
    handler.send_header("Access-Control-Allow-Headers", "Content-Type")
    handler.send_header("Access-Control-Max-Age", "86400")


class CombinedHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        if not self.path.startswith("/proxy") and not self.path.startswith("/api"):
            self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def do_OPTIONS(self) -> None:  # noqa: N802
        if self.path.startswith("/api"):
            self.send_response(204)
            _cors_api_headers(self)
            self.end_headers()
            return
        if self.path.startswith("/proxy"):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "*")
            self.send_header("Access-Control-Max-Age", "86400")
            self.end_headers()
            return
        self.send_error(404, "Not Found")

    def do_GET(self) -> None:  # noqa: N802
        if self._try_api("GET"):
            return
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/proxy":
            self._handle_proxy(parsed)
            return
        super().do_GET()

    def do_PUT(self) -> None:  # noqa: N802
        if self._try_api("PUT"):
            return
        self.send_error(404, "Not Found")

    def do_DELETE(self) -> None:  # noqa: N802
        if self._try_api("DELETE"):
            return
        self.send_error(404, "Not Found")

    def _try_api(self, method: str) -> bool:
        if DB is None:
            return False
        parsed = urllib.parse.urlparse(self.path)
        if not parsed.path.startswith("/api"):
            return False
        result = handle_api(self, method, self.path, DB)
        if result is None:
            return False
        status, body, content_type = result
        self.send_response(status)
        _cors_api_headers(self)
        if content_type:
            self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body and self.command != "HEAD":
            self.wfile.write(body)
        return True

    def _handle_proxy(self, parsed: urllib.parse.ParseResult) -> None:
        qs = urllib.parse.parse_qs(parsed.query)
        targets = qs.get("url") or []
        if not targets:
            self.send_error(400, "Missing url query parameter")
            return

        target = targets[0].strip()
        if not target:
            self.send_error(400, "Empty url query parameter")
            return

        for _ in range(2):
            decoded = urllib.parse.unquote(target)
            if decoded == target:
                break
            target = decoded

        if not is_allowed_target(target):
            self.send_error(403, "Host not allowed")
            return

        req = urllib.request.Request(
            target,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
                "Referer": "https://bgm.tv/",
            },
            method="GET",
        )

        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                body = resp.read()
                content_type = resp.headers.get("Content-Type")
                status = getattr(resp, "status", 200) or 200
        except urllib.error.HTTPError as exc:
            body = exc.read() if exc.fp else b""
            content_type = exc.headers.get("Content-Type") if exc.headers else None
            status = exc.code
        except urllib.error.URLError as exc:
            self.send_error(502, f"Upstream error: {exc.reason}")
            return
        except Exception as exc:  # noqa: BLE001
            self.send_error(502, f"Proxy failure: {exc}")
            return

        if not content_type:
            guessed, _ = mimetypes.guess_type(urllib.parse.urlparse(target).path)
            content_type = guessed or "application/octet-stream"

        self.send_response(status)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "public, max-age=86400")
        self.end_headers()
        if self.command != "HEAD" and body:
            self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def main() -> int:
    global DB

    parser = argparse.ArgumentParser(
        description="Flutter web static + Bangumi proxy + SQLite library API"
    )
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument(
        "--root",
        type=str,
        default=str(PROJECT_ROOT / "build" / "web"),
        help="Document root (default: build/web next to this script)",
    )
    parser.add_argument(
        "--db",
        type=str,
        default=str(PROJECT_ROOT / "data" / "library.db"),
        help="SQLite database path (default: data/library.db)",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(
            f"ERROR: document root not found: {root}\n"
            "Run: flutter build web --release",
            file=sys.stderr,
        )
        return 1

    db_path = Path(args.db).resolve()
    DB = LibraryDB(db_path)

    os.chdir(root)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), CombinedHandler)
    print(f"Serving {root}")
    print(f"  app:    http://127.0.0.1:{args.port}/")
    print(f"  proxy:  http://127.0.0.1:{args.port}/proxy?url=<encoded>")
    print(f"  api:    http://127.0.0.1:{args.port}/api/health")
    print(f"  db:     {db_path}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
