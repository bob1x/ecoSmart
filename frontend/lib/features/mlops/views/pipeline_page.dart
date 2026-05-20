import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../view_models/mlops_view_model.dart';

class PipelinePage extends StatelessWidget {
  const PipelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MlopsViewModel>();
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CI/CD · MODEL HEALTH',
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.inkTertiary, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('Pipeline',
                          style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 28, fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary)),
                    ],
                  ),
                ),
                // Manual refresh button
                IconButton(
                  onPressed: vm.loading ? null : () => vm.fetchMetrics(),
                  icon: vm.loading
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ecoGreen))
                      : Icon(Icons.refresh, color: AppColors.ecoGreen),
                  tooltip: 'Refresh metrics',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── GitHub Actions ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('GITHUB ACTIONS ·\nLATEST PUSH',
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.inkTertiary, letterSpacing: 0.5, height: 1.3)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.ecoGreen.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.ecoGreen.withAlpha(80), width: 1),
                        ),
                        child: Text(vm.allGreen ? 'All\ngreen' : 'Failed',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, fontWeight: FontWeight.w600,
                                color: AppColors.ecoGreen, height: 1.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...vm.ciSteps.map((step) => _CiStepRow(step: step)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Confusion Matrix ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('CONFUSION\nMATRIX',
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                              color: AppColors.inkTertiary, letterSpacing: 0.5, height: 1.3)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('test set', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.inkTertiary)),
                          Text('n=${vm.matrixTestN}', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 11,
                              fontWeight: FontWeight.w600, color: AppColors.inkSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ConfusionMatrixGrid(labels: vm.matrixLabels, matrix: vm.confusionMatrix),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Model Registry ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MODEL REGISTRY',
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.inkTertiary, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.memory, size: 20, color: AppColors.inkSecondary),
                      const SizedBox(width: 8),
                      Text(vm.registryModelName, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 14,
                          fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                      const SizedBox(width: 8),
                      Text(vm.registryVersion, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                          color: AppColors.inkTertiary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.production.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.production.withAlpha(80), width: 1),
                        ),
                        child: Text(vm.registryStage, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                            fontWeight: FontWeight.w600, color: AppColors.production)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── CI Step Row ─────────────────────────────────────────────────
class _CiStepRow extends StatelessWidget {
  const _CiStepRow({required this.step});
  final dynamic step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            (step.passed as bool) ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: (step.passed as bool) ? AppColors.ecoGreen : AppColors.errorRed,
          ),
          const SizedBox(width: 10),
          Text(step.name as String, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
          const Spacer(),
          Text(step.detail as String, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11,
              color: AppColors.inkTertiary)),
        ],
      ),
    );
  }
}

// ── Confusion Matrix Grid ───────────────────────────────────────
class _ConfusionMatrixGrid extends StatelessWidget {
  const _ConfusionMatrixGrid({required this.labels, required this.matrix});
  final List<String> labels;
  final List<List<dynamic>> matrix;

  static const _catColors = [AppColors.catPlastic, AppColors.catMetal, AppColors.catGlass, AppColors.catCardboard];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: 36),
            ...labels.asMap().entries.map((e) => Expanded(
              child: Center(
                child: Text(e.value, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9,
                    fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
              ),
            )),
          ],
        ),
        const SizedBox(height: 6),
        // Matrix rows
        ...matrix.asMap().entries.map((rowEntry) {
          final rowIdx = rowEntry.key;
          final row = rowEntry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(labels[rowIdx], style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9,
                      fontWeight: FontWeight.w600, color: AppColors.inkTertiary)),
                ),
                ...row.asMap().entries.map((cellEntry) {
                  final colIdx = cellEntry.key;
                  final cell = cellEntry.value;
                  final isHighlight = cell.isHighlight as bool;
                  final val = cell.value as int;
                  final color = isHighlight ? _catColors[colIdx] : AppColors.surfaceLight;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isHighlight ? color.withAlpha(40) : color,
                        borderRadius: BorderRadius.circular(6),
                        border: isHighlight ? Border.all(color: color.withAlpha(100), width: 1) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(val.toString(), style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                          fontWeight: FontWeight.w700, color: isHighlight ? color : AppColors.inkTertiary)),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}
