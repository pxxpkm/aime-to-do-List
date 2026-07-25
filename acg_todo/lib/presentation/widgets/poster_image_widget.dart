import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/core/theme/app_palette.dart';
import 'package:acg_todo/core/utils/poster_url.dart';
import 'package:acg_todo/presentation/widgets/shimmer_placeholder.dart';

/// Pure display widget for posters.
///
/// Web: [Image.network] via local CORS proxy ([toProxyUrl]) — Flutter Web
/// always XHR-fetches image bytes (not native no-cors &lt;img&gt;).
/// Non-Web: CachedNetworkImage (direct URL, no browser CORS).
/// Legacy data URLs: Image.memory directly.
class PosterImageWidget extends ConsumerStatefulWidget {
  final String? posterUrl;
  final String type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PosterImageWidget({
    super.key,
    required this.posterUrl,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  ConsumerState<PosterImageWidget> createState() => _PosterImageWidgetState();
}

class _PosterImageWidgetState extends ConsumerState<PosterImageWidget> {
  int _retryCount = 0;
  static const _maxRetries = 2;

  @override
  Widget build(BuildContext context) {
    final url = normalizePosterUrl(widget.posterUrl);

    Widget child;
    if (url == null) {
      child = _buildFallback();
    } else if (url.startsWith('data:')) {
      child = _buildDataUrl(url);
    } else if (isNetworkUrl(url)) {
      child = kIsWeb ? _buildWebNetwork(url) : _buildIoNetwork(url);
    } else {
      child = _buildFallback();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildDataUrl(String url) {
    try {
      final bytes = base64Decode(url.split(',')[1]);
      return Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    } catch (_) {
      return _buildFallback();
    }
  }

  Widget _buildWebNetwork(String url) {
    final proxyUrl = toProxyUrl(url);
    return Image.network(
      proxyUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return ShimmerPlaceholder(
          width: widget.width ?? double.infinity,
          height: widget.height ?? double.infinity,
        );
      },
        errorBuilder: (_, _, _) {
        if (_retryCount < _maxRetries) {
          Future.delayed(Duration(milliseconds: 500 * (_retryCount + 1)), () {
            if (mounted) {
              setState(() => _retryCount++);
            }
          });
          return ShimmerPlaceholder(
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
          );
        }
        return _buildFallback();
      },
    );
  }

  Widget _buildIoNetwork(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => ShimmerPlaceholder(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
      ),
      errorWidget: (_, _, _) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    final color = context.palette.typeColor(widget.type);
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            context.palette.bg,
          ],
        ),
        borderRadius: widget.borderRadius,
      ),
      child: Center(
        child: Icon(
          _iconForType(widget.type),
          size: 24,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'anime' => Icons.movie_outlined,
      'manga' => Icons.menu_book_outlined,
      'light_novel' => Icons.auto_stories_outlined,
      'game' => Icons.sports_esports_outlined,
      _ => Icons.image_outlined,
    };
  }
}
