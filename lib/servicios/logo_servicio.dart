import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LogoServicio extends StatelessWidget {
  final String? logoBase64;
  final double size;
  final double borderRadius;

  const LogoServicio({
    super.key,
    required this.logoBase64,
    this.size = 52,
    this.borderRadius = 16,
  });

  Uint8List? _decodificar() {
    final contenido = logoBase64?.trim() ?? '';
    if (contenido.isEmpty) return null;

    try {
      return base64Decode(contenido);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodificar();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: bytes == null
          ? Icon(
              Icons.design_services_rounded,
              color: const Color(0xFF1565C0),
              size: size * 0.52,
            )
          : Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.design_services_rounded,
                color: const Color(0xFF1565C0),
                size: size * 0.52,
              ),
            ),
    );
  }
}
