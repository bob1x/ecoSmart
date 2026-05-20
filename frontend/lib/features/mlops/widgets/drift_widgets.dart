import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Drift divergence bar (shows JS divergence for a feature)
class DriftBar extends StatelessWidget {
  const DriftBar({super.key, required this.feature, required this.threshold});
  final dynamic feature;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final fraction = (feature.jsDivergence as double) / 0.06;
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

/// API stat widget (requests, latency, etc.)
class ApiStat extends StatelessWidget {
  const ApiStat({super.key, required this.label, required this.value, required this.unit, required this.valueColor});
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

/// Latency sparkline chart
class LatencySparkline extends StatelessWidget {
  const LatencySparkline({super.key, required this.data});
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
