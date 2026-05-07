import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Section header label (all-caps, muted green text).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppFonts.inter,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.inkTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}
