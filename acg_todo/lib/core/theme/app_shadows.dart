import 'package:flutter/material.dart';

class AppShadows {
  static const Color _ink = Color(0x1A2C2416);

  static List<BoxShadow> get card => const [
        BoxShadow(
          color: _ink,
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x122C2416),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get fab => const [
        BoxShadow(
          color: Color(0x332C2416),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];
}
