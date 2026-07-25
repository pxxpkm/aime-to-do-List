/**
 * Cloudflare Pages Function: Bangumi poster CORS proxy.
 * Route: GET /proxy?url=<encoded https url>
 *
 * Security: only bgm.tv / lain.bgm.tv / *.bgm.tv (same as proxy_server.py).
 * Never fetch arbitrary hosts (SSRF / open proxy).
 */

const ALLOWED_HOSTS = new Set(["bgm.tv", "lain.bgm.tv"]);
const ALLOWED_SUFFIX = ".bgm.tv";
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

function isAllowedTarget(raw) {
  try {
    const u = new URL(raw);
    if (u.protocol !== "http:" && u.protocol !== "https:") return false;
    const host = (u.hostname || "").toLowerCase();
    if (!host) return false;
    if (ALLOWED_HOSTS.has(host)) return true;
    return host.endsWith(ALLOWED_SUFFIX);
  } catch {
    return false;
  }
}

function decodeUrlParam(raw) {
  let target = raw.trim();
  for (let i = 0; i < 2; i++) {
    try {
      const d = decodeURIComponent(target);
      if (d === target) break;
      target = d;
    } catch {
      break;
    }
  }
  return target;
}

export async function onRequestOptions() {
  return new Response(null, {
    status: 204,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, OPTIONS, HEAD",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Max-Age": "86400",
    },
  });
}

export async function onRequestGet(context) {
  return handleProxy(context.request);
}

export async function onRequestHead(context) {
  return handleProxy(context.request);
}

async function handleProxy(request) {
  const incoming = new URL(request.url);
  const raw = incoming.searchParams.get("url");
  if (!raw) {
    return new Response("Missing url query parameter", { status: 400 });
  }

  const target = decodeUrlParam(raw);
  if (!target) {
    return new Response("Empty url query parameter", { status: 400 });
  }
  if (!isAllowedTarget(target)) {
    return new Response("Host not allowed", { status: 403 });
  }

  let fetchUrl = target;
  try {
    const u = new URL(target);
    if (u.protocol === "http:") {
      u.protocol = "https:";
      fetchUrl = u.toString();
    }
  } catch {
    /* keep target */
  }

  let upstream;
  try {
    upstream = await fetch(fetchUrl, {
      method: "GET",
      headers: {
        "User-Agent": USER_AGENT,
        Accept: "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
        Referer: "https://bgm.tv/",
      },
      redirect: "follow",
      cf: {
        cacheTtl: 86400,
        cacheEverything: true,
      },
    });
  } catch (e) {
    return new Response(`Upstream error: ${e}`, { status: 502 });
  }

  const headers = new Headers();
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set(
    "Content-Type",
    upstream.headers.get("Content-Type") || "application/octet-stream",
  );
  headers.set(
    "Cache-Control",
    upstream.ok ? "public, max-age=86400" : "public, max-age=60",
  );

  return new Response(upstream.body, {
    status: upstream.status,
    headers,
  });
}
