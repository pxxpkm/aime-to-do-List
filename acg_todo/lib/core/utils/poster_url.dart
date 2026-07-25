/// Poster URL helpers — normalize for Web display (HTTPS) and type checks.
String? normalizePosterUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('data:')) return url;

  var s = url.trim();

  // Protocol-relative: //lain.bgm.tv/... → https://lain.bgm.tv/...
  if (s.startsWith('//')) {
    s = 'https:$s';
  }

  // Broken resolve: http://127.0.0.1:8080//lain.bgm.tv/... → //lain...
  final hostPathMatch = RegExp(
    r'^https?://[^/]+(//(?:lain\.)?bgm\.tv/.*)$',
    caseSensitive: false,
  ).firstMatch(s);
  if (hostPathMatch != null) {
    s = 'https:${hostPathMatch.group(1)}';
  }

  // Also handle path-only embed: http://host//lain.bgm.tv without capture edge cases
  final embedded = RegExp(
    r'(//(?:lain\.)?bgm\.tv/\S+)',
    caseSensitive: false,
  ).firstMatch(s);
  if (s.contains('127.0.0.1') || s.contains('localhost')) {
    if (embedded != null) {
      s = 'https:${embedded.group(1)}';
    }
  }

  final uri = Uri.tryParse(s);
  if (uri == null) return upgradeBangumiPosterQuality(s);

  final host = uri.host.toLowerCase();
  final isBangumiHost =
      host == 'lain.bgm.tv' || host.endsWith('.bgm.tv') || host == 'bgm.tv';
  if (uri.scheme == 'http' && isBangumiHost) {
    s = uri.replace(scheme: 'https').toString();
  } else if (s.startsWith('http://lain.bgm.tv') ||
      s.startsWith('http://bgm.tv')) {
    s = 'https${s.substring(4)}';
  }

  return upgradeBangumiPosterQuality(s);
}

/// Prefer Bangumi full-size covers (`/pic/cover/l/`) over common/medium/small/grid.
///
/// API images map (legacy + v0): large > common > medium > small > grid.
/// Home wall stores one URL; common (~13KB) looks blurry when upscaled.
String? upgradeBangumiPosterQuality(String? url) {
  if (url == null || url.isEmpty || url.startsWith('data:')) return url;
  if (!url.contains('bgm.tv')) return url;

  // .../pic/cover/{c|m|s|g}/... → .../pic/cover/l/...
  final upgraded = url.replaceFirstMapped(
    RegExp(r'/pic/cover/[cmsg]/', caseSensitive: false),
    (_) => '/pic/cover/l/',
  );
  return upgraded;
}

bool isDataUrl(String? url) => url?.startsWith('data:') == true;

bool isNetworkUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.startsWith('//') ||
      url.startsWith('http://') ||
      url.startsWith('https://');
}

/// Legacy fixed base (tests / offline docs). Prefer [posterProxyBase].
const String kLocalPosterProxyBase = 'http://127.0.0.1:8080/proxy?url=';

/// Same-origin poster proxy: local `proxy_server.py` **or** Cloudflare
/// Pages Function `/proxy` on the deployed host.
///
/// Uses [Uri.base.origin] when it is http(s); otherwise falls back to
/// [kLocalPosterProxyBase].
String posterProxyBase() {
  try {
    final origin = Uri.base.origin;
    if (origin.startsWith('http://') || origin.startsWith('https://')) {
      // Strip trailing slash if any
      final o = origin.endsWith('/')
          ? origin.substring(0, origin.length - 1)
          : origin;
      return '$o/proxy?url=';
    }
  } catch (_) {
    // Uri.base unavailable
  }
  return kLocalPosterProxyBase;
}

/// Rewrite Bangumi CDN URLs through the CORS image proxy (Web call sites).
///
/// [proxyBase] overrides [posterProxyBase] (useful in unit tests).
String toProxyUrl(String url, {String? proxyBase}) {
  if (url.startsWith('data:')) return url;
  if (url.contains('/proxy?url=')) return url;
  if (url.contains('lain.bgm.tv') || url.contains('bgm.tv')) {
    final base = proxyBase ?? posterProxyBase();
    return '$base${Uri.encodeComponent(url)}';
  }
  return url;
}
