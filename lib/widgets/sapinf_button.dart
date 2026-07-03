import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/sapinf_colors.dart';
import '../theme/sapinf_spacing.dart';
import '../theme/sapinf_shadows.dart';

class SapinfButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const SapinfButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: SapinfSpacing.roundedMd,
        boxShadow: SapinfShadows.blueGlow,
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: SapinfColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: SapinfSpacing.roundedMd,
          ),
        ),
        child: loading
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 24),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
