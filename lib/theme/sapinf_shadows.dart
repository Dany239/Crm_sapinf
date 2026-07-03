import 'package:flutter/material.dart';

class SapinfShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> blueGlow = [
    BoxShadow(
      color: const Color(0xFF1565C0).withValues(alpha: 0.22),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ];
}
