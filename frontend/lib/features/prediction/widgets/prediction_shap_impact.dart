import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/eco_card.dart';

/// SHAP waterfall chart — shows feature contribution bars
class ShapWaterfall extends StatelessWidget {
  const ShapWaterfall({super.key, required this.contributions});
  final List<Map<String, dynamic>> contributions;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      glowColor: AppColors.mlopsBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 16, color: AppColors.mlopsBlue),
              const SizedBox(width: 8),
              Text('Contribution des features',
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          ...contributions.take(6).map((c) {
            final feature = c['feature'] as String? ?? '';
            final contribution = (c['contribution'] as num?)?.toDouble() ?? 0;
            final barFraction = (contribution / 100).clamp(0.0, 1.0);
            final color = contribution > 20
                ? AppColors.ecoGreen
                : contribution > 10
                    ? AppColors.mlopsBlue
                    : AppColors.inkTertiary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(feature, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkSecondary)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: contribution),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Text(
                          '${v.toStringAsFixed(1)}%',
                          style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                              fontWeight: FontWeight.w700, color: color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: barFraction),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Stack(
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: v,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color.withAlpha(140), color]),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Environmental impact calculator card
class ImpactCard extends StatelessWidget {
  const ImpactCard({super.key, required this.categorie});
  final String categorie;

  static const _co2Saved = {
    'Plastique': 1.5, 'Papier': 0.9, 'Verre': 0.6, 'Métal': 2.3,
  };
  static const _waterSaved = {
    'Plastique': 12.0, 'Papier': 26.0, 'Verre': 3.0, 'Métal': 18.0,
  };
  static const _landfillDiverted = {
    'Plastique': 0.8, 'Papier': 0.5, 'Verre': 1.2, 'Métal': 1.5,
  };

  @override
  Widget build(BuildContext context) {
    final co2 = _co2Saved[categorie] ?? 1.0;
    final water = _waterSaved[categorie] ?? 10.0;
    final landfill = _landfillDiverted[categorie] ?? 0.5;

    return EcoCard(
      glowColor: AppColors.ecoGreen,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, size: 16, color: AppColors.ecoGreen),
              const SizedBox(width: 8),
              Text('Impact du recyclage — $categorie',
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12,
                      fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ImpactMetric(icon: Icons.cloud_outlined, value: co2, unit: 'kg', label: 'CO₂ économisé', color: AppColors.ecoGreen)),
              const SizedBox(width: 12),
              Expanded(child: _ImpactMetric(icon: Icons.water_drop_outlined, value: water, unit: 'L', label: 'Eau préservée', color: AppColors.mlopsBlue)),
              const SizedBox(width: 12),
              Expanded(child: _ImpactMetric(icon: Icons.delete_outline_rounded, value: landfill, unit: 'kg', label: 'Décharge évitée', color: AppColors.mlopsGold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImpactMetric extends StatelessWidget {
  const _ImpactMetric({required this.icon, required this.value, required this.unit, required this.label, required this.color});
  final IconData icon;
  final double value;
  final String unit;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text(
            '${v.toStringAsFixed(1)} $unit',
            style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.inkTertiary)),
      ],
    );
  }
}
