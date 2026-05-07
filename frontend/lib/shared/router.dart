import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/prediction/views/prediction_screen.dart';
import '../features/nlp_assistant/views/nlp_screen.dart';
import '../features/mlops/views/mlops_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          _AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/predict',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const PredictionScreen(),
              transitionsBuilder: (context, animation, _, child) =>
                  SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/nlp',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const NlpAssistantScreen(),
              transitionsBuilder: (context, animation, _, child) =>
                  SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
        ]),
        // ── 4th tab: MLOps ──────────────────────────────────
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/mlops',
            pageBuilder: (context, state) => CustomTransitionPage(
              child: const MlopsScreen(),
              transitionsBuilder: (context, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
        ]),
      ],
    ),
  ],
);

// ── Navigation Shell ───────────────────────────────────────────
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // Data tab
                _NavTab(
                  icon: 'assets/icons/dashboard_icon.svg',
                  label: 'Data',
                  isActive: currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),
                // Predict tab
                _NavTab(
                  icon: 'assets/icons/predict_icon.svg',
                  label: 'Predict',
                  isActive: currentIndex == 1,
                  onTap: () => _goBranch(1),
                ),
                // NLP tab
                _NavTab(
                  icon: 'assets/icons/nlp_icon.svg',
                  label: 'NLP',
                  isActive: currentIndex == 2,
                  onTap: () => _goBranch(2),
                ),
                // MLOps tab — elevated style
                _MlopsTab(
                  isActive: currentIndex == 3,
                  onTap: () => _goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Standard Nav Tab ────────────────────────────────────────────
class _NavTab extends StatelessWidget {
  const _NavTab({required this.icon, required this.label, required this.isActive, required this.onTap});
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.ecoGreen : AppColors.inkTertiary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(icon, width: 22, height: 22,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Elevated MLOps Tab ──────────────────────────────────────────
class _MlopsTab extends StatelessWidget {
  const _MlopsTab({required this.isActive, required this.onTap});
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive ? AppColors.mlopsBlue : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: AppColors.mlopsBlue.withAlpha(60),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Center(
                child: SvgPicture.asset('assets/icons/mlops_icon.svg',
                    width: 22, height: 22,
                    colorFilter: ColorFilter.mode(
                      isActive ? AppColors.white : AppColors.inkTertiary,
                      BlendMode.srcIn,
                    )),
              ),
            ),
            const SizedBox(height: 2),
            Text('MLOps', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.mlopsBlue : AppColors.inkTertiary)),
          ],
        ),
      ),
    );
  }
}
