import 'package:flutter/widgets.dart';

/// Non-web stub — never used when [kIsWeb] is false (caller uses CachedNetworkImage).
Widget buildHtmlPosterImage({
  required String url,
  required BoxFit fit,
  double? width,
  double? height,
  required Widget Function() fallbackBuilder,
}) {
  return fallbackBuilder();
}
