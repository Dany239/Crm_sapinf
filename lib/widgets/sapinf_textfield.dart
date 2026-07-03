import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/sapinf_colors.dart';
import '../theme/sapinf_spacing.dart';
import '../theme/sapinf_shadows.dart';

class SapinfTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const SapinfTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: SapinfColors.card,
        borderRadius: SapinfSpacing.roundedMd,
        border: Border.all(
          color: const Color(0xFFD3DDF2),
        ),
        boxShadow: SapinfShadows.soft,
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  SapinfColors.primaryLight,
                  SapinfColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                color: SapinfColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: SapinfColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
