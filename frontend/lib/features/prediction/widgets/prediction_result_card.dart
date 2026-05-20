import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/category_badge.dart';
import '../../../shared/widgets/confidence_bar.dart';
import '../../../shared/widgets/eco_score_gauge.dart';
import '../../../shared/widgets/feedback_row.dart';
import '../../../data/models/prediction_result.dart';
import '../view_models/prediction_view_model.dart';

/// Card showing the prediction result (category, price, confidence, eco score)
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result, required this.isLoading, this.error});
  final PredictionResult? result;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<PredictionViewModel>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: isLoading
          ? const ShimmerResult()
          : result != null
              ? Column(
                  children: [
                    _ResultContent(result: result!),
                    const SizedBox(height: 14),
                    Center(child: EcoScoreGauge(score: result!.ecoScore, size: 110)),
                    const SizedBox(height: 14),
                    FeedbackRow(
                      predictedLabel: result!.categorie,
                      onFeedback: vm.submitFeedback,
                    ),
                  ],
                )
              : _EmptyResult(error: error),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Résultat', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
        const SizedBox(height: 4),
        Text(
          error ?? 'Ajustez les curseurs puis lancez la prédiction',
          style: TextStyle(
            fontFamily: AppFonts.spaceGrotesk, fontSize: 15, fontWeight: FontWeight.w600,
            color: error != null ? AppColors.errorRed : AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result});
  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final prixTnd = result.prixRevente * 3.37;
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: 'TND', decimalDigits: 2);
    final catColor = AppColors.forCategory(result.categorie);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catégorie prédite', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 4),
                  Text(result.categorie, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.inkPrimary)),
                ],
              ),
            ),
            CategoryBadge(category: result.categorie),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.white10, height: 1),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix estimé', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 2),
                  Text('${fmt.format(prixTnd)}/kg', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                ],
              ),
            ),
            if (result.clusterId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Cluster', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 2),
                  Text('#${result.clusterId}', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        ConfidenceBar(confidence: result.confidence, color: catColor, label: 'Certitude', trackColor: AppColors.white10),
      ],
    );
  }
}

/// Shimmer loading state for the result card
class ShimmerResult extends StatefulWidget {
  const ShimmerResult({super.key});
  @override
  State<ShimmerResult> createState() => _ShimmerResultState();
}

class _ShimmerResultState extends State<ShimmerResult> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double width = double.infinity, double height = 14}) => AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: Container(
            width: width, height: height,
            decoration: BoxDecoration(color: AppColors.white10, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 90, height: 10),
          const SizedBox(height: 8),
          _box(width: 160, height: 24),
          const SizedBox(height: 16),
          _box(height: 14),
          const SizedBox(height: 10),
          _box(height: 6),
        ],
      );
}
