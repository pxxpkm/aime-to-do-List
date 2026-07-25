import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/utils/poster_url.dart';

void main() {
  group('normalizePosterUrl', () {
    test('upgrades protocol-relative //lain.bgm.tv to https', () {
      expect(
        normalizePosterUrl('//lain.bgm.tv/pic/cover/l/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
    });

    test('repairs localhost-resolved //lain path', () {
      expect(
        normalizePosterUrl(
          'http://127.0.0.1:8080//lain.bgm.tv/pic/cover/l/c3/b7/18770.jpg?r=1',
        ),
        'https://lain.bgm.tv/pic/cover/l/c3/b7/18770.jpg?r=1',
      );
    });

    test('upgrades lain.bgm.tv http to https', () {
      expect(
        normalizePosterUrl('http://lain.bgm.tv/pic/cover/l/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
    });

    test('upgrades any bgm.tv http host to https', () {
      expect(
        normalizePosterUrl('http://api.bgm.tv/v0/subjects/1/image'),
        'https://api.bgm.tv/v0/subjects/1/image',
      );
    });

    test('leaves https large unchanged', () {
      const url = 'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg';
      expect(normalizePosterUrl(url), url);
    });

    test('upgrades common cover path to large', () {
      expect(
        normalizePosterUrl('https://lain.bgm.tv/pic/cover/c/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
    });

    test('upgrades medium/small/grid cover paths to large', () {
      expect(
        normalizePosterUrl('https://lain.bgm.tv/pic/cover/m/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
      expect(
        normalizePosterUrl('https://lain.bgm.tv/pic/cover/s/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
      expect(
        normalizePosterUrl('https://lain.bgm.tv/pic/cover/g/ab/cd.jpg'),
        'https://lain.bgm.tv/pic/cover/l/ab/cd.jpg',
      );
    });

    test('leaves https /r/ large thumbnail paths unchanged', () {
      const url = 'https://lain.bgm.tv/r/400/pic/cover/l/ab/cd.jpg';
      expect(normalizePosterUrl(url), url);
    });

    test('upgrades /r/ common thumbnail path size letter to large', () {
      expect(
        normalizePosterUrl('https://lain.bgm.tv/r/400/pic/cover/c/ab/cd.jpg'),
        'https://lain.bgm.tv/r/400/pic/cover/l/ab/cd.jpg',
      );
    });

    test('leaves data URLs unchanged', () {
      const data = 'data:image/jpeg;base64,abc';
      expect(normalizePosterUrl(data), data);
    });

    test('returns null for null or empty', () {
      expect(normalizePosterUrl(null), isNull);
      expect(normalizePosterUrl(''), isNull);
    });

    test('leaves non-bangumi http unchanged', () {
      const url = 'http://example.com/a.jpg';
      expect(normalizePosterUrl(url), url);
    });
  });

  group('upgradeBangumiPosterQuality', () {
    test('returns null/empty as-is', () {
      expect(upgradeBangumiPosterQuality(null), isNull);
      expect(upgradeBangumiPosterQuality(''), '');
    });

    test('ignores non-bangumi', () {
      const url = 'https://example.com/pic/cover/c/x.jpg';
      expect(upgradeBangumiPosterQuality(url), url);
    });
  });

  group('isDataUrl / isNetworkUrl', () {
    test('detects data and network URLs', () {
      expect(isDataUrl('data:image/png;base64,x'), isTrue);
      expect(isDataUrl('https://example.com/a.jpg'), isFalse);
      expect(isNetworkUrl('https://example.com/a.jpg'), isTrue);
      expect(isNetworkUrl('http://example.com/a.jpg'), isTrue);
      expect(isNetworkUrl('//lain.bgm.tv/pic/x.jpg'), isTrue);
      expect(isNetworkUrl('data:image/png;base64,x'), isFalse);
      expect(isNetworkUrl(null), isFalse);
    });
  });

  group('toProxyUrl', () {
    test('wraps lain.bgm.tv through proxy base', () {
      const src = 'https://lain.bgm.tv/pic/cover/c/ab/cd.jpg';
      final out = toProxyUrl(src, proxyBase: kLocalPosterProxyBase);
      expect(out.startsWith(kLocalPosterProxyBase), isTrue);
      expect(out, contains(Uri.encodeComponent(src)));
    });

    test('wraps other bgm.tv hosts', () {
      const src = 'https://api.bgm.tv/v0/subjects/1/image';
      expect(
        toProxyUrl(src, proxyBase: kLocalPosterProxyBase),
        '$kLocalPosterProxyBase${Uri.encodeComponent(src)}',
      );
    });

    test('same-origin style base for cloud deploy', () {
      const src = 'https://lain.bgm.tv/pic/cover/l/x.jpg';
      const base = 'https://todo.example.com/proxy?url=';
      expect(
        toProxyUrl(src, proxyBase: base),
        '$base${Uri.encodeComponent(src)}',
      );
    });

    test('leaves data URLs unchanged', () {
      const data = 'data:image/jpeg;base64,abc';
      expect(toProxyUrl(data), data);
    });

    test('leaves non-bangumi URLs unchanged', () {
      const url = 'https://example.com/a.jpg';
      expect(toProxyUrl(url), url);
    });

    test('does not double-wrap proxy URLs', () {
      const src = 'https://lain.bgm.tv/pic/cover/c/ab/cd.jpg';
      final once = toProxyUrl(src, proxyBase: kLocalPosterProxyBase);
      expect(toProxyUrl(once), once);
    });
  });
}
