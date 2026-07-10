import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Native HTML &lt;img&gt; via [HtmlElementView] — no CORS fetch decode.
/// Do NOT set crossOrigin (no-cors display path).
Widget buildHtmlPosterImage({
  required String url,
  required BoxFit fit,
  double? width,
  double? height,
  required Widget Function() fallbackBuilder,
}) {
  return _HtmlPosterImage(
    url: url,
    fit: fit,
    width: width,
    height: height,
    fallbackBuilder: fallbackBuilder,
  );
}

int _nextViewId = 0;
final Map<String, void Function()> _errorHandlers = {};
final Map<String, void Function()> _loadHandlers = {};

class _HtmlPosterImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function() fallbackBuilder;

  const _HtmlPosterImage({
    required this.url,
    required this.fit,
    this.width,
    this.height,
    required this.fallbackBuilder,
  });

  @override
  State<_HtmlPosterImage> createState() => _HtmlPosterImageState();
}

class _HtmlPosterImageState extends State<_HtmlPosterImage> {
  bool _failed = false;
  bool _loaded = false;
  late String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'acg-poster-${_nextViewId++}';
    _registerAndLoad();
  }

  @override
  void didUpdateWidget(covariant _HtmlPosterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _failed = false;
      _loaded = false;
      _viewType = 'acg-poster-${_nextViewId++}';
      _registerAndLoad();
    }
  }

  @override
  void dispose() {
    _errorHandlers.remove(_viewType);
    _loadHandlers.remove(_viewType);
    super.dispose();
  }

  void _registerAndLoad() {
    _errorHandlers[_viewType] = () {
      if (mounted) setState(() => _failed = true);
    };
    _loadHandlers[_viewType] = () {
      if (mounted) setState(() => _loaded = true);
    };

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = web.HTMLImageElement()
        ..alt = ''
        ..draggable = false;
      img.style
        ..setProperty('width', '100%')
        ..setProperty('height', '100%')
        ..setProperty('object-fit', _cssObjectFit(widget.fit))
        ..setProperty('display', 'block')
        ..setProperty('border', 'none')
        ..setProperty('pointer-events', 'none');

      img.onError.listen((_) {
        _errorHandlers[_viewType]?.call();
      });
      img.onLoad.listen((_) {
        _loadHandlers[_viewType]?.call();
      });

      img.src = widget.url;

      if (img.complete && img.naturalWidth > 0) {
        _loadHandlers[_viewType]?.call();
      }

      return img;
    });
  }

  static String _cssObjectFit(BoxFit fit) {
    return switch (fit) {
      BoxFit.contain => 'contain',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'fill',
      BoxFit.fitHeight => 'fill',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scale-down',
      BoxFit.cover => 'cover',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.fallbackBuilder();
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!_loaded)
            const ColoredBox(color: Color(0xFF0f3460)),
          HtmlElementView(
            key: ValueKey(_viewType),
            viewType: _viewType,
          ),
        ],
      ),
    );
  }
}
