import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Full-width hero header with animated gradient background and subtle glow.
class HeroBar extends StatefulWidget {
  const HeroBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.trailing,
    this.icon,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Widget? trailing;
  final IconData? icon;

  @override
  State<HeroBar> createState() => _HeroBarState();
}

class _HeroBarState extends State<HeroBar> with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.backgroundColor,
                Color.lerp(widget.backgroundColor, AppColors.scaffold, 0.5 + 0.15 * _shimmer.value)!,
                AppColors.scaffold,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.trailing != null)
                    Align(alignment: Alignment.topRight, child: widget.trailing!),
                  Row(
                    children: [
                      if (widget.icon != null) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor.withAlpha(120),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, size: 18, color: AppColors.inkPrimary),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontFamily: AppFonts.spaceGrotesk,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontFamily: AppFonts.inter,
                                fontSize: 12,
                                color: AppColors.inkTertiary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
