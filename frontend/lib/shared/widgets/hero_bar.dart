import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Full-width hero header with gradient background.
class HeroBar extends StatelessWidget {
  const HeroBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundColor, AppColors.scaffold],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (trailing != null)
                Align(alignment: Alignment.topRight, child: trailing!),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.spaceGrotesk,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 12,
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
