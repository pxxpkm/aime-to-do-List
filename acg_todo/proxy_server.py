#!/usr/bin/env python3
"""Local static + CORS image proxy for Flutter Web poster loading.

Serves build/web on 8080 and proxies Bangumi CDN images via:
  GET /proxy?url=<encoded-https-url>

Usage:
  cd C:\\todo\\acg_todo
  flutter build web --release
  python proxy_server.py
  # open http://127.0.0.1:8080
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

ALLOWED_HOST_SUFFIXES = (".bgm.tv",)
ALLOWED_HOSTS = frozenset({"bgm.tv", "lain.bgm.tv"})
DEFAULT_PORT = 8080
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Safari/537.36"
)


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


class CombinedHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        # Static assets also need CORS for Flutter web tooling edge cases.
        if not self.path.startswith("/proxy"):
            self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

    def do_OPTIONS(self) -> None:  # noqa: N802
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
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/proxy":
            self._handle_proxy(parsed)
            return
        super().do_GET()

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

        # Accept once-encoded or double-encoded values from browsers.
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
    parser = argparse.ArgumentParser(description="Flutter web static + Bangumi image proxy")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT)
    parser.add_argument(
        "--root",
        type=str,
        default=str(Path(__file__).resolve().parent / "build" / "web"),
        help="Document root (default: build/web next to this script)",
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

    os.chdir(root)
    handler = CombinedHandler
    server = ThreadingHTTPServer(("127.0.0.1", args.port), handler)
    print(f"Serving {root}")
    print(f"  app:   http://127.0.0.1:{args.port}/")
    print(f"  proxy: http://127.0.0.1:{args.port}/proxy?url=<encoded>")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down")
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
