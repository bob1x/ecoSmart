import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/dashboard_stats.dart';

/// Animated top-row metric cards (Échantillons, Catégories, Clusters, Précision)
class AnimatedMetricRow extends StatelessWidget {
  const AnimatedMetricRow({super.key, required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData('Échantillons', stats.totalSamples.toDouble(), '', AppColors.ecoGreen, Icons.analytics_outlined),
      _MetricData('Catégories', stats.categoryCount.toDouble(), '', AppColors.aiPurple, Icons.category_outlined),
      _MetricData('Clusters', stats.clusterCount.toDouble(), '', AppColors.mlopsGold, Icons.hub_outlined),
      _MetricData('Précision', stats.modelAccuracy * 100, '%', AppColors.ecoGreen, Icons.speed_outlined),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: metrics.map((m) => _GlassMetricCard(data: m)).toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.suffix, this.color, this.icon);
  final String label;
  final double value;
  final String suffix;
  final Color color;
  final IconData icon;
}

class _GlassMetricCard extends StatelessWidget {
  const _GlassMetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: data.value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        final display = data.suffix == '%'
            ? '${animValue.toStringAsFixed(1)}${data.suffix}'
            : '${animValue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}${data.suffix}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.color.withAlpha(18),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: data.color.withAlpha(30)),
            boxShadow: [
              BoxShadow(
                color: data.color.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: data.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(data.icon, size: 14, color: data.color),
                  ),
                  const Spacer(),
                  _MiniSparkline(color: data.color),
                ],
              ),
              const Spacer(),
              Text(
                display,
                style: TextStyle(
                  fontFamily: AppFonts.spaceGrotesk,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                data.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  color: AppColors.inkTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tiny sparkline decoration for metric cards
class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(color.value);
    final points = List.generate(6, (_) => rng.nextDouble());
    return CustomPaint(
      size: const Size(40, 16),
      painter: _SparkPainter(points: points, color: color),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - points[i] * size.height * 0.8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}
