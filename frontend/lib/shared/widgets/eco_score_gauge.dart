import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Animated circular gauge that displays an EcoScore (0-100).
/// Red < 40, Amber 40-70, Green > 70.
class EcoScoreGauge extends StatefulWidget {
  const EcoScoreGauge({super.key, required this.score, this.size = 120});
  final int score;
  final double size;

  @override
  State<EcoScoreGauge> createState() => _EcoScoreGaugeState();
}

class _EcoScoreGaugeState extends State<EcoScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prevScore = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.score / 100.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(EcoScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _prevScore = old.score;
      _anim = Tween<double>(
              begin: _prevScore / 100.0, end: widget.score / 100.0)
          .animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static Color _colorForScore(double t) {
    if (t < 0.4) return Color.lerp(AppColors.errorRed, AppColors.mlopsGold, t / 0.4)!;
    if (t < 0.7) return Color.lerp(AppColors.mlopsGold, AppColors.ecoGreen, (t - 0.4) / 0.3)!;
    return AppColors.ecoGreen;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        final displayScore = (t * 100).round();
        final color = _colorForScore(t);
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Track ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: AppColors.white10,
                  strokeWidth: 8,
                ),
              ),
              // Progress ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: t,
                  color: color,
                  strokeWidth: 8,
                ),
              ),
              // Glow
              Container(
                width: widget.size * 0.72,
                height: widget.size * 0.72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha((40 * t).round()),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              // Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$displayScore',
                    style: TextStyle(
                      fontFamily: AppFonts.spaceGrotesk,
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    'EcoScore',
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: widget.size * 0.1,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
