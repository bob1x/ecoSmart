import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Premium glassmorphic card with optional glow accent.
class EcoCard extends StatelessWidget {
  const EcoCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(200),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: glowColor?.withAlpha(30) ?? AppColors.border,
          width: 1,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withAlpha(15),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
