import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../view_models/mlops_view_model.dart';

class DataDriftPage extends StatelessWidget {
  const DataDriftPage({super.key});

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
            Text('MONITORING',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.inkTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Data drift',
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary)),
            const SizedBox(height: 20),

            // ── Status pill ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3D22), Color(0xFF112E1E)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.ecoGreen.withAlpha(40), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(color: AppColors.ecoGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vm.driftStatus, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14,
                            fontWeight: FontWeight.w600, color: AppColors.ecoGreen)),
                        Text('${vm.driftLastScan}  ·  ${vm.driftEngine}',
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Feature Drift Card ─────────────────────────────
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
                        child: Text('FEATURE DRIFT\n(JENSEN-SHANNON)',
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                                color: AppColors.inkTertiary, letterSpacing: 0.5, height: 1.3)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mlopsBlue.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.mlopsBlue.withAlpha(80), width: 1),
                        ),
                        child: Text(vm.driftBadge, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                            fontWeight: FontWeight.w600, color: AppColors.mlopsBlue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...vm.driftFeatures.map((f) => _DriftBar(feature: f, threshold: vm.driftThreshold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 12, height: 2, color: AppColors.errorRed),
                      const SizedBox(width: 6),
                      Text('threshold ${vm.driftThreshold.toStringAsFixed(2)}',
                          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.errorRed)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── API Metrics ────────────────────────────────────
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
                  Text('API METRICS · LAST 24H',
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.inkTertiary, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _ApiStat(label: 'Requests', value: '1.284', unit: '', valueColor: AppColors.inkPrimary)),
                      Expanded(child: _ApiStat(label: 'Avg latency', value: '142', unit: 'ms', valueColor: AppColors.inkPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _ApiStat(label: 'Error rate', value: '0.3', unit: '%', valueColor: AppColors.ecoGreen)),
                      Expanded(child: _ApiStat(label: 'p95 latency', value: '389', unit: 'ms', valueColor: AppColors.mlopsGold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Latency trend (ms)',
                      style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: _LatencySparkline(data: vm.latencyTrend),
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

// ── Drift Bar ───────────────────────────────────────────────────
class _DriftBar extends StatelessWidget {
  const _DriftBar({required this.feature, required this.threshold});
  final dynamic feature;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final fraction = (feature.jsDivergence as double) / 0.06; // normalize to max ~0.06
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(feature.name as String, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11,
                color: AppColors.inkSecondary)),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(feature.color as int),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('.${((feature.jsDivergence as double) * 1000).toInt().toString().padLeft(3, '0')}',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 11, color: AppColors.inkTertiary)),
          ),
        ],
      ),
    );
  }
}

// ── API Stat ────────────────────────────────────────────────────
class _ApiStat extends StatelessWidget {
  const _ApiStat({required this.label, required this.value, required this.unit, required this.valueColor});
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 28,
                fontWeight: FontWeight.w700, color: valueColor)),
            if (unit.isNotEmpty)
              TextSpan(text: unit, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 14,
                  fontWeight: FontWeight.w500, color: AppColors.inkTertiary)),
          ]),
        ),
      ],
    );
  }
}

// ── Latency Sparkline ───────────────────────────────────────────
class _LatencySparkline extends StatelessWidget {
  const _LatencySparkline({required this.data});
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: _SparklinePainter(data),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;
    final dx = size.width / (data.length - 1);

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = dx * i;
      final y = size.height - ((data[i] - minV) / range * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF22C55E).withAlpha(40), const Color(0xFF22C55E).withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
