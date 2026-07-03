import 'package:flutter/material.dart';

class SapinfLogo extends StatelessWidget {
  final double size;

  const SapinfLogo({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_sapinf.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
