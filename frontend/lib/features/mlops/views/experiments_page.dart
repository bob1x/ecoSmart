import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/eco_card.dart';
import '../models/mlops_models.dart';
import '../view_models/mlops_view_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ExperimentsPage extends StatelessWidget {
  const ExperimentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MlopsViewModel>();
    final api = context.read<ApiService>();

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Text('MLFLOW REGISTRY',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.inkTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Experiments',
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary)),
            const SizedBox(height: 20),

            // ── Metric cards ───────────────────────────────────
            Row(
              children: [
                Expanded(child: _MetricCard(
                  value: vm.bestF1.toStringAsFixed(3),
                  label: vm.bestRunLabel,
                  title: 'BEST F1',
                  valueColor: AppColors.ecoGreen,
                )),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(
                  value: vm.totalRuns.toString(),
                  label: vm.totalRunsLabel,
                  title: 'TOTAL RUNS',
                  valueColor: AppColors.inkPrimary,
                )),
              ],
            ),
            const SizedBox(height: 20),

            // ── F1 Score Chart ──────────────────────────────────
            _F1Chart(f1History: vm.f1History, delta: vm.f1Delta),
            const SizedBox(height: 20),

            // ── Run Log ────────────────────────────────────────
            Text('RUN LOG',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.inkTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...vm.runs.map((run) => _RunLogItem(run: run)),
            const SizedBox(height: 20),

            // ── Export buttons ──────────────────────────────────
            Text('EXPORTS',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.inkTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ExportButton(
                    icon: Icons.table_chart_outlined,
                    label: 'Exporter CSV',
                    subtitle: 'Données feedback',
                    color: AppColors.ecoGreen,
                    onTap: () {
                      final url = api.getExportUrl('/export/feedback');
                      html.window.open(url, '_blank');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExportButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Rapport PDF',
                    subtitle: 'Performance modèles',
                    color: AppColors.errorRed,
                    onTap: () {
                      final url = api.getExportUrl('/export/report');
                      html.window.open(url, '_blank');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Export Button ────────────────────────────────────────────────
class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 9,
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label, required this.title, required this.valueColor});
  final String value;
  final String label;
  final String title;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.inkTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 32, fontWeight: FontWeight.w700,
              color: valueColor)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
        ],
      ),
    );
  }
}

// ── F1 Score Line Chart ─────────────────────────────────────────
class _F1Chart extends StatelessWidget {
  const _F1Chart({required this.f1History, required this.delta});
  final List<double> f1History;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final spots = f1History.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
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
              Text('F1 SCORE ACROSS RUNS', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11,
                  fontWeight: FontWeight.w600, color: AppColors.inkTertiary, letterSpacing: 0.5)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ecoGreen.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward, size: 12, color: AppColors.ecoGreen),
                    Text('+${delta}%', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 11,
                        fontWeight: FontWeight.w600, color: AppColors.ecoGreen)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: 0.85,
                maxY: 0.96,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.03,
                  getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 0.03,
                      getTitlesWidget: (v, _) => Text(v.toStringAsFixed(2),
                          style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 9, color: AppColors.inkTertiary)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('R${v.toInt() + 1}',
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.inkTertiary)),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.ecoGreen,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: spot.x == spots.last.x ? 5 : 3,
                        color: AppColors.ecoGreen,
                        strokeColor: AppColors.scaffold,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.ecoGreen.withAlpha(60), AppColors.ecoGreen.withAlpha(5)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Run Log Item ────────────────────────────────────────────────
class _RunLogItem extends StatelessWidget {
  const _RunLogItem({required this.run});
  final ExperimentRun run;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          // Circle avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(run.id, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                fontWeight: FontWeight.w700, color: AppColors.inkPrimary)),
          ),
          const SizedBox(width: 12),
          // Name & algorithm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(run.name, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                Text(run.algorithm, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11,
                    color: AppColors.inkTertiary)),
              ],
            ),
          ),
          // F1 score
          Text(run.f1Score.toStringAsFixed(3), style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16,
              fontWeight: FontWeight.w700, color: AppColors.inkPrimary)),
          const SizedBox(width: 10),
          // Badge
          _StatusBadge(status: run.status),
        ],
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RunStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      RunStatus.champion => ('Champion', AppColors.champion),
      RunStatus.staging  => ('Staging', AppColors.staging),
      RunStatus.archived => ('Archived', AppColors.archived),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
          fontWeight: FontWeight.w600, color: color)),
    );
  }
}
