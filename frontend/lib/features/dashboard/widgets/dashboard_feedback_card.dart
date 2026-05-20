import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/eco_card.dart';

/// Card showing live user feedback statistics
class FeedbackStatsCard extends StatelessWidget {
  const FeedbackStatsCard({
    super.key,
    required this.totalFeedback,
    required this.corrections,
    required this.accuracyRate,
  });

  final int totalFeedback;
  final int corrections;
  final double accuracyRate;

  @override
  Widget build(BuildContext context) {
    final accuracyPct = (accuracyRate * 100).toStringAsFixed(1);
    final confirmed = totalFeedback - corrections;
    final accuracyColor = accuracyRate >= 0.8
        ? AppColors.ecoGreen
        : accuracyRate >= 0.5
            ? AppColors.mlopsGold
            : AppColors.errorRed;

    return EcoCard(
      glowColor: accuracyColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: accuracyColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.people_outline, size: 14, color: accuracyColor),
              ),
              const SizedBox(width: 10),
              Text(
                '$totalFeedback retours collectés',
                style: TextStyle(
                  fontFamily: AppFonts.inter, fontSize: 13,
                  fontWeight: FontWeight.w500, color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _FeedbackMetric(label: 'Précision réelle', value: '$accuracyPct%', color: accuracyColor)),
              const SizedBox(width: 12),
              Expanded(child: _FeedbackMetric(label: 'Confirmés', value: '$confirmed', color: AppColors.ecoGreen)),
              const SizedBox(width: 12),
              Expanded(child: _FeedbackMetric(
                label: 'Corrections', value: '$corrections',
                color: corrections > 0 ? AppColors.mlopsGold : AppColors.inkTertiary,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, __) => Opacity(
            opacity: v,
            child: Text(value,
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 20,
                    fontWeight: FontWeight.w700, color: color)),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
      ],
    );
  }
}
