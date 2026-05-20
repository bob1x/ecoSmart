import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Prometheus stat card (Total Requests, Error Rate, Uptime)
class PromStat extends StatelessWidget {
  const PromStat({super.key, required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.ecoGreen),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.inkPrimary)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.inkTertiary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// Time-series chart rendered from Prometheus data points
class TimeSeriesChart extends StatelessWidget {
  const TimeSeriesChart({super.key, required this.series, required this.color});
  final List<Map<String, dynamic>> series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Center(
        child: Text('No data yet',
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
      );
    }

    final firstSeries = series[0];
    final points = (firstSeries['points'] as List<dynamic>? ?? [])
        .map((p) => (p as Map<String, dynamic>)['v'] as num? ?? 0)
        .map((n) => n.toDouble())
        .toList();

    if (points.isEmpty) {
      return Center(
        child: Text('Collecting...',
            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
      );
    }

    return CustomPaint(
      size: const Size(double.infinity, 80),
      painter: _TimeSeriesPainter(data: points, color: color),
    );
  }
}

class _TimeSeriesPainter extends CustomPainter {
  _TimeSeriesPainter({required this.data, required this.color});
  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(0.001, double.infinity);

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1).clamp(1, double.infinity)) * size.width;
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.85) - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Fill gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(50), color.withAlpha(5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // Line
    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Latest value label
    final lastVal = data.last;
    final tp = TextPainter(
      text: TextSpan(
        text: lastVal.toStringAsFixed(lastVal < 10 ? 2 : 0),
        style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 9, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 2, 0));
  }

  @override
  bool shouldRepaint(covariant _TimeSeriesPainter old) => old.data != data;
}

/// Endpoint traffic bar for per-endpoint breakdown
class EndpointBar extends StatelessWidget {
  const EndpointBar({super.key, required this.name, required this.count, required this.maxCount});
  final String name;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(name,
              style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 10, color: AppColors.inkSecondary),
              overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(color: AppColors.scaffold, borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.02, 1.0),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.ecoGreen.withAlpha(180), AppColors.ecoGreen.withAlpha(80)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('$count',
            style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 10,
                color: AppColors.inkPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
