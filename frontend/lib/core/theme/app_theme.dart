import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

// ─────────────────────────────────────────────────────────────────
// Custom Slider Thumb: white circle + ecoGreen ring + center dot
// ─────────────────────────────────────────────────────────────────
class EcoThumbShape extends SliderComponentShape {
  const EcoThumbShape();

  static const double _thumbRadius = 7;
  static const double _ringWidth = 2;
  static const double _dotRadius = 2;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(_thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // White fill
    canvas.drawCircle(
      center,
      _thumbRadius,
      Paint()..color = AppColors.white,
    );

    // Green ring
    canvas.drawCircle(
      center,
      _thumbRadius,
      Paint()
        ..color = AppColors.ecoGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth,
    );

    // Center dot
    canvas.drawCircle(
      center,
      _dotRadius,
      Paint()..color = AppColors.ecoGreen,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AppTheme — Dark-only
// ─────────────────────────────────────────────────────────────────
abstract class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.scaffold,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.ecoGreen,
          onPrimary: AppColors.white,
          secondary: AppColors.aiPurple,
          surface: AppColors.surface,
          onSurface: AppColors.inkPrimary,
        ),
        fontFamily: AppFonts.inter,

        // ── Cards ──────────────────────────────────────────────
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Sliders ────────────────────────────────────────────
        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.ecoGreen,
          inactiveTrackColor: AppColors.ecoGreenLight,
          thumbColor: AppColors.white,
          overlayColor: Color(0x1F22C55E),
          thumbShape: EcoThumbShape(),
          trackHeight: 3,
          overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
          showValueIndicator: ShowValueIndicator.never,
        ),

        // ── Inputs ─────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.ecoGreen, width: 1.5),
          ),
          hintStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: AppColors.inkTertiary,
          ),
        ),

        // ── ElevatedButton ─────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ecoGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: const StadiumBorder(),
            textStyle: TextStyle(
              fontFamily: AppFonts.spaceGrotesk,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),

        // ── Bottom Nav ─────────────────────────────────────────
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          elevation: 0,
          selectedItemColor: AppColors.ecoGreen,
          unselectedItemColor: AppColors.inkTertiary,
          selectedLabelStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 10,
          ),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),

        // ── AppBar ─────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        // ── SnackBar ───────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceLight,
          contentTextStyle: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 13,
            color: AppColors.inkPrimary,
          ),
          actionTextColor: AppColors.ecoGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
