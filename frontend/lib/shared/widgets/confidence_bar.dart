import 'package:flutter/material.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_colors.dart';

class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    super.key,
    required this.confidence,
    required this.color,
    this.label = 'Confidence',
    this.trackColor,
  });

  final double confidence;
  final Color color;
  final String label;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 11,
                color: AppColors.inkTertiary,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: confidence),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  '${(value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: AppFonts.spaceGrotesk,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: confidence),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  // Track
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: trackColor ?? color.withAlpha(38),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
